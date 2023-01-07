+++
title = "Deploy http4s on your domain with fly.io"
date = 2023-01-07
slug = "http4s-on-fly-io"
language="en"
draft = true
[extra]
description = "How to write and deploy a server with [http4s](https://http4s.org/) and `scala-cli` and deploying it on your **own domain** with [fly.io](https://fly.io/) in 10 minutes."
+++

> **DISCLAIMER**: This article assumes some familiarity with the [Typelevel](https://typelevel.org/)'s tech stack, [http4s] in particular.
>
> There's plenty of **good resources** to read online to get started with, some of them being [Scala with Cats](https://underscore.io/books/scala-with-cats/), [Essential Effects](https://essentialeffects.dev/) and the [Cats Effect](https://typelevel.org/cats-effect/) documentation.
> The **best and most comprehensive resource** you'll find to develop a microservice using this stack is [Practical FP in Scala](https://leanpub.com/pfp-scala), that I strongly suggest reading.
>
> If you need **help** with any of these resources feel free to contact me or better ask questions in the [Typelevel's Discord](https://discord.com/invite/XF3CXcMzqD). You'll find **an amazing and kind community** of really **talented** people that will be glad to answer to your questions :smile:

If you already own a domain, deploying a toy server or any personal *server-shaped* project on it should not be a complex operation. Using [fly.io], [scala-cli], [http4s] and [just] can help automatise the process and reduce the friction up to the point it might even be funny.

### Requirements
Before starting, we'll need to set up a couple of things. Here's the list:

- Having/buying a **custom domain** and having access to its **DNS settings page**: I'm using [Google Domains] since the domains are cheap (most of them cost 12$ per year), but it lacks support for ALIAS records.
- Sign up on [fly.io], [install]((https://fly.io/docs/hands-on/install-flyctl/)) its command line tool **`flyctl`** and log in using `flyctl auth login`
- **Of course**, a local installation of [scala-cli] (Here's me talking about it on the [Rock The JVM blog])
- Optionally the command line tool [just] that I <strike>recently</strike> reviewed [here](https://toniogela.dev/just/)

## Writing the application
Writing a hello-world-spitting server with http4s using [its giter8 template](https://github.com/http4s/http4s.g8) and sbt it's a trivial task.

Instead, we'll write it manually, using scala-cli and adding a slightly less trivial business logic. To begin, we'll create a file containing a few scala-cli directives to declare the dependencies and the scala version:

{% codeBlock(title="Server.scala") %}
```scala
//> using scala "3.2.1"
//> using resourceDir "."
//> using packaging.packageType "assembly"
//> using lib "org.http4s::http4s-ember-server::0.23.17"
//> using lib "org.http4s::http4s-dsl::0.23.17"
//> using lib "com.monovore::decline-effect::2.4.1"
//> using lib "ch.qos.logback:logback-classic:1.4.5"
```
{% end %}

env var e secrets


# TODO

- Develop server
  - Use logback
  - `scala-cli package helloWorld.scala --docker --docker-image-repository hello-world-scala --docker-image-tag 0.1.0 --docker-from eclipse-temurin:11.0.17_8-jre-alpine`

- fly.io
  - Talk about the free tier
  - `flyctl create`
  - use https://fly.io/docs/reference/configuration
  - Alter fly.toml
  - `flyctl deploy --local-only`
  - `flyctl ips allocate-v4`
  
- Certificates
  - `flyctl certs add foo.toniogela.dev`
  - DNS configuration

- Write a `Justfile`
  - `flyctl secrets set GREET="Hey"`
  - `flyctl deploy --local-only`

[fly.io]: https://fly.io/
[scala-cli]: https://scala-cli.virtuslab.org/
[http4s]: https://http4s.org/
[Google Domains]: https://domains.google/
[just]: https://github.com/casey/just
[Rock The JVM blog]: https://blog.rockthejvm.com/