+++
title = "Deploy http4s on your domain with fly.io"
date = 2023-01-06
slug = "http4s-on-fly-io"
language="en"
draft = true
[extra]
description = "How to write and deploy a server with [http4s](https://http4s.org/) and `scala-cli` and deploying it on your **own domain** with [fly.io](https://fly.io/) in 10 minutes."
+++

- Buy a domain
- Sign up on fly.io
  - Talk about the free tier
  - `flyctl auth login`
  - `flyctl create`
  - use https://fly.io/docs/reference/configuration
- Develop server
- Alter fly.toml
- Use logback
- `scala-cli package helloWorld.scala --docker --docker-image-repository hello-world-scala --docker-image-tag 0.1.0 --docker-from eclipse-temurin:11.0.17_8-jre-alpine`
- Write a `Justfile`
- `flyctl secrets set GREET="Hey"`
- `flyctl deploy --local-only`
- `flyctl ips allocate-v4`
- `flyctl certs add foo.toniogela.dev`