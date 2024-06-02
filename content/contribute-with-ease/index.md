+++
title = "Contributing to OSS is easier than you think"
date = 2024-05-01
slug = "contributing-is-easier-than-you-think"
language="en"
draft = true
[extra]
description = "Simple and easy guide to contribute to OSS projects with a focus on Typelevel's Scala projects. You're just minutes away from your first pull request!"
+++

When I began working with Scala, I was a developer with just two years of experience in ~~Java~~ Spring Boot. **I could never imagine contributing to Open Source Software projects**, mainly because my general software development knowledge and Scala expertise were scarce.

Once I filled those gaps, I realised that there was some **required knowledge that I was still lacking**. It was vaguely related to the fact that all my present and past employers (at that time) preferred to keep their source code well hidden in private repositories hosted on VPN-guarded on-premise data center machines.

What I was lacking was the ability to use any **public collaborative version control platform** (that's how Wikipedia defines Github and Gitlab; blame them if the definition is terse).

> {{ info() }} This post aims to be a **simple and easy guide** to help newcomers to collaborate to the OSS project they use and love. I will specifically show how to open a simple Pull Request on [feral] a Typelevel's framework for writing serverless functions in [Scala.js] with [Cats Effect]. The only pre-requirement is having some confidence with [git] and its usage.

# Configuring `git` with you GitHub account

As [feral] sits on Github, we'll need a GitHub account, and we will create it via the [signup page](https://github.com/signup). Once you've created it and logged in, you should set up git to authenticate with the GitHub servers using the newly created account as an identity.

> There are various methods to set up git to authenticate with GitHub and this is a topic developers usually have strong opinions about. 

For everybody's pleasure, and to maximise the entropy, I'll pick the most opinionated one, `gh`. Still the [getting started with git](https://docs.github.com/en/get-started/getting-started-with-git/set-up-git) guide by GitHub covers most of the alternatives like [ssh](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/about-ssh), direct [https](https://docs.github.com/en/get-started/getting-started-with-git/caching-your-github-credentials-in-git) authentication with credentials and also goes in detail in to more advance topics like [signing your commits](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification) (something that I particularly like).

The [command line tool `gh`]((https://cli.github.com/)) is a multi-purpose tool with multiple capabilities, but we will use it just to make git authenticate with Github using HTTPS. Installing it is as simple as following the [installation instructions](https://github.com/cli/cli#installation) (by definition) and to login it's enough to prompt `gh auth login` and follow the on screen instructions:

```cli
$ gh auth login
? What account do you want to log into? GitHub.com
? What is your preferred protocol for Git operations on this host? HTTPS
? Authenticate Git with your GitHub credentials? Yes
? How would you like to authenticate GitHub CLI? Login with a web browser

! First copy your one-time code: 0707-596C
Press Enter to open github.com in your browser...
✓ Authentication complete.
✓ Configured git protocol
✓ Logged in as <your-username>
```

Now the best thing to ensure everything's okay is to [create a new repository on Github](https://github.com/new) and push your first commit. Assuming your newly create repository's name is `foobar` you can clone it with `gh` using the command `gh repo clone <your-username>/foobar`.

```cli
$ gh repo clone <your-username>/foobar
Cloning into 'foobar'...
warning: You appear to have cloned an empty repository.
```

We should really take care of the emptyness warning creating a commit: `cd` into the folder, create a new file (like a `README.md`), add it to the tracked files with `git add` and create your first commit.

```cli
$ cd foobar
$ touch README.md
$ git add .
$ git commit -m "Initial commit"
[main (root-commit) 1e11b44] Initial commit
 1 file changed, 0 insertions(+), 0 deletions(-)
 create mode 100644 README.md
```

If everything is configured properly `git push` should work flawlessly and you should be able to see your first commit on the Github's repository page.

```cli
$ git push
Enumerating objects: 3, done.
Counting objects: 100% (3/3), done.
Writing objects: 100% (3/3), 214 bytes | 214.00 KiB/s, done.
Total 3 (delta 0), reused 0 (delta 0), pack-reused 0
To https://github.com/feralguy/foobar.git
 * [new branch]      main -> main
$ gh browse
Opening github.com/<your-username>/foobar in your browser.
```

Congratulations you're now able to commmit on GitHub, and you've completed the first step required to contribute :tada:

> {{ info() }} In case of any issue refer to the [getting started with git](https://docs.github.com/en/get-started/getting-started-with-git/set-up-git) guide or ask for help in the comments :wink:

# Using GitHub to interact with other developers

One of my strongest beliefs when I began contributing was that **contributing consisted solely on writing proper code**, submitting it to the corresponding repository and waiting for a review by some grownup developer.

What I realised after I spent some time contibuting and maintaing public code is that writing code and submitting pull requests is just **one of the many ways a user can help improving a library**, and what I believe is that there surely are **more important** (and possibly simpler) actions that any library user can perform to help everyone (maintainer and users) **evolving both the library and its user experience**.

Since the reasons that usually bring a developer to search for a library's repo page, in my opinion, are mainly these:
- Check which is the **last version** of that lib and copy its import string (like `"dev.foo" %% "foo-lib" %% "1.0.0"`)
- Read its documentation **to learn how to use it**
- Read its documentation to understand if the **weird behaviour** they're getting **is a bug**
- **Search within the issues** whether someone else had the very same experience they're having
- **Open a bug** after if the previous three resulted in nothing

every user can contribute simply making **these users' interactions with the library and its documentation more accessible, more enjoyable and simply easier**.

> **Contributing to the library documentation enhances the overall usability and accessibility of the project, and it's also the simplest action with the highest effort-to-impact ratio that a user can take.**

A non trivial and possibly funnier way to help other users is to **write blog posts on how to use the library** or what problem you solved at work using it. Open Source libraries documentations usually have sections that link to blog post of happy users, be sure to signal to the maintainers that you wrote an enthusiastic post that it's worth getting added there and you'll possibly see your blog ranking up in SEO too.

> **Spotting and reporting bugs** is also incredibly important for keeping an open-source library in top shape. Don't be yet another developer that expects libraries to just work and that complains when they don't. It's not useful to anyone, yourself included, and denigrates the free and voluntary work that open source contributors did.

Before reporting a bug opening a new issue just make sure to check the existing ones first to avoid any repeats and be sure to **add all the context details as possible**. In these cases adding an [**MRE**](https://en.wikipedia.org/wiki/Minimal_reproducible_example) is extremely useful for mantainers and contributors, as they can use your example as a unit test to turn green while fixing the bug.

A really appreciated kind of MREs in the Scala OSS ecosystem are the ones using [scala-cli], as in a single file you can define the specific combination of JVM, library and language versions that will cause the specific piece of code to fail the expectations. Imagine reading a bug report that contains this snippet:

```scala
//> using scala 3.4.2
//> using jvm 8
//> using dep dev.foo::foo-lib::1.0.0

@main def foo = assert(foo.method("specific argument value"))
```

while reading one saying just that "Sometimes `foo.method` returns a false". With the latter, most of the investigation is supposed to be done by the people attempting to solve the bug, possibly spending a lot of time trying to guess with (scala, jvm, lib) versions combination produces the faulty behaviour. This way, new problems get fixed faster, and the software stays solid and reliable for everyone.

> SHALL I SHOW HOW TO OPEN AN ISSUE?

### There's not just Github

- If there's a Discord, or a chat channel you can use it

# Contributing to the library

---

- Contribute to code
    - Understand the thing
    - Fork the repo
    - Enable actions in the fork
    - clone locally
    - run tests, setup the ide, compile everthing, ensure to have autocompletions
    - do the fix
    - add a test
    - run prePR
    - watch the CI succeed
        - the first time you might need to be approved
    - open the PR
    - wait for a review


[feral]: https://github.com/typelevel/feral
[Scala.js]: https://www.scala-js.org/
[scala-cli]: https://scala-cli.virtuslab.org/
[Cats Effect]: https://typelevel.org/cats-effect/
[git]: https://git-scm.com/
