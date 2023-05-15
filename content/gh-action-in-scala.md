+++
title = "Writing a GitHub Action with Scala.js"
date = 2023-05-13
slug = "gh-action-in-scala"
language="en"
draft = true
[extra]
description = "How to leverage [`scala-cli`](https://github.com/VirtusLab/scala-cli) and the [Typelevel Toolkit](https://github.com/typelevel/toolkit) to super charge your GitHub CI."
+++

Some months ago I discussed with a DevOps colleague the need for a custom GitHub Action at `$work`. The action we needed had to perform a bunch of tasks that weren't present in any action we were able to find, so we planned to write our own.

The chances were limited: there was the evergreen option to embed a **gigantic shell script** in the ci file (dealing with evergreen problems like escaping, quoting and indentation), the also evergreen option to **commit the script** in the repository itself or we could have written our **own GitHub action**.

The last option was the most interesting one. Writing business logic in a language that's more structured than bash was interesting, but we had to face the fact that, according to the documentation, only two [types of actions] exist (if you don't consider composite ones): `Docker Container Actions` and `Javascript Actions`.

Since no one had any intention whatsoever to write javascript code and [Docker Container Actions] had all the features we needed, we resorted to using one of them (despite their limitations in terms of compatibility).

Even though this <u>scarcely interesting success story</u> has a happy ending, a question emerged during the developments: `Is it possible to write a Github Action with Scala.js?`

> Also, I asked myself `Is it still possible to survive as a software developer in 2023 without ever having written a single line of javascript?`: you'll find the answer below.

**TLDR**: yes and [@armanbilge] did it in a couple of repositories like [this one](https://github.com/typelevel/await-cirrus), so in this post we'll dissect his approach to create a how-to guide. Thank you Arman! :heart:

## Creating a simple action

The first action we'll create will be a **simple adder** that will `sum up two numbers` that can be either defined in the build file or one of the results of one of the previous steps.

### Metadata

According to its [metadata syntax] page, every action defined in a repository requires an `action.yml` file that defines the inputs, the outputs and the run configuration for your action.

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

Once the metadata file is defined we'll have to write the business logic, but there are a few issues that need to be addressed:
- How do we produce a runnable js file?
- How do we read the action's inputs?
- How do we write the action's outputs?

The simplest and yet immensely powerful tool that will produce <u>javascript code from a single Scala file</u> is undoubtedly [`scala-cli`](https://github.com/VirtusLab/scala-cli) with its ability to define in a few lines packaging, platform and dependencies setting.

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

Packaging this file is as simple as running the command `scala-cli --power package -f index.scala` (we'll reuse this command later in our CI). This command will produce a `index.js` file that can be run locally using `node ./index.js`.

Now that we're able to produce a runnable js file it's time to create an actual GitHub action. The [official documentation for javascript actions](https://docs.github.com/en/actions/creating-actions/creating-a-javascript-action) recommends using the [`GitHub Actions Toolkit Node.js module`](https://github.com/actions/toolkit) to speed up development (a smart person will probably use it) but the Actions' runtime offers an alternative.

Digging deep into the metadata syntax documentation, in the [inputs] section you'll find an interesting paragraph:

> When you specify an input in a workflow file or use a default input value, GitHub creates an environment variable for the input with the name `INPUT_<VARIABLE_NAME>`. The environment variable created converts input names to uppercase letters and replaces spaces with `_` characters.

So to get our input parameters, reading the environment variables `INPUT_NUMBER-ONE` and `INPUT_NUMBER-TWO` will be enough.

Last but not least, we need to find a way to define our action's output. Picking up the shovel again and digging further in the documentation we'll discover [a section](https://docs.github.com/en/actions/using-jobs/defining-outputs-for-jobs#overview) that enlights us about the existence of a `GITHUB_OUTPUT` environment variable that will contain a file's path. This file will serve as an output buffer for the currently running step and using it is as simple as writing the string `<output_variable_name>=<value>` in it.

In our case, we'll have to write `result=<sum of the inputs>` in the file that sits at path `$GITHUB_OUTPUT` and we'll be done.

To sum up, we need a library/framework/stack that offers comfy APIs to read the content of environment variables and write stuff into files that have been compiled for Scala.js.

Unluckily the Scala standard library won't be enough even for such a simple task (unless you'll manually call some node.js APIs), so why don't we pick __*a tech stack that offers a resource-safe referentially transparent way to perform these operations and that has **a nice **asynchronous** API to** call other processes, like other command line tools*__?

### Typelevel toolkit

Luckily for everybody such a stack exists, the [Typelevel] libraries are published for a wide number of Scala versions, and for every platform that Scala supports (including [Scala native](https://typelevel.org/blog/2022/09/19/typelevel-native.html)).

The most straightforward way to test out most of the fundamental libraries this stack has to offer is to use the [Typelevel toolkit]. The toolkit is a meta library that includes (among the others) [Cats Effect], [fs2-io] for streaming, [a library to parse command line arguments](https://ben.kirw.in/decline/effect.html), [a JSON serde that supports automatic Scala 3 derivation](https://circe.github.io/circe/) and [an HTTP client](https://http4s.org/v0.23/docs/client.html).

To use the toolkit, it's enough to declare it as dependency in our scala-cli script:

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

With the same method we can get the output file path and write the output in it:

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

### Testing never hurts

- Commit the js
- Use actions to test the action itself
- The diff may break in the future due to `latest.release`
- Link the repo

---

- In the future it will be awesome to rewrite in pure scala the actions/toolkit dep

[types of actions]: https://docs.github.com/en/actions/creating-actions/about-custom-actions#types-of-actions
[Docker container Actions]: https://docs.github.com/en/actions/creating-actions/creating-a-docker-container-action
[@armanbilge]: https://github.com/armanbilge
[metadata syntax]: https://docs.github.com/en/actions/creating-actions/metadata-syntax-for-github-actions
[inputs]: https://docs.github.com/en/actions/creating-actions/metadata-syntax-for-github-actions#inputs
[Typelevel]: https://typelevel.org/
[Typelevel toolkit]: https://typelevel.org/toolkit/
[Cats Effect]: https://typelevel.org/cats-effect/
[fs2-io]: https://fs2.io/#/io