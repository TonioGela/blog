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
[Scala-cli](https://scala-cli.virtuslab.org/) is a recent command line tool by [VirtusLab](https://virtuslab.org/) that lets you interact with Scala in multiple ways. One of its most valuable features is the support to create single-file scripts that can use any Scala dependency and be packaged in various formats to run everywhere.

Once [installed](https://scala-cli.virtuslab.org/install), lets write in a `.scala` file a simple hello world application

{% codeBlock(title="Hello.scala") %}
```scala
object Hello {
  def main(args: Array[String]): Unit = println("Hello from scala-cli")
}
{%end%}

and run it using `scala-cli run Hello.scala`

```zsh
$ scala-cli run Hello.scala
# Compiling project (Scala 3.2.0, JVM)
# Compiled project (Scala 3.2.0, JVM)
Hello from scala-cli
```

By default, it downloads stuff


Top-down or bottom-up, using the functional style, you can do both.