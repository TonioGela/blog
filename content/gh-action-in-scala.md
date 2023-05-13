+++
title = "Writing a GitHub Action with Scala.js"
date = 2023-05-13
slug = "gh-action-in-scala"
language="en"
draft = true
[extra]
description = "How to leverage [`scala-cli`](https://github.com/VirtusLab/scala-cli) and the [Typelevel Toolkit](https://github.com/typelevel/toolkit) to super charge your GitHub CI."
+++

Some months ago I discussed with a DevOps colleague the need for a custom GitHub Action at `$work`. 

- GH fornisce docker o js
- l'alternativa era usare un megascriptone in bash poco mantenibile
- nessuno voleva scrivere roba in js
- scala puo sputare js
- sfruttiamo lo stack tl perche' e' gia tutto ported a js
- tl toolkit comprende una serie di librerie comode per lo scopo
- scala-cli semplifica tutto
- si puo' testare l'azione stessa nella sua ci