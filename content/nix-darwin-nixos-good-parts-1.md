+++
title = "Nix, Darwin, NixOS: the good parts - part 1"
date = 2024-11-16
slug = "nix-darwin-nixos-good-parts-1"
language="en"
draft = true
[extra]
description = "Lorem Ipsum"
+++

Last two years, fired, Arianna, no more oss, but nix.

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
