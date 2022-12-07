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

The Scala ecosystem has many fantastic tools and libraries to help us synthesise the solution and package our solver in an **ultra-fast native executable with instant startup time** using our favourite language and its expressivity. To implement our solution, I chose [scala-cli](https://scala-cli.virtuslab.org/) to structure the project and to compile it with [scala-native](https://scala-native.org/en/stable/), [decline](https://ben.kirw.in/decline/) to parse command line arguments and [cats](https://typelevel.org/cats/) for its purely functional approach.

## Scala-CLI: your best command line buddy
[Scala CLI](https://scala-cli.virtuslab.org/) is a recent command line tool by [VirtusLab](https://virtuslab.org/) that lets you interact with Scala in multiple ways. One of its most valuable features is the support to create single-file scripts that can use any Scala dependency and be packaged in various formats to run everywhere.

Once [installed](https://scala-cli.virtuslab.org/install), let's write in a `.scala` file a simple hello world application:

{% codeBlock(title="Hello.scala") %}
```scala3
object Hello {
  def main(args: Array[String]): Unit = println("Hello from scala-cli")
}
```
{%end%}

and run it using `scala-cli run Hello.scala`

```cli
$ scala-cli run Hello.scala
# Compiling project (Scala 3.2.0, JVM)
# Compiled project (Scala 3.2.0, JVM)
Hello from scala-cli
```

Scala CLI default downloads the **latest scala version** and uses the available JVM installed on your system unless you specify otherwise.

```cli
$ scala-cli run Hello.scala --jvm "temurin:11" --scala "2.13.10"
# Downloading JVM temurin:11
# Compiling project (Scala 2.13.10, JVM)
# Compiled project (Scala 2.13.10, JVM)
Hello from scala-cli
```

The best way to alter the default behaviour through the various options Scala CLI lets you customise is [using Directives](https://scala-cli.virtuslab.org/docs/guides/using-directives).

### Directives
Let's say that for our script purposes, a library like [PPrint](https://github.com/com-lihaoyi/PPrint) might be convenient. Using directives, it's possible to declare it as our script's dependency and to specify both the JVM and Scala versions we intend to run our script with:

{% codeBlock(title="Maps.scala") %}
```scala3
//> using scala "2.13.10"
//> using jvm "temurin:11"
//> using lib "com.lihaoyi::pprint::0.6.6"

object Maps {
  def main(args: Array[String]): Unit =
    println("Maps in Scala have the shape " + pprint.tprint[Map[_,_]])
}
```
{% end %}

Now it's possible to execute the script with no additional command line flags

```cli
$ scala-cli run Hello.scala
# Compiling project (Scala 2.13.10, JVM)
# Compiled project (Scala 2.13.10, JVM)
Maps in Scala have the shape Map[_, _]
```

Through directives, it's possible, among other things, to add java options or compiler flags, declare tests, change the compilation target and decide whether to package the application producing a fat jar or a script that downloads all the required dependencies at its first usage. For a complete reference, see [Directives](https://scala-cli.virtuslab.org/docs/reference/scala-command/directives).

### Updating dependencies
As some of you may have noticed, the `pprint` library version in the example it's not the newest one: at the time of writing, the most recent version is 0.8.0. Luckily we're not forced to _check it manually on Github or Maven Central_ since Scala CLI exposes the `dependency-update` command that will fetch the last version of each dependency and **print a command to update them all**.

```cli
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

```cli
$ scala-cli setup-ide Maps.scala
```

resulting in the generation of 2 files that both Metals and IntelliJ use to provide all their functionalities.

```tree
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

```tree
...
├── .scalafmt.conf
└── Maps.scala
```

and then running `scala-cli fmt Maps.scala`. The command can run even without the configuration file as it infers the version and dialect from the project. To save locally the default scalafmt configuration (to maybe use it with you IDE of choice), it's possible to use a flag: `scala-cli fmt Maps.scala --save-scalafmt-conf`.

**Now that we have a working IDE, we can begin modelling the problem and its solution.**

# Modelling a Sudoku Board

Since sudoku consists of 9 lines of 9 digits from 1 to 9, one of the ways to encode and store the information in a case class is wrapping a `Vector[Int]`. So in a newly created `Sudoku.scala` file, we'll define

{% codeBlock(title="Sudoku.scala") %}
```scala3
//> using scala "3.2.1"

final case class Sudoku private (data: Vector[Int])
```
{% end %}

We made the constructor private to avoid `Sudoku` getting instantiated outside its companion object, where we will soon create a "factory" method named `from`. 

Since we plan to read sudokus from the command line, it's reasonable to imagine a factory method that accepts a `String` and returns a `Sudoku` or a **data structure** that may contain **either** a `Sudoku` or a way to signal an error (like an error `String` to log in case of validation errors).

{% codeBlock(title="Sudoku.scala") %}
```scala3
//> using scala "3.2.1"

final case class Sudoku private (data: Vector[Int])

object Sudoku {

  def from(s: String): Either[String, Sudoku] = ???
}
```
{% end %}

To implement the method, we'll leverage some utility functions that [cats](https://typelevel.org/cats/) provide.

{% codeBlock(title="Sudoku.scala") %}
```scala3
//> using scala "3.2.1"
//> using lib "org.typelevel::cats-core::2.9.0"

import cats.syntax.all.*

final case class Sudoku private (data: Vector[Int])

object Sudoku {

  def from(s: String): Either[String, Sudoku] =
    s.replaceAll("\\.", "0")
      .asRight[String]
      .ensure("The sudoku string doesn't contain only digits")(
        _.forall(_.isDigit)
      )
      .map(_.toCharArray().map(_.asDigit).toVector)
      .ensure("The sudoku string is not exactly 81 characters long")(
        _.length === 81
      )
      .map(Sudoku.apply)
}
```
{% end %}

Let's examine the `from` function line by line:
- `s.replaceAll("\\.", "0")` replaces the `.`s with `0`s to signal the lack of a digit using a value that belongs to type `Int`. Replacing `.` is necessary since we'll use [this generator](https://qqwing.com/generate.html) with "Output format: One line".
- `.asRight[String]` is the first cats utility that we'll use. Defined as 
  
  ```scala 
  def asRight[B]: Either[B, A] = Right(a)
  ```

  it is an extension method over `a: A`. It wraps the value in a `Right` but requires a type argument `B` to widen the result declaration to `Either[B,A]`. This way, the result will not have type `Right[String]` but `Either[String, String]`, letting us use other utility functions defined over `Either[_,_]`.
- `.ensure("The sudoku string doesn't contain only digits")(_.forall(_.isDigit))` uses the extension method `ensure`, a guard function that filters either in the case is a `Right` and returns the content of the first parenthesis in case of errors. Its definition (where `eab` is the extended value) is
  ```scala
  def ensure(onFailure: => A)(condition: B => Boolean): Either[A, B] = eab match {
    case Left(_)  => eab
    case Right(b) => if (condition(b)) eab else Left(onFailure)
  }
  ```
  In this particular case, we use to check that all the characters in the string (`forall`) are digits (`isDigit`) otherwise, we return a `Left("The sudoku string doesn't contain only digits")` to signal the error, shortcircuiting all the following validations.
- `.map(_.toCharArray().map(_.asDigit).toVector)` Now that we're sure that every character is a digit, we first map over the `Either[String,String]` to transform its content (when it's a `Right`) and then we map every `Char` into an `Int` `map`ping over the array. (Note: we use `asDigit` and not `toDigit` as we want to interpret the literal value of the `Char` as a digit and not its internal representation)
- Using the same `ensure` function we check that the string has the correct length
- Finally, we map the `Either[String, Array[Int]]` into an `Either[String, Sudoku]` calling `Sudoku`'s constructor, that here in the companion object is accessible.

The main strength of the `from` function is that it won't let us create a `Sudoku` if the input **doesn't comply with a set of minimum requirements needed to fully and correctly describe a** `Sudoku`. This approach, sometimes called ["Parse, don't validate"](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/), might not seem a big deal. Still, it enables us to write functions and extension methods that use `Sudoku` as parameters and **are not required to perform any validation**. `Sudoku`s are now impossible to create without using a valid input: we made invalid `Sudoku`s impossible to represent. 

## Adding utility methods

Our `Sudoku` case class is pretty much useless without any function using it, so let's write a few methods that might help us solve the problem. Since each number in each cell is _row_, _column_ and _cell_ constrained, it makes sense to create methods to extract those pieces of information from the case class.

{% codeBlock(title="Sudoku.scala") %}
```scala3
//> using scala "3.2.1"
//> using lib "org.typelevel::cats-core::2.9.0"

import cats.syntax.all.*

final case class Sudoku private (data: Vector[Int]) {

  def get(x: Int)(y: Int): Int = data(y * 9 + x)

  def getRow(y: Int): Vector[Int] = data.slice(y * 9, (y + 1) * 9)

  def getColumn(x: Int): Vector[Int] = (0 until 9).toVector.map(get(x))

  def getCellOf(x: Int)(y: Int): Vector[Int] = {
    def span(n: Int): Vector[Int] = {
      val x: Int = (3 * (n / 3))
      Vector(x, x + 1, x + 2)
    }

    for {
      b <- span(y)
      a <- span(x)
    } yield get(a)(b)
  }
}

object Sudoku {

  def from(s: String): Either[String, Sudoku] = /* ... */
}
```
{% end %}

> We added these methods to the case class itself, but another option we could have chosen is to add this logic in an [extension](https://docs.scala-lang.org/scala3/book/ca-extension-methods.html). Creating an **extension** over the `Sudoku` datatype will let us call the methods defined in it **as if they were methods of the** `Sudoku` **class**.
> ```scala3
> object Sudoku {
> 
>   extension (s: Sudoku) {
>     def get(x: Int)(y: Int): Int = /* ... */
>     def getRow(y: Int): Vector[Int] = /* ... */
>     /* ... */
>   }
> }
> 
> sudoku.get(0)(0)
> ```
> Extending may be preferable since it **keeps data separated from the logic** that manipulates them (enforcing some [separation of concerns](https://en.wikipedia.org/wiki/Separation_of_concerns)), and since it's possible over datatypes **not part of your codebase**, like standard library types or datatypes coming from a library. This approach shines when the extension depends on a [typeclass](https://docs.scala-lang.org/scala3/book/ca-type-classes.html), since extending the typeclass for a new type `T` you get a **custom syntax over** `T` **for free**.
>
> On the other hand, **defining new methods in the class** (or in a trait) is easier if you intend to add **new operations** to that specific type (or trait). Pros and cons of the _typeclass_ vs _inheritance_ approach to the [Wadler's expression problem](https://en.wikipedia.org/wiki/Expression_problem) will be discussed in a future article.

## Testing

Now that we have some APIs over `Sudoku`, it makes sense to test them out before trying to solve the problem further. [Scala-cli supports testing](https://scala-cli.virtuslab.org/docs/commands/test) out of the box and detects test files in several ways. The easiest one to leverage is using the `.test.scala` extension, ideal when you have a single source file like `foo.scala` and its testing companion `foo.test.scala`.

A more structured way to setup a project is to separate the source files from the test ones, maybe in different folder trees, using a slightly more complex project structure that [scala-cli supports](https://scala-cli.virtuslab.org/docs/reference/root-dir).

```tree
.
├── project.scala
├── src
│  └── Sudoku.scala
└── test
   └── SudokuSpec.scala
```

This structure autodetects *test classes* using the files' relative path: if the file's path contains the string `"test"`, it will be treated as a test class. To test the application, we will declare **munit** in the `project.scala` file now containing all the directives previously in `Sudoku.scala`.

{% codeBlock(title="project.scala") %}
```scala3
//> using scala "3.2.1"
//> using lib "org.typelevel::cats-core::2.9.0"
//> using lib "com.monovore::decline::2.3.1"
//> using lib "org.scalameta::munit::0.7.29"
```
{% end %}

{% codeBlock(title="src/Sudoku.scala") %}
```scala3
import cats.syntax.all.*

final case class Sudoku private (data: Vector[Int]) { /* ... */ }

object Sudoku { /* ... */ }
```
{% end %}

{% codeBlock(title="test/SudokuSpec.scala") %}
```scala3
import munit.*
import cats.syntax.all.*

class SudokuSpec extends FunSuite {

  // format: off
  val maybeSudoku = Sudoku.from(
    "435269781" +
    "682571493" +
    "197834562" +
    "826195347" +
    "374682915" +
    "951743628" +
    "519326874" +
    "248957136" +
    "763418259"
  )
  // format: on

  val sudokuF: FunFixture[Sudoku] = FunFixture(_ => maybeSudoku.fold(failSuite(_), identity), _ => ())

  /* Tests here! */

}
```
{% end %}

To easily have a `Sudoku` instance available for easy unit testing we used `FunFixture`. `FunFixture` is one of the [available fixtures](https://scalameta.org/munit/docs/fixtures.html) that munit provides to **acquire and release resources** and to share them between single tests or whole suites. We coded `sudokuF` to fail the entire suite if the `Sudoku` is trying to instantiate is invalid and to give it to the fixture user otherwise.

Now we can define tests using the munit's simple syntax:

```scala3
sudokuF.test("Sudoku.get(x,y) should extract the number at (x,y) (0 based, from top left)") { sudoku =>
  assertEquals(sudoku.get(0)(0), 4)
  assertEquals(sudoku.get(1)(0), 3)
  assertEquals(sudoku.get(2)(7), 8)
}

sudokuF.test("Sudoku.getRow(n) should extract nth row from top") { sudoku =>
  assertEquals(sudoku.getRow(0), Vector(4, 3, 5, 2, 6, 9, 7, 8, 1))
  assertEquals(sudoku.getRow(6), Vector(5, 1, 9, 3, 2, 6, 8, 7, 4))
}

sudokuF.test("Sudoku.getColumn(n) should extract nth column from left") { sudoku =>
  assertEquals(sudoku.getColumn(0), Vector(4, 6, 1, 8, 3, 9, 5, 2, 7))
  assertEquals(sudoku.getColumn(6), Vector(7, 4, 5, 3, 9, 6, 8, 1, 2))
}

sudokuF.test("Sudoku.getCellOf(n) should extract the correct cell") { sudoku =>
  assert(sudoku.getCellOf(1)(1).forall((1 to 9).contains))
  assert(sudoku.getCellOf(7)(3).forall((1 to 9).contains))
}
```

and test our implementation using the `test` command of **scala-cli**:

```cli
$ scala-cli test .
SudokuSpec:
  + Sudoku.get(x,y) should extract the number at (x,y) (0 based, from top left) 0.037s
  + Sudoku.getRow(n) should extract nth row from top 0.002s
  + Sudoku.getColumn(n) should extract nth column from left 0.001s
  + Sudoku.getCellOf(n) should extract the correct cell 0.003s
```

# Recursive immutable solution

To solve the sudoku we will use a recursive algorithm:

1. Given a sudoku, we will **search for a zero** in it
2. If there's at least one, we will **find all the numbers that fit in that position** according to the constraints
3. If there's at least a number that fits, we will **generate a new sudoku replacing the zero** with that number
4. We will apply the 3 previous steps to **every sudoku** that we created so far **until there are no more zeros**
5. We will end up with a **list of solved sudokus** that we will return to the user

// Add set, fitsInPlace, getZero and asPrettyString

# TODO

// Solve using both the `flatMap` solution, both the recursive one

```diff
- def solve: Either[String, Sudoku] = Sudoku.slowSolve(this)
+ def solve: Either[String, Sudoku] = Sudoku.fastSolve(this)
```

// Add `--all` flag to print all the solutions

// Use native

// OFC That's not a comprehensive guide of all the features that scala-cli has.