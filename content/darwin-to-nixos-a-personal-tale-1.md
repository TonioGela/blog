+++
title = "Darwin to NixOS: a personal tale - part 1"
date = 2026-09-30
slug = "darwin-to-nixos-a-personal-tale-1"
language="en"
draft = true
[extra]
description = "A tale of a slow descent into `Nix` and later `NixOs` starting from a Darwin machine while avoiding flakes w/o any means of generality whatsoever."
+++

{% quote() %}If you're not interested in my short personal update feel free to skip to [A humble beginning](#a-humble-beginning) {% end %}

As it stands out looking at the publication date of the last post on this blog, I've been away from it since two years ago and the last time I just wrote a few lines to state that I was about to put myself in the niche of sw developers not using what has now been renamed to X.

My life since then has been good, fun and satisfying in many different ways, and the tldr is that me and my partner had a daughter, that she's the best thing that has happened to this planet since forever, that I love spending a lot of time with her and that's basically what has happened daily since then. There has been other changes too, but let's be frank, you're here reading this blog post because you're interested in just one of these:

{% quote() %}I now use NixOS btw{% end %}

Most of the people that knows me also knows that for most of my career I've been committed mostly into using [Scala], advocating for it, loving it and despite this is pretty much unchanged nowadays (I do still use it at `$WORK`), I've definitely stopped contributing to it and to the [Typelevel] stack that I'm still so fond of. The reason for such a change (if you exclude sleep deprivation, lack of time, aliens and similar) is mostly that my attention in the last two years has been dragged towards [Nix].

My personal story with nix, or at least its beginning, is possibly an uncommon one: I never had the chance (or rather the time) to try it by myself but changing job made me land in a company that uses it extensively. When joining I asked for a Darwin machine, as that was the sole os/hardware that I had ever used for sw development at that time (if you exclude a tiny parenthesis with Arch), but in the following 18 months I ended up nixifying (or rather home-managerifying) every machine I own, from Zimaboards, to OVH boxes, including a Framework Laptop bought just to install NixOS on it and making it my main machine.

I'm writing about my experience with Nix because it's mostly a story about me continuosly getting marvelled (#TODO check work) by nix, by home-manager, by nixos as a personal os, by nixos a server os, by a community of talented people, by a local community of nixos enthusiasts that I love hanging out with and many other things.

As such, expect this series of posts to be a story, a tutorial and self-documentation material packed with strong personal opinions about technical topics.

{% quote() %}**DISCLAIMER #1** To the avid flakes user: I never found myself in the need to use flakes so you won't find any usage of them here.{% end %}

{% quote() %}**DISCLAIMER #2** I haven't use any AI tool or LLM to write this or any of the other posts contents, but I've used it and still I use it to debug what's happening on my machine in case of bugs, simply feeding it my system journal and asking it for explanations. The consequent fixes to ny nixos configuration, despite being handwritten, might then be the result of an LLM suggestion, and some of those might end up in some of this posts.{% end %}

# A humble beginning

Aura farming

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
