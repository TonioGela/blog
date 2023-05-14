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

### Business logic

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

Now that we're able to produce a runnable js file it's time to create an actual GitHub action. The [official documentation for javascript actions](https://docs.github.com/en/actions/creating-actions/creating-a-javascript-action) recommends using the [`GitHub Actions Toolkit Node.js module`](https://github.com/actions/toolkit) to speed up development, and a "smart person" will probably use it, but the Actions' runtime offers an alternative.

Digging deep into the metadata syntax documentation, in the [inputs] section you'll find an interesting paragraph:

> When you specify an input in a workflow file or use a default input value, GitHub creates an environment variable for the input with the name `INPUT_<VARIABLE_NAME>`. The environment variable created converts input names to uppercase letters and replaces spaces with `_` characters.

So to get our input parameters, reading the environment variables `INPUT_NUMBER-ONE` and `INPUT_NUMBER-TWO` will be enough.

Last but not least, we need to find a way to define our action's output. 

### Testing never hurts


---
- Process APIs in fs2
- sfruttiamo lo stack tl perche' e' gia tutto ported a js
- tl toolkit comprende una serie di librerie comode per lo scopo
- scala-cli semplifica tutto
- si puo' testare l'azione stessa nella sua ci
- Per il futuro sarebbe bello scrivere i bindings per quella lib

[types of actions]: https://docs.github.com/en/actions/creating-actions/about-custom-actions#types-of-actions
[Docker container Actions]: https://docs.github.com/en/actions/creating-actions/creating-a-docker-container-action
[@armanbilge]: https://github.com/armanbilge
[metadata syntax]: https://docs.github.com/en/actions/creating-actions/metadata-syntax-for-github-actions
[inputs]: https://docs.github.com/en/actions/creating-actions/metadata-syntax-for-github-actions#inputs