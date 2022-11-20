+++
title = "Creating a CLI sudoku solver with scala-cli"
date = 2022-11-13
slug = "overkilling-sudoku"
language="en"
draft = true
[extra]
description = "Writing a sudoku solver that brute forces a sudoku is an easy junior developer task. How about overkilling the task to create a fully-fledged command line application using `scala-cli`, `scala-native` and `decline`?"
+++


> This post was inspired by the Scala beginners' solution that Daniel [wrote](https://blog.rockthejvm.com/sudoku-backtracking/) and [recorded](https://youtu.be/zBLCbqycVzw) on his blog and Youtube channel **[Rock The JVM](https://rockthejvm.com/)**. I encourage you to read his blog post first if you are a Scala beginner, since it leverages mutability, resulting in a easier to understand solution that might give you the chance to get more familiar with the syntax of the language and with **recursion**.

# Introduction
[Sudoku](https://en.wikipedia.org/wiki/Sudoku) is a notorious combinatorial puzzle solvable with optimised and efficient algorithms. Today we won't focus on any of those techniques, but we'll leverage the computing power of our machines to brute-force the solution in a **functional immutable fashion.**

The Scala community has many fantastic tools and libraries to help us synthesise the solution and package our solver in an **ultra-fast native executable with instant startup times** using our favourite language and its expressivity. To implement our solution, I chose [scala-cli](https://scala-cli.virtuslab.org/) to structure the project and to compile it with [scala-native](https://scala-native.org/en/stable/), [decline](https://ben.kirw.in/decline/) to parse command line arguments and [cats](https://typelevel.org/cats/) for its purely functional approach.

## Scala-CLI: your best command line buddy
[Scala CLI](https://scala-cli.virtuslab.org/) is a recent command line tool by [VirtusLab](https://virtuslab.org/) that lets you interact with Scala in multiple ways. One of its most valuable features is the support to create single-file scripts that can use any Scala dependency and be packaged in various formats to run everywhere.

Once [installed](https://scala-cli.virtuslab.org/install), let's write in a `.scala` file a simple hello world application:

{% codeBlock(title="Hello.scala") %}
```scala
object Hello {
  def main(args: Array[String]): Unit = println("Hello from scala-cli")
}
{%end%}

and run it using `scala-cli run Hello.scala`

```sh
$ scala-cli run Hello.scala
# Compiling project (Scala 3.2.0, JVM)
# Compiled project (Scala 3.2.0, JVM)
Hello from scala-cli
```

Scala CLI default downloads the **latest scala version** and uses the available JVM installed on your system unless you specify otherwise.

```sh
$ scala-cli run Hello.scala --jvm "temurin:11" --scala "2.13.10"
# Downloading JVM temurin:11
# Compiling project (Scala 2.13.10, JVM)
# Compiled project (Scala 2.13.10, JVM)
Hello from scala-cli
```

The best way to alter the default behaviour through the various options Scala CLI lets you customise is [using Directives](https://scala-cli.virtuslab.org/docs/guides/using-directives).

### Directives
Let's say that for our script purposes, a library like [PPrint](https://github.com/com-lihaoyi/PPrint) might be convenient. Using directives it's possible to declare it as our script's dependency and to specify both the JVM and Scala versions we intend to run our script with:

{% codeBlock(title="Maps.scala") %}
```scala
//> using scala "2.13.10"
//> using jvm "temurin:11"
//> using lib "com.lihaoyi::pprint::0.6.6"

object Hello {
  def main(args: Array[String]): Unit =
    println("Maps in Scala have the shape " + pprint.tprint[Map[_,_]])
}
```
{% end %}

Now it's possible to execute the script with no additional command line flags

```sh
$ scala-cli run Hello.scala
# Compiling project (Scala 2.13.10, JVM)
# Compiled project (Scala 2.13.10, JVM)
Maps in Scala have the shape Map[_, _]
```

Through directives, it's possible, among other things, to add java options or compiler flags, declare tests, change the compilation target and decide whether to package the application producing a fat jar or a script that downloads all the required dependencies at its first usage. For a complete reference, see [Directives](https://scala-cli.virtuslab.org/docs/reference/scala-command/directives).

### Updating dependencies
As some of you may have noticed, the pprint library version in the example it's not the newest one: at the time of writing, the most recent version is 0.8.0. Luckily we're not forced to _check it manually on Github or Maven Central_ since Scala CLI exposes the `dependency-update` command that will fetch the last version of each dependency and **print a command to update them all**.

```sh
$ scala-cli dependency-update Maps.scala
Updates
   * com.lihaoyi::pprint::0.6.6 -> 0.8.0
To update all dependencies run:
    scala-cli dependency-update --all

$ scala-cli dependency-update --all Maps.scala
Updated dependency to: com.lihaoyi::pprint::0.8.0

$ head -3 Maps.scala
//> using scala "2.13.10"
//> using jvm "temurin:11"
//> using lib "com.lihaoyi::pprint::0.8.0"
```

### IDE support

Writing Scala code without the help of a fully-fledged IDE is fine if you're writing a "Hello world" application or similar, but for a _"complete programming experience"_ using one of the IDE alternatives, being IntelliJ or a Metals compatible one, is recommended. Scala CLI can help you set up your IDE of choice by generating the necessary files, providing you with full-blown IDE support. 

The [setup-ide](https://scala-cli.virtuslab.org/docs/commands/setup-ide) command is run before every `run`, `compile` or `test` but it can be invoked manually like:

```
scala-cli setup-ide Maps.scala
```

resulting in the generation of 2 files that both Metals and IntelliJ use to provide all their functionalities.

```
.
├── .bsp
│  └── scala-cli.json
├── .scala-build
│  └── ide-inputs.json
└── Maps.scala
```

Opening the _enclosing folder_ in your **Metals**-enabled editor or importing it in **IntelliJ** will provide you with the Scala IDE experience you're used to.

### Formatting
Our developer experience can't be complete without a properly configured formatter. Luckily Scala CLI supports [Scalafmt](https://scalameta.org/scalafmt/) configuration in the same format used in sbt, mill or similar, i.e. having a `.scalafmt.conf` file in the project's root folder

```
...
├── .scalafmt.conf
└── Maps.scala
```

and then running `scala-cli fmt Maps.scala`. The command can run even without the configuration file as it infers the version and dialect from the project. To save locally the default scalafmt configuration (to maybe use it with you IDE of choice), it's possible to use a flag: `scala-cli fmt Maps.scala --save-scalafmt-conf`.

**Now that we have a working IDE, we can begin modelling the problem and its solution.**

# Modeling a Sudoku Board

// Nuova sezione
Lo famo in scala 3, usiamo piu' files, facciamo i test, usiamo anche il flag `--all` per printare tutte le soluzioni


Top-down or bottom-up, using the functional style, you can do both.
That's not a comprehensive guide of all the features that scala-cli has, ofc.