+++
title = "Nix, Darwin, NixOS: the good parts - part 1"
date = 2024-11-16
slug = "nix-fapp-part1"
language="en"
draft = true
[extra]
description = "Lorem Ipsum"
+++

I'm aware that this blog audience is pretty much non existent and the few of you reading this lines might be here just to read about Scala 
stuff but given that this blog is one of the few ways to get in touch with me I felt like adding this tiny update here.

{% codeBlock(title="foo.nix") %}
```nix
{
  config,
  pkgs,
  ...
} : {
  home.packages = [ pkgs.zola ];
}
```
{% end %}


I deleted my twitter (or whatever it's called now) account as scrolling my homepage lately felt like seeking comfort in a den of haters: useless for boredom, terrible for the mood. From now on assume that anyone using the `@toniogela` handle might be someone else.

If you want to keep in touch try using Mastodon, Discord or the github-discussions-powered comments here :point_down:.
