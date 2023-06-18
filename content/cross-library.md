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

`"Library authors must be incredibly skilled (and patient) people that rewrite N times the same library"` was my thought at that time, and while I still believe that lib authors are **immensely talented people**, now I've clear ideas on how to cross-compile a library (and no, you don't have to rewrite everything).

This post aims to write a library for what we can imagine being the **worst case scenario**: a library should behave differently for every **platform and Scala version**. The best case scenario, for instance, is having every dependency already cross-compiled and writing our library/application just once. 

Wel'll also cover how to publish this library on **Maven Central**, taking care of **every step required**, from claiming a groupID to publishing a [Laika] powered documentation site passing from **automagically written CI workflows** for cross-testing and publication.

## Rough Idea
A simple idea for a cross-compiled library may be a wrapper for a simple static string composed of the platform's name and the major Scala version. Let's call this string `platformAndVersion`. It may not be useful, but it **quickly proves the point** of having different implementations for the same **shared** "facade".

Ideally printing this string in **different "conditions"** will produce different outputs, i.e.

{% codeBlock(title="platform.sc", color="red") %}
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

We'll implement such a library using [sbt-crossproject], an sbt plugin that adds cross-platform compilation support.

## Cross Building with sbt-crossproject

We already know from the [cross-building section of sbt's manual] that the mechanism to indicate which version of Scala a library was compiled against is to append the binary version, that's why we often see artifacts named `<lib-name>_2.13-<version>.jar` or `<lib-name>_3-<version>-sources.jar`.

We're also used to use the double `%%` when declaring a dependency in our builds to avoid specifying the Scala version: if our dependencies are declared like `"com.foo" %% "bar" % "0.0.1"`, changing the Scala version from i.e. `2.13.11` to `3.3.0` will automatically instrument coursier (via sbt) to download the correct artifact.

Sbt leverages suffixes even when it has to differentiate an artifact that was compiled against JVM Scala from an artifact compiled agains Scala Native or Scala.js. For this reason is common to see artifacts whose name ends in `_sjs1_2.13` or `_native0.4_3` and for the same reason the operator `%%%` was added to pick the correct native or js library version.

> Forgetting the third `%` is so common that someone though of creating [youforgotapercentagesignoracolon]

While sbt supports out of the box cross-building for different Scala versions, cross compiling a library for different platforms requires using [sbt-crossproject]. Since we'll build for all the three supported platforms, we have to use both scala-js and scala-native plugins, each in combination with its cross-project plugin

{% codeBlock(title="project/plugins.sbt", color="red") %}
```scala
addSbtPlugin("org.scala-js"       % "sbt-scalajs"                   % "1.13.1")
addSbtPlugin("org.portable-scala" % "sbt-scalajs-crossproject"      % "1.2.0")
addSbtPlugin("org.scala-native"   % "sbt-scala-native"              % "0.4.14")
addSbtPlugin("org.portable-scala" % "sbt-scala-native-crossproject" % "1.2.0")
```
{% end %}

`BUT we'll use it through sbt-tl`

### Rough Lineup

- [x] Rough Idea
- [ ] sbt-crossproject
- [ ] \+ vs ++
- [ ] publishLocal and have fun
- [ ] sbt-typelevel
- [ ] writing different tests for different platforms
- [ ] Claiming Maven Central GroupID
- [ ] github actions con dependency submission
- [ ] versioning and mima?
- [ ] Scala Steward + instance-creation with diy-steward
- [ ] Mergify
- [ ] Unidocs
- [ ] Site + domain 
- [ ] javadoc.io + scaladex

[Laika]: https://github.com/typelevel/Laika
[Sonartype]: https://central.sonatype.com/
[sbt-typelevel]: https://typelevel.org/sbt-typelevel
[diy-steward]: https://github.com/armanbilge/diy-steward
[sbt-crossproject]: https://github.com/portable-scala/sbt-crossproject
[cross-building section of sbt's manual]: https://www.scala-sbt.org/1.x/docs/Cross-Build.html
[youforgotapercentagesignoracolon]: (https://youforgotapercentagesignoracolon.com/)