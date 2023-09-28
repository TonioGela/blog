+++
title = "Testing the typelevel toolkit"
date = 2023-09-25
slug = "testing-typelevel-toolkit"
language="en"
draft = true
[extra]
description = "How do you test a meta library that is meant to be used via `scala-cli`? And also, how do you automatize the tests for every platform that the meta library supports? Here's how we did in a weekend full of `sbt`_-fu_"
+++

The [Typelevel toolkit] is a metalibrary including some **great libraries** by [Typelevel] created to speed up the development of cross-platform applications in Scala. It's the Typelevel's flavour of the official [Scala Toolkit], a set of libraries to perform common programming tasks, that got its own section, full of examples, in the [official Scala documentation](https://docs.scala-lang.org/toolkit/introduction.html).

One of the vaunts of the Typelevel's stack is the fact that (almost) every library is published for the all the **three officially supported Scala platforms: JVM, JS and Native**, and for this reason every library is **heavily tested** against every supported platform and Scala version, to ensure a near perfect cross-compatibility.

Since its creation the [Typelevel toolkit] was lacking any sort of testing, mainly due to the fact that it is a mere collection of already battle tested libraries, so why bothering writing tests for it? As [this bug](https://github.com/typelevel/toolkit/issues/49) promptly reminded us, the main goal of the toolkit is to provide the most seamless experience while using [scala-cli]. 

Ideally you should be able to write:

{% codeBlock(title="helloWorld.scala", color="red") %}
```scala
//> using toolkit typelevel:latest

import cats.effect.*

object Hello extends IOApp.Simple:
  def run = IO.println("Hello World!")
```
{% end %}

specify any platform with `//> using platform {jvm,js,native}` and calling `scala-cli run helloWorld.scala` should **Just Work™** printing `"Hello World!"` to the console.

To be 100% sure we needed CI tests indeed.

## Planning the tests

What had to be tested though? All the included libraries are already tested, some of them are built using other included libraries, so some sort of **cross testing** was already done. What we were really interested in was always **being sure that scala-cli is always able to compile scripts written using the toolkit**. And what's the best way to ensure that `scala-cli` can compile a script written with the toolkit if not using `scala-cli` itself? 

`Pause for dramatic effect`

The coarse idea that [Arman](https://github.com/armanbilge) and I had in mind was to have a CI doing the following:
- **Locally publishing** the toolkit artifact
- Passing the artifact's version to a bunch of pre-baked parametrized scripts
- Running the scripts with `scala-cli`
- Be happy if every exit code is 0




[Typelevel toolkit]: https://typelevel.org/toolkit/
[Typelevel]: https://github.com/typelevel/
[Scala Toolkit]: https://github.com/scala/toolkit/
[scala-cli]: https://scala-cli.virtuslab.org/

- scala-cli in GH non ci piaceva, implementare test esternamente
- artifact publishing
- primo tentativo jvm only con il classpath
- Idea con BuildInfo
- Trasformare runtime error in compile errors
- cross platform con fs2, invocando java e dichiarando male la dipendenza