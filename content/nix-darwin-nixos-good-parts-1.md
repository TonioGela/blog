+++
title = "Nix, Darwin, NixOS: the good parts - part 1"
date = 2026-09-30
slug = "nix-darwin-nixos-good-parts-1"
language="en"
draft = true
[extra]
description = "A tale of a slow descent into `Nix` and later `NixOs` starting from a Darwin machine and `avoiding flakes` w/o any means of generality whatsoever"
+++

There's no surprise in me asserting that I've been away from this blog since two years ago and that the last time I wrote something was to state that I was about to put myself in the niche of sw developers with a blog but not using what has now been renamed to X.

My life since then has been good, fun and satisfying in many different ways, and the tldr is that me and my partner had a daughter, that she's the best thing that has happened to this planet since forever, that I love spending a lot of time with her and that's basically what has happened daily since then. There has been other changes too, but let's be frank, you're here reading this blog post because you're interested in just one of these:

{% quote() %}I now use NixOS btw{% end %}

Most of the people that knows me also knows that for most of my career I've been committed mostly into using [Scala], advocating for it, loving it and despite this is pretty much unchanged nowadays (I do still use it at `$WORK`), I've definitely stopped contributing to it and to the [Typelevel] stack that I'm still so fond of. The reason for such a change is mostly [Nix].

Darwin not ideal, but at least that's what carried me into nix, then Nixos.

Avoided Flakes, avoided Nix Darwin, just hm and npins.

Tutorial, guide, storytelling, idk:
- Home manager on Darwin
- From channels to npins
- Module system with the auto importer (config, import, options)
- Why doesn't nix-build work? Trip into cat-ting scripts and then nh.
- Adding a nixos machine (disko, hardware, iso creation, etc)
- Creating a builder also for nixos
- Nixos modules and home-manager modules

{% codeBlock(title="foo.nix") %}
```nix
{
  config,
  pkgs,
  ...
}: {
  home.packages = [ pkgs.zola ];
}
```
{% end %}

[Scala]: https://scala-lang.org
[Typelevel]: https://typelevel.org
[Nix]: https://nix.dev
