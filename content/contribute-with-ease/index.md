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

One of my strongest beliefs when I began contributing was that **contributing consisted solely on writing proper code**, submitting it to the corresponding repository and waiting for a review by some grownup and more skilled developer that I was.

What I realised after I spent some time contibuting and maintaing public code is that writing code and submitting pull requests is just **one of the many ways a user can help improving a library**, and what I believe is that there surely are **more important** (and possibly simpler) actions that any library user can perform to help everyone (maintainer and users) **evolving both the library and its user experience**.


- Issues, labels, search a lot
- If there's a Discord, or a chat channel you can use it
- Read CONTRIBUTING, use templates
- Info section on the upper right part
- Use scala-cli for MRE

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
[Cats Effect]: https://typelevel.org/cats-effect/
[git]: https://git-scm.com/
