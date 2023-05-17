+++
title = "Writing a GitHub Action with Scala.js"
date = 2023-05-13
slug = "gh-action-in-scala"
language="en"
draft = true
[extra]
description = "How to use [`scala-cli`](https://github.com/VirtusLab/scala-cli) and the [Typelevel Toolkit](https://github.com/typelevel/toolkit) to super charge your GitHub CI."
+++

Some months ago, I discussed with a DevOps colleague the need for a custom GitHub Action at `$work`. The action we needed had to perform many tasks that weren't present in any action we could find, so we planned to write our own.

The chances were limited: there was the evergreen option to embed a **gigantic shell script** in the ci file (dealing with evergreen problems like escaping, quoting and indentation), the also evergreen option to **commit the script**, or we could have written our **own GitHub action**.

The last option was the most interesting one. Writing business logic in a more structured language than bash was desirable, but we had to face the fact that, according to the documentation, only two [types of actions] exist (if you don't consider composite ones): `Docker Container Actions` and `Javascript Actions`.

Since no one had any intention whatsoever to write javascript code and [Docker Container Actions] had all the features we needed, we resorted to using one of them (despite their limitations in terms of compatibility).

Even though this <u>scarcely interesting success story</u> has a happy ending, a question emerged during the developments: `Is it possible to write a Github Action with Scala.js?`

> Also, I asked myself `Is it still possible to survive as a software developer in 2023 without ever having written a single line of javascript?`: you'll find the answer below.

**TLDR**: yes and [@armanbilge] did it in a couple of repositories like [this one](https://github.com/typelevel/await-cirrus), so in this post, we'll dissect his approach to create a how-to guide. Thank you, Arman! :heart:

## Creating a simple action

The action we'll create will be a **simple adder** that will `sum up two numbers` that can be either defined in the build file or one of the results of one of the previous steps.

### Metadata

According to its [metadata syntax] page, every action defined in a repository requires an `action.yml` file that describes your action's inputs, outputs and run configuration.

Our action will have two required inputs and a single output, and it will run using node 16:

{% codeBlock(title="action.yml", color="blue") %}
```yml
name: 'Scala.js adder'
description: 'Summing two numbers, but with Scala.js'
inputs:
  number-one:
    description: 'The first number'
    required: true
  number-two:
    description: 'The second number'
    required: true
outputs:
  result:
    description: "The sum of the two inputs"
runs:
  using: 'node16'
  main: 'index.js'
```
{% end %}

### Business logic requirements

Once the metadata file is defined, we'll have to write the business logic, but we need to address a few issues:
- How do we produce a runnable js file?
- How do we read the action's inputs?
- How do we write the action's outputs?

The most straightforward and potent tool that will produce <u>javascript code from a single Scala file</u> is undoubtedly [`scala-cli`](https://github.com/VirtusLab/scala-cli), with its ability to define in a few lines packaging, platform and dependencies setting.

Let's create in our repository a scala file with the required settings to produce a js module using a specific js and scala version:

{% codeBlock(title="index.scala", color="red") %}
```scala
//> using scala "3.2.2"
//> using platform "js"
//> using jsVersion "1.13.1"
//> using jsModuleKind "common"

object index extends App:
    println("Hello world")
```
{% end %}

Packaging this file is as simple as running the command `scala-cli --power package -f index.scala` (we'll reuse this command later in our CI). This command will produce an `index.js` file that can run locally using `node ./index.js`.

Now that we can produce a runnable js file, it's time to create an actual GitHub action. The [official documentation for javascript actions](https://docs.github.com/en/actions/creating-actions/creating-a-javascript-action) recommends using the [`GitHub Actions Toolkit Node.js module`](https://github.com/actions/toolkit) to speed up development (an intelligent person will probably use it,) but the Actions' runtime offers an alternative.

Digging deep into the metadata syntax documentation, in the [inputs] section, you'll find an interesting paragraph:

> When you specify an input in a workflow file or use a default input value, GitHub creates an environment variable for the input with the name `INPUT_<VARIABLE_NAME>`. The environment variable created converts input names to uppercase letters and replaces spaces with `_` characters.

So to get our input parameters, reading the environment variables `INPUT_NUMBER-ONE` and `INPUT_NUMBER-TWO` will be enough.

Last but not least, we need to find a way to define our action's output. Picking up the shovel again and digging further into the documentation, we'll discover [a section](https://docs.github.com/en/actions/using-jobs/defining-outputs-for-jobs#overview) that enlightens us about the existence of a `GITHUB_OUTPUT` environment variable containing a file's path. This file will serve as an output buffer for the currently running step, and using it is as simple as writing the string `<output_variable_name>=<value>` in it.

In our case, we'll have to write `result=<sum of the inputs>` in the file at path `$GITHUB_OUTPUT`, and we'll be done.

To sum up, we need a library/framework/stack that offers comfy APIs to read the content of environment variables and write stuff into files that have been compiled for Scala.js.

Unluckily the Scala standard library won't be enough even for such a simple task (unless you'll manually call some node.js APIs). If only there was **a tech stack offering a resource-safe, referentially transparent way to perform these operations and a nice asynchronous API to call other processes, like other command line tools**!

### Typelevel toolkit

Luckily for everybody, such a stack exists. The [Typelevel] libraries are published for many Scala versions and for every platform Scala supports, including [Scala native](https://typelevel.org/platforms/native/). [Most of them](https://typelevel.org/platforms/js/) can be used in a node.js action.

The most straightforward way to test this stack's fundamental libraries is using the Typelevel toolkit. The toolkit is a meta library that includes (among the others) [Cats Effect], [fs2-io] for streaming, [a library to parse command line arguments](https://ben.kirw.in/decline/effect.html), [a JSON serde that supports automatic Scala 3 derivation](https://circe.github.io/circe/) and [an HTTP client](https://http4s.org/v0.23/docs/client.html).

To use the toolkit, it's enough to declare it as a dependency in our scala-cli script:

{% codeBlock(title="index.scala", color="red") %}
```scala
//> using scala "3.2.2"
//> using platform "js"
//> using jsVersion "1.13.1"
//> using jsModuleKind "common"
//> using dep "org.typelevel::toolkit::latest.release"

object index extends App:
    println("Hello world")
```
{% end %}

Now it's time to write an input reading function: we can use `cats.effect.std.Env` to access the environment variables

```scala
import cats.effect.IO
import cats.effect.std.Env

def getInput(input: String): IO[Option[String]] =
  Env[IO].get(s"INPUT_${input.toUpperCase.replace(' ', '_')}")
```

With the same method, we can get the output file path and write the output in it:

```scala
import fs2.io.file.{Files, Path}
import fs2.Stream

def outputFile: IO[Path] =
  Env[IO].get("GITHUB_OUTPUT").map(_.get).map(Path.apply) // unsafe Option.get

def setOutput(name: String, value: String): IO[Unit] =
  outputFile.flatMap(path =>
    Stream[IO, String](s"${name}=${value}")
      .through(Files[IO].writeUtf8(path))
      .compile
      .drain
  )
```

Last but not least, we can write the logic of our application:

```scala
import cats.effect.IOApp

object index extends IOApp.Simple:
  def run = for {
    number1 <- getInput("number-one").map(_.get.toInt) // unsafe
    number2 <- getInput("number-two").map(_.get.toInt) // unsafe
    _ <- setOutput("result", s"${number1 + number2}")
  } yield ()
```

The whole action implementation will then be

{% codeBlock(title="index.scala", color="red") %}
```scala
//> using scala "3.2.2"
//> using platform "js"
//> using jsVersion "1.13.1"
//> using jsModuleKind "common"
//> using dep "org.typelevel::toolkit::latest.release"

import cats.effect.{ExitCode, IO, IOApp}
import cats.effect.std.Env
import fs2.io.file.{Files, Path}
import fs2.Stream

def getInput(input: String): IO[Option[String]] =
  Env[IO].get(s"INPUT_${input.toUpperCase.replace(' ', '_')}")

def outputFile: IO[Path] =
  Env[IO].get("GITHUB_OUTPUT").map(_.get).map(Path.apply) // unsafe Option.get

def setOutput(name: String, value: String): IO[Unit] =
  outputFile.flatMap(path =>
    Stream[IO, String](s"${name}=${value}")
      .through(Files[IO].writeUtf8(path))
      .compile
      .drain
  )

object index extends IOApp.Simple:
  def run = for {
    number1 <- getInput("number-one").map(_.get.toInt) // unsafe Option.get
    number2 <- getInput("number-two").map(_.get.toInt) // unsafe Option.get
    _ <- setOutput("result", s"${number1 + number2}")
  } yield ()
```
{% end %}

<details>
<summary>Safer and shorter alternative that uses decline</summary>

{% codeBlock(title="index.scala", color="red") %}
```scala
//> using scala "3.2.2"
//> using platform "js"
//> using jsVersion "1.13.1"
//> using jsModuleKind "common"
//> using dep "org.typelevel::toolkit::latest.release"

import cats.effect.{IO, ExitCode}
import cats.syntax.all.*
import fs2.Stream
import fs2.io.file.{Files, Path}
import com.monovore.decline.Opts
import com.monovore.decline.effect.CommandIOApp

val args = (
  Opts.env[Int]("INPUT_NUMBER-ONE", "The first number"),
  Opts.env[Int]("INPUT_NUMBER-TWO", "The second number"),
  Opts.env[String]("GITHUB_OUTPUT", "The file of the output").map(Path.apply)
)

object index extends CommandIOApp("adder", "Summing two numbers"):
  def main = args.mapN { (one, two, path) =>
    Stream(s"result=${one + two}")
      .through(Files[IO].writeUtf8(path))
      .compile
      .drain
      .as(ExitCode.Success)
  }
```
{% end %}

</details>

Now that the logic is in place, we must produce a `.js` file and **commit it** in the repo, as the action runtime won't interpret our Scala code. Scala-cli helps us: running `scala-cli --power package -f index.scala` produces an `index.js` file that our action can run.

The content of our repository should now be this:

```tree
.
├── action.yml
├── index.js
└── index.scala
```

It's time to check if our action work as intended.

### Testing never hurts

There are a few ways to test if an action you're developing works as intended. The best one is probably using [act], as the feedback cycle will be shorter. Sadly, the last time I checked `sbt` (and possibly `scala-cli`) was included only in the complete runtime image, requiring you to download the whole ~20GB container image.

The quickest way to test the action is to run it directly on the GitHub Runners and set up its CI to test the logic: the only required thing is a workflow file under `.github/workflows`.

As we must commit the transpiled version of our source code, a preliminary check that the `.js` file corresponds to the source `.scala` file is a good idea. The easiest way to test that they match is to recompile the `.scala` file with scala-cli and to use the good old `git diff`:

```yml
check-js-file:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v3                     # Checking out our code
    - uses: actions/setup-java@v3
      with:
        distribution: temurin
        java-version: 17
    - uses: coursier/cache-action@v6
    - uses: VirtusLab/scala-cli-setup@main          # Installing scala-cli
    - run: scala-cli --power package -f index.scala # Recompiling our code
    - run: git diff --quiet index.js                # Silently failing if there's any difference
```

> One thing to consider is that we used `latest.release` as the toolkit version, making our build non reproducible. Pinning the dependencies' versions is usually a good idea. Also, pinning each action version (i.e. `- uses:VirtusLab/scala-cli-setup@v1.0.0-RC2`) might decrease the chances that your CI will produce a different js file (and thus failing) in the future.

Once sure that the transpiled version of our code is correct, we can run our action and test its output directly in its own CI:

```yml
test-action-itself:
  needs: check-js-file                # There's no point in testing the wrong version
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v3
    - uses: ./                        # Here we'll use the action itself
      id: test-gh-action
      with:
        number-one: 3
        number-two: 9
    - run: test 12 -eq "${{ steps.test-gh-action.outputs.result }}"
```

The last action uses the good old `test` command (aka `[`) to check the action's output for the specified inputs.

<details>
<summary>Complete CI file</summary>

{% codeBlock(title=".github/workflows/ci.yml", color="green") %}
```yml
name: Continuos Integration
on:
  pull_request:
    branches: ['**']
  push:
    branches: ['**', '!update/**', '!pr/**']

jobs:
  check-js-file:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-java@v3
        with:
          distribution: temurin
          java-version: 17
      - uses: coursier/cache-action@v6
      - uses: VirtusLab/scala-cli-setup@main
      - run: scala-cli --power package -f index.scala
      - run: git diff --quiet index.js

  test-action-itself:
    needs: check-js-file
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: ./
        id: test-gh-action
        with:
          number-one: 3
          number-two: 9
      - run: test 12 -eq "${{ steps.test-gh-action.outputs.result }}"
```
{% end %}

</details>

### Using the action

To let the world use your new and shiny Scala.js-powered GitHub Action, commit every mentioned file in a public repository, let's say [`TonioGela/test-gh-action`](https://github.com/TonioGela/test-gh-action), and use the repository slug in every other action on the whole GitHub:

```yml
# ...
  - name: Sum numbers with Scala
    id: this-is-the-id
    uses: TonioGela/test-gh-action@main # specify a branch name, a version or a commit sha
    with:
        number-one: 3
        number-two: 9
# ...
```

### Further considerations

The example in this post is meant to show how to use a combination of tools and libraries to create a Github Action and doesn't show the true power of the Typelevel stack. A recent addition to [fs2-io] that can be handy in the context of an action might be the [Processes apis], with whom you can invoke external commands/tools handling their stdin, stdout, and exit codes:

```scala
import cats.effect.{Concurrent, MonadCancelThrow}
import fs2.io.process.{Processes, ProcessBuilder}
import fs2.text

def helloProcess[F[_]: Concurrent: Processes]: F[String] =
  ProcessBuilder("echo", "Hello, process!").spawn.use { process =>
    process.stdout.through(text.utf8.decode).compile.string
  }
```

The toolkit includes the `Ember` client and its `circe` integration, with whom you can easily call any external service and deserialize its output in a case class:

```scala
import cats.effect.IO
import cats.syntax.all.*
import io.circe.Decoder
import org.http4s.circe.jsonOf
import org.http4s.EntityDecoder
import org.http4s.ember.client.EmberClientBuilder

case class Foo(bar:String) derives Decoder
given EntityDecoder[IO, Foo] = jsonOf[IO, Foo]

EmberClientBuilder.default[IO].build.use { client =>
    client.expect[Foo](s"https://foo.bar").flatMap(foo => IO.println(foo))
}
```

The toolkit's site contains a [few examples](https://typelevel.org/toolkit/examples.html) of what you can do with it. Go take a look :smile:

## Conclusions

Despite being a bit unripe, I find this approach fascinating and easy to use (in particular if you don't know any `js` in 2023 :innocent:). 

In the future, I might consider rewriting in Scala.js the [actions/toolkit](https://github.com/actions/toolkit) library or a part of it (I might have to learn javascript :facepalm:). If you want to contribute, feel free to [contact me](https://discord.com/users/TonioGela#2735).

One thing that's worth exploring is the interaction with [Scala-Steward](https://github.com/scala-steward-org/scala-steward). Can the CI be set up to re-generate the js and commit the result? Probably yes, with `postUpdateHooks`. Is it desirable? I'm still not sure.


You'll find the code written in the post in [this repository](https://github.com/TonioGela/test-gh-action)

Enjoy!

[types of actions]: https://docs.github.com/en/actions/creating-actions/about-custom-actions#types-of-actions
[Docker container Actions]: https://docs.github.com/en/actions/creating-actions/creating-a-docker-container-action
[@armanbilge]: https://github.com/armanbilge
[metadata syntax]: https://docs.github.com/en/actions/creating-actions/metadata-syntax-for-github-actions
[inputs]: https://docs.github.com/en/actions/creating-actions/metadata-syntax-for-github-actions#inputs
[Typelevel]: https://typelevel.org/
[Typelevel toolkit]: https://typelevel.org/toolkit/
[Cats Effect]: https://typelevel.org/cats-effect/
[fs2-io]: https://fs2.io/#/io
[act]: https://github.com/nektos/act
[Processes apis]: https://fs2.io/#/io?id=processes