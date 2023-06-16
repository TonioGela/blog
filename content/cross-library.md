+++
title = "Cross publishing with sbt-typelevel"
date = 2023-06-18
slug = "cross-library"
language="en"
draft = true
[extra]
description = "Setting up the CI to test and publish a Scala library on Maven Central for every platform and version is no more a complicated task thanks to [`sbt-typelevel`](https://typelevel.org/sbt-typelevel)."
+++

In my early days as a Scala developer, one of the things that were more confusing to me was imagining the **immensely complicated machinery** that enabled people like me to use the same library for **different Scala versions and different platforms**.

`"Library authors must be incredibly skilled (and patient) people that rewrite N times the same library"` was my thought, and while I still believe that lib authors are **immensely talented people**, now I've clear ideas on how to cross-compile a library (and no, you don't have to rewrite everything).

This post aims to write a library that behaves differently **according to the platform and Scala version you are using** and to publish it on Maven Central, taking care of **every step required**, from claiming a groupID to publishing a [Laika] powered documentation site passing from **automagically written CI workflows** for cross-testing and publication.

## Simplest Library Idea Ever
A simple idea for a cross-compiled library may be a simple static string composed of the platform's name and the major Scala version. It's not useful, but it **quickly proves the point** of having different implementations for the same **shared** "facade":

{% codeBlock(title="platform.sc", color="scala") %}
```scala
//> using dep my-group-id::my-library::latest.release
println(Platform.platformAndVersion)
```
{% end %}

```cli
$ scala-cli run platform.sc
# jvm-3
$ scala-cli run platform.sc --scala 2.13.10
# jvm-2
$ scala-cli run platform.sc --native
# native-3
$ scala-cli run platform.sc --scala 2.13.10 --js
# jvm-3
...
```

`// Fix from here`

How do we implement this? Using [sbt-crossproject]


### Appunti
Racconta Moduli \
Scala-Steward \
Mergify \
Sito

[Laika]: https://github.com/typelevel/Laika
[sbt-crossproject]: https://github.com/portable-scala/sbt-crossproject