+++
title = "Integration testing the Typelevel toolkit"
date = 2023-10-04
slug = "testing-typelevel-toolkit"
language="en"
draft = false
[extra]
description = "How do you test a meta library that is meant to be used mainly via `scala-cli`? And also, how do you automatize the tests for every platform that the meta library supports? Here's how we did in a weekend full of `sbt`_-fu_."
+++

The [Typelevel toolkit] is a metalibrary including some **great libraries** by [Typelevel], that was created to speed up the development of cross-platform applications in Scala and that I happily maintain since its creation. It's the Typelevel's flavour of the official [Scala Toolkit], a set of libraries to perform common programming tasks, that has its own section, full of examples, in the [official Scala documentation](https://docs.scala-lang.org/toolkit/introduction.html).

One of the vaunts of the Typelevel's stack is the fact that (almost) every library is published for the all the **three officially supported Scala platforms: JVM, JS and Native**, and for this reason every library is **heavily tested** against every supported platform and Scala version, to ensure a near perfect cross-compatibility.

Since its creation the [Typelevel toolkit] was lacking any sort of testing, mainly due to the fact that it is a mere collection of already battle tested libraries, so why bothering writing tests for it? As [this bug](https://github.com/typelevel/toolkit/issues/49) promptly reminded us, the main goal of the toolkit is to provide the most seamless experience while using [scala-cli].

Ideally you should be able to write:

{% codeBlock(title="helloWorld.scala") %}
```scala
//> using toolkit typelevel:latest

import cats.effect.*

object Hello extends IOApp.Simple:
  def run = IO.println("Hello World!")
```
{% end %}

and calling `scala-cli run {,--js,--native} helloWorld.scala` should **Just Work™** printing `"Hello World!"` to the console.

To be 100% sure we needed CI tests indeed.

## Planning the tests

What had to be tested though? All the included libraries are already tested, some of them are built using other included libraries, so some sort of **cross testing** was already done. What we were really interested in was always **being sure that scala-cli is always able to compile scripts written using the toolkit**. And what's the best way to ensure that `scala-cli` can compile a script written with the toolkit if not using `scala-cli` itself? 

`Pause for dramatic effect`

The coarse idea that [Arman](https://github.com/armanbilge) and I had in mind was to have a CI doing the following:
- **Locally publishing** the toolkit artifact
- Passing the artifact's version to a bunch of **pre-baked parametrized scripts**
- **Running** the scripts with `scala-cli`
- Be happy if every exit code is **0**

The **third step** in particular could have been implemented in a couple of ways:
1) Installing `scala-cli` in the CI image via GitHub Actions, call it from the tests code, and gather the results
2) Since `scala-cli` is a [native executable generated by GraalVM Native Image](https://scala-cli.virtuslab.org/docs/under-the-hood) and the corresponding jvm artifact [is distributed](https://repo1.maven.org/maven2/org/virtuslab/scala-cli/cli_3/), using it as a dependency and calling its main method in the tests.

We decided to follow the latter, as we didn't want to **mangle the GitHub Actions CI file** or relying on the **timely publication of the updated scala-cli GitHub Action**: whenever any continuous integration setting is changed, every developer should apply the same or an equivalent change to its local environment to reflect the testing/building remote environment change. This also means more testing/contributing documentation that needs to be constantly updated (and that risks becoming outdated at every CI setting changed) and that the contributing/developing curve becomes steeper for newcomers (it's easier to ask a Scala developer to have just one build tool installed locally, right?).

Also, [sbt] is a superb tool for implementing this kind of tests: since it downloads automatically the specified scala-cli artifact we didn't need to have scala-cli installed locally, the version we are testing in particular. The build would be more self-contained, the scala-cli artifact version will be managed as every other dependency by [scala-steward](https://github.com/scala-steward-org/scala-steward) and developers and contributors could test locally the repository with ease with a simple `sbt test`.

> **BONUS EXAMPLE**: Using `scala-cli` in `scala-cli` to run a `scala-cli` script that runs itself
>{% codeBlock(title="recursiveScalaCli.scala", color="green") %}
```scala
//> using dep org.virtuslab.scala-cli::cli::1.0.4

import scala.cli.ScalaCli

object ScalaCliApp extends App:
    ScalaCli.main(Array("run", "recursiveScalaCli.scala"))
```
{%end%}

## First tentative: using the dependency in tests

In order to publish the artifacts locally before testing we needed a new `tests` project and to establish this relationship:

{% codeBlock(title="build.sbt") %}
```scala
//...
lazy val root = tlCrossRootProject.aggregate(
  toolkit, 
  toolkitTest,
  tests
)
//...
lazy val tests = project
  .in(file("tests"))
  .settings(
    name := "tests",
    Test / test := (Test / test).dependsOn(toolkit.jvm / publishLocal).value
  )
//...
```
{%end%}

In this way the `test` sbt command will always run a `publishLocal` of the jvm flavor of the toolkit artifact. The project then needed to be set to **not publish its** artifact and to have some dependencies added to actually write the tests. The `scala-cli` dependency needed some trickery (`.cross(CrossVersion.for2_13Use3)`) to use the Scala 3 artifact, the only one published, in Scala 2.13 as well.

{% codeBlock(title="build.sbt") %}
```scala
//...
lazy val tests = project
  .in(file("tests"))
  .settings(
    name := "tests",
    Test / test := (Test / test).dependsOn(toolkit.jvm / publishLocal).value,
    // Required to use the scala 3 artifact with scala 2.13
    scalacOptions ++= {
      if (scalaBinaryVersion.value == "2.13") Seq("-Ytasty-reader") else Nil
    },
    libraryDependencies ++= Seq(
      "org.typelevel" %% "munit-cats-effect" % "2.0.0-M3" % Test,
      // This is needed to write scripts' body into files
      "co.fs2" %% "fs2-io" % "3.9.2" % Test,
      "org.virtuslab.scala-cli" %% "cli" % "1.0.4" % Test cross (CrossVersion.for2_13Use3)
    )
  )
  .enablePlugins(NoPublishPlugin)
//...
```
{%end%}

The last bit needed was a way to add to the scripts' body **which version of the artifact we were publishing right before the testing step and which Scala version we were running on**, in order to test it properly. The only place were this **(non-static)** information was present was the build itself, but we needed to have them **as an information in the source code**. We definitively needed some sbt trickery to make it happen.

> There is an **unspoken rule** about the Scala community (or in the sbt users community to be precise) that you may already know about: 
>
> _If you need some kind of sbt trickery, **[eed3si9n]** probably wrote a sbt plugin for that_.

This was our case with [sbt-buildinfo], a sbt plugin whose punchline is "_I know this because build.sbt knows this_". As you'll discover later, **sbt-buildinfo has been the corner stone of our second and more exhausting approach**, but what briefly does is generating Scala source from your build definitions, and thus makes build information available in the source code too.

As `scalaVersion` and `version` are two information that are injected by default, we just needed to add the plugin into `project/plugins.sbt` and enabling it on `tests` in the build:

{% codeBlock(title="projects/plugins.sbt") %}
```scala
//...
addSbtPlugin("com.eed3si9n" % "sbt-buildinfo" % "0.11.0")
```
{%end%}

{% codeBlock(title="build.sbt") %}
```scala
//...
lazy val tests = project
  .in(file("tests"))
  .settings(
    name := "tests",
    Test / test := (Test / test).dependsOn(toolkit.jvm / publishLocal).value,
    // Required to use the scala 3 artifact with scala 2.13
    scalacOptions ++= {
      if (scalaBinaryVersion.value == "2.13") Seq("-Ytasty-reader") else Nil
    },
    libraryDependencies ++= Seq(
      "org.typelevel" %% "munit-cats-effect" % "2.0.0-M3" % Test,
      // This is needed to write scripts' body into files
      "co.fs2" %% "fs2-io" % "3.9.2" % Test,
      "org.virtuslab.scala-cli" %% "cli" % "1.0.4" % Test cross (CrossVersion.for2_13Use3)
    )
  )
  .enablePlugins(NoPublishPlugin, BuildInfoPlugin)
//...
```
{%end%}

**Time to write the tests!** The first thing that was needed was a way to write on a temporary file the body of the script, including the artifact and Scala version, and then submit the file to scala-cli main method:

{% codeBlock(title="ToolkitTests.scala") %}
```scala
package org.typelevel.toolkit

import munit.CatsEffectSuite
import cats.effect.IO
import fs2.Stream
import fs2.io.file.Files
import scala.cli.ScalaCli
import buildinfo.BuildInfo.{version, scalaVersion}

class ToolkitCompilationTest extends CatsEffectSuite {

  testRun("Toolkit should compile a simple Hello Cats Effect") {
    s"""|import cats.effect._
        |
        |object Hello extends IOApp.Simple {
        |  def run = IO.println("Hello toolkit!")
        |}"""
  }

  // We'll describe this method in a later section of the post
  def testRun(testName: String)(scriptBody: String): Unit = test(testName)(
    Files[IO].tempFile(None, "", "-toolkit.scala", None)
      .use { path =>
          val header = List(
            s"//> using scala ${BuildInfo.scalaVersion}",
            s"//> using toolkit typelevel:${BuildInfo.version}",
          ).mkString("", "\n", "\n")
        Stream(header, scriptBody.stripMargin)
          .through(Files[IO].writeUtf8(path))
          .compile
          .drain >> IO.delay(
          ScalaCli.main(Array("run", path.toString))
        )
      }
  )
}
```
{%end%}

And with this easy and lean approach we were finally able to **test the toolkit**! :tada::tada::tada:

`Another pause for dramatic effect`

Except we weren't really testing everything: the `js` and `native` artifact weren't tested by this approach, as the `tests` project is a jvm only project depending on `toolkit.jvm`. Also, the `toolkit-test` artifact wasn't even taken in consideration. We needed a more general/agnostic solution.

## Second approach: Invoking Java as an external process

The first tentative was good but not satisfying at all: we had to find a way to test the `js` and `native` artifacts too, but how? The `scala-cli` artifact is **JVM Scala 3 only**, and there's no way to use it as a dependency on other platforms. The only way to use it is just through the jvm, and that's **precisely what we decided to do**.

Given that:
- At least a JVM was present in the testing environment
- `fs2.io.process` exposes a **cross-platform way to launch and manage external processes**
- we had the scala-cli artifact on our classpath

we knew that was possible, there was just some `sbt`_-fu_ needed. 

The thing we needed to intelligently invoke was a mere `java -cp <scala-cli + transitive deps classpath> scala.cli.ScalaCli`, pass to it `run <scriptFilename>.scala` and wait for the exit code, for each `(scalaVersion,platform)` combination.

### BuildInfo magic

To begin we had to transform the `tests` project in to a cross project (using [sbt-crossproject](https://github.com/portable-scala/sbt-crossproject), that is embedded in [sbt-typelevel]) and make every subproject `test` command depend on the publication of the respective artifacts:

{% codeBlock(title="build.sbt") %}
```scala
//...
lazy val tests = crossProject(JVMPlatform, JSPlatform, NativePlatform)
  .in(file("tests"))
  .settings(
    name := "tests",
    scalacOptions ++= {
      if (scalaBinaryVersion.value == "2.13") Seq("-Ytasty-reader") else Nil
    },
    libraryDependencies ++= Seq(
      "org.typelevel" %%% "munit-cats-effect" % "2.0.0-M3" % Test,
      "co.fs2" %%% "fs2-io" % "3.9.2" % Test,
      "org.virtuslab.scala-cli" %% "cli" % "1.0.4" cross (CrossVersion.for2_13Use3)
    )
  )
  .jvmSettings(
    Test / test := (Test / test).dependsOn(toolkit.jvm / publishLocal, toolkitTest.jvm / publishLocal).value
  )
  .jsSettings(
    Test / test := (Test / test).dependsOn(toolkit.js / publishLocal, toolkitTest.js / publishLocal).value
    scalaJSLinkerConfig ~= { _.withModuleKind(ModuleKind.CommonJSModule) }
  )
  .nativeSettings(
    Test / test := (Test / test).dependsOn(toolkit.native / publishLocal, toolkitTest.native / publishLocal).value
  )
  .enablePlugins(BuildInfoPlugin, NoPublishPlugin)
//...
```
{% end %}

One thing to note is that we deliberately made a "mistake". The `munit-cats-effect` and `fs2-io` dependencies are declared using `%%%` the operator that not only appends `_${scalaBinaryVersion}` to the end of the artifact name but also the platform name (appending i.e. for a Scala 3 native dependency `_native0.4_3`), but the `scala-cli` one was declared using just `%%` and the `% Test` modifier was removed. In this way we were sure that, for **every platform**, the `Compile / dependencyClasspath` would have included just the **jvm version of scala-cli**.

To inject the classpath into the source code we leveraged our beloved friend [sbt-buildinfo], that **it's not limited to inject just `SettingKey[T]`s** and/or static information (computed at project load time), but using its own syntax **can inject `TaskKey[T]`s after they've been evaluated** (and re-evaluated each time at compile). So in the common `.settings` we added: 

{% codeBlock(title="build.sbt") %}
```scala
///...
  buildInfoKeys += scalaBinaryVersion,
  buildInfoKeys += BuildInfoKey.map(Compile / dependencyClasspath) {
      case (_, v) =>
        "classPath" -> v.seq
          .map(_.data.getAbsolutePath)
          .mkString(File.pathSeparator) // That's the way java -cp accepts classpath info
    },
    buildInfoKeys += BuildInfoKey.action("javaHome") {
      val path = sys.env.get("JAVA_HOME").orElse(sys.props.get("java.home")).get
      if (path.endsWith("/jre")) {
        // handle JDK 8 installations
        path.replace("/jre", "")
      } else path
    },
    buildInfoKeys += "scala3" -> (scalaVersion.value.head == '3')
///...
```
{% end %}

and in each platform specific section we added to buildInfo the platform's name:

{% codeBlock(title="build.sbt") %}
```scala
//...
  .jvmSettings(
    //...
    buildInfoKeys += "platform" -> "jvm"
  )
  .jsSettings(
    //...
    buildInfoKeys += "platform" -> "js",
  )
  .nativeSettings(
    //...
    buildInfoKeys += "platform" -> "native"
  )
//...
```
{% end %}

in this way we could leverage in our source code all the information required to run `scala-cli` and test our snippets:

```scala
private val classPath: String          = BuildInfo.classPath
private val javaHome: String           = BuildInfo.javaHome
private val platform: String           = BuildInfo.platform
private val scalaBinaryVersion: String = BuildInfo.scalaBinaryVersion
private val scala3: Boolean            = BuildInfo.scala3
```

### Invoking Java via fs2 `Process`

Once we had all the required components, invoking java was easy, we just created and spawned a [Process](https://fs2.io/#/io?id=processes) from the package `fs2.io.process`, that is implemented for every platform under the very same API:

{% codeBlock(title="ScalaCliTest.scala") %}
```scala
import buildinfo.BuildInfo
import cats.effect.kernel.Resource
import cats.effect.std.Console
import cats.effect.IO
import cats.syntax.parallel.*
import fs2.Stream
import fs2.io.file.Files
import fs2.io.process.ProcessBuilder
import munit.Assertions.fail

object ScalaCliProcess {

  private def scalaCli(args: List[String]): IO[Unit] = ProcessBuilder(
    s"${BuildInfo.javaHome}/bin/java",
    args.prependedAll(List("-cp", BuildInfo.classPath, "scala.cli.ScalaCli"))
  ).spawn[IO]
    .use(process =>
      (
        process.exitValue,
        process.stdout.through(fs2.text.utf8.decode).compile.string,
        process.stderr.through(fs2.text.utf8.decode).compile.string
      ).parFlatMapN {
        case (0, _, _) => IO.unit
        case (exitCode, stdout, stdErr) =>
          IO.println(stdout) >> Console[IO].errorln(stdErr) >> IO.delay(
            fail(s"Non zero exit code ($exitCode) for ${args.mkString(" ")}")
          )
      }
    )

  //..

}
```
{% end %}

Let's dissect this function:
- `ProcessBuilder` constructor accepts a `String` command and a list of `String` arguments, it can then spawn the subprocess using `.spawn[IO]`, that will return a `Resource[IO, Process[IO]]`. Resource is a really useful Cats Effect datatype that deserves its own post, but you can find some information in [the official documentation](https://typelevel.org/cats-effect/docs/std/resource).
- The `Process[IO]` resource is `use`d, and its exit code is gathered, **in parallel**, together with its stdout and stderr using `parFlatMapN`. This will prevent deadlocking, as we won't wait for a process' exit code without consuming its stdout and stderr streams.
- Once we have the results, if the exit code is 0 we'll simply discard the content of the streams, otherwise we'll print everything that might be useful to debug possible errors, and we'll instruct our testing framework to fail with a specific message.

Now we needed a method to write in a temporary file the source of each scala-cli script with all the information needed to correctly test the toolkit. Luckily for us `fs2` makes it easy:

{% codeBlock(title="ScalaCliTest.scala") %}
```scala
//...
  private def writeToFile(scriptBody: String)(isTest: Boolean): Resource[IO, String] =
    Files[IO].tempFile(None,"",if (isTest) "-toolkit.test.scala" else "-toolkit.scala", None)
      .evalTap { path =>
        val header = List(
          s"//> using scala ${BuildInfo.scalaVersion}",
          s"//> using toolkit typelevel:${BuildInfo.version}",
          s"//> using platform ${BuildInfo.platform}"
        ).mkString("", "\n", "\n")
        Stream(header, scriptBody.stripMargin)
          .through(Files[IO].writeUtf8(path))
          .compile
          .drain
      }
      .map(_.toString)
//...
```
{% end %}

Dissecting this function too we'll see that:
- `Files[IO].tempFile` creates a temporary file as a `Resource`, whose release method will **delete the temporary file**.
- The `isTest` parameter is used to determine the extension that the temp file will have, as `scala-cli` requires a specific extension for both source and test files.
- `.evalTap` will run an effectful side effect but returning the same `Resource` it was called on. In this case it will write the script content in the newly created temp file. This effect will run **AFTER** the file creation, but **BEFORE** any other effectful action that can be performed in the `use` method.
- In the effect we'll produce a set of `scala-cli` directives using `BuildInfo`, we'll prepend them to the script's body and write everything in the temp file.
- The path of the freshly baked scala-cli script will then be provided as a `Resource[IO, String]`

The only thing we needed to do was to **combine the two methods** into a testing method:

{% codeBlock(title="ScalaCliTest.scala") %}
```scala
//...
  def testRun(testName:String)(body: String): IO[Unit] = 
   test(testName)(writeToFile(body)(false).use(f => scalaCli("run" :: f :: Nil)))

  def testTest(testName:String)(body: String): IO[Unit] = 
    test(testName)(writeToFile(body)(true).use(f => scalaCli("test" :: f :: Nil)))
//...
```
{% end %}

To recap, each of the two methods will run a munit test that:
- write the `body` argument to a temporary file with the correct extension, prepending the correct `scala-cli` directives
- run either the command `scala-cli run` or `scala-cli test` against the newly created file
- use the exit code of the process to establish if the test is passed or not
- delete the temporary file

The **produced files** will look, for example, like this:

```scala
//> using scala 3
//> using toolkit typelevel:typelevel:0.1.14-29-d717826-20231004T153011Z-SNAPSHOT
//> using platform jvm

import cats.effect.*

object Hello extends IOApp.Simple:
  def run = IO.println("Hello toolkit!")
```

where `0.1.14-29-d717826-20231004T153011Z-SNAPSHOT` is the version of the toolkit that was just **published** locally by sbt.

## Test writing

It was then **Time to write and run the actual tests!**

{% codeBlock(title="ToolkitTests.scala") %}
```scala
import munit.CatsEffectSuite
import buildinfo.BuildInfo.scala3
import ScalaCliTest.{testRun, testTest}

class ToolkitTests extends CatsEffectSuite {

  testRun("Toolkit should run a simple Hello Cats Effect") {
    if (scala3)
      """|import cats.effect.*
         |
         |object Hello extends IOApp.Simple:
         |  def run = IO.println("Hello toolkit!")"""
    else
      """|import cats.effect._
         |
         |object Hello extends IOApp.Simple {
         |  def run = IO.println("Hello toolkit!")
         |}"""
  }

  testTest("Toolkit should execute a simple munit suite") {
    if (scala3)
      """|import cats.effect.*
         |import munit.*
         |
         |class Test extends CatsEffectSuite:
         |  test("test")(IO.unit)"""
    else
      """|import cats.effect._
         |import munit._
         |
         |class Test extends CatsEffectSuite {
         |  test("test")(IO.unit)
         |}"""
  }
  //...
}
```
{% end %}

The little testing framework we wrote is now capable of both running and testing `scala-cli` scripts that use the typelevel toolkit, and it will test it in every platform and scala version. `sbt test` will now publish both the toolkit and the test toolkit, for every platform, right before running the unit tests, achieving in this way a complete coverage and adding reliability to our releases! :tada: 

And all of this was done without even touching our GitHub Actions, just with some `sbt`_-fu_, and **just using the libraries that are included in the toolkit itself** :sunglasses:

[Typelevel toolkit]: https://typelevel.org/toolkit/
[Typelevel]: https://github.com/typelevel/
[Scala Toolkit]: https://github.com/scala/toolkit/
[scala-cli]: https://scala-cli.virtuslab.org/
[sbt]: https://www.scala-sbt.org/
[eed3si9n]: https://github.com/eed3si9n
[sbt-buildinfo]: https://github.com/sbt/sbt-buildinfo
[scala-steward]: https://github.com/scala-steward-org/scala-steward
[sbt-typelevel]: https://github.com/typelevel/sbt-typelevel 