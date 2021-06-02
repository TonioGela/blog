+++
title = "Just use just"
date = 2021-06-02
slug="just"
draft=true
language="en"
+++

OMG, the blog is live! :scream: And this is the first article! :scream:

This first article will be about [Just] a command-line tool I recently discovered that immediately became essential in many work projects.

Let's suppose you've just deployed your application via `scp` (_sigh!_) on one of the work machines. Maybe your application was already built using tools like [Decline], so it's already capable of parsing command-line options and flags and printing a complete help like:

```
$ foo --help
Usage:
    foo schedule
    foo encrypt
    foo decrypt

foo tool, it can encrypt and decrypt files and schedule operations

Options and flags:
    --help
        Display this help text.

Subcommands:
    schedule
        schedules encryptions/decriptions
    encrypt
        encrypts files
    decrypt
        decrypts files
```

But let's add a **slow-changing configuration** to the scenario, which changes so often that it doesn't justify a refactor to add a library like [Ciris] to your code. Maybe there are some non-power users that need to change that configuration once a week or month _because of reasons_.

What's missing? Maybe there's a local MySql that needs to be queried for maintenance operations, or perhaps a remote database/storage/service/whatever that requires another command-line tool to be interacted with.

This is one of the times in which unmaintained, undocumented, faulty crap like **maintenance_script.sh** or **fix_for_prod.sh** begins to spread around. In no time, the situation will look similar to

```bash
/home/applicative_account/perform_operation.sh
/home/colleague1/perform_operation_copy.sh
/home/colleague1/old_version/perform_operation_as_root.sh
/home/sre_guy/this_should_fix_everything.sh
/home/random_data_scientist/do_not_run.sh #(ofc it was chmod +x)
```

90% of them will have the shebang `#!/bin/bash` while the 10% `#!/bin/sh`. Some of them will have `zsh` commands because there are people around that uses `zsh` (like me) that forgets that it doesn't share 100% of the syntax with `bash` (not like me, I swear).

Most of them will contain almost the same commands like 

```
mysql prod_db < maintenance.sql > maintenance_output.dump
``` 

or templatized commands like 

```
"/foo-${VERSION}/bin/foo"
```

that depend on environment variables defined int the `.profile` of a deleted user.

The last time you used [ShellCheck] to check the scripts, the linter exploded and somewhere in the world [Stephen Bourne] suddenly began crying without apparent reason.

## Just to the rescue

As its Github [README] states Just _is handy way to save and run project-specific commands_ called **recipes**, stored in a file called `justfile` with a syntax inspired by **Make**.

Here's a tiny example:
```make
build:
    cc *.c -o main

# test everything
test-all: build
    ./test --all

# run a specific test
test TEST: build
    ./test --test {{TEST}}
```

Just searches for a `justfile` in the current directory written in its particular syntax, so let's begin creating one with an hello world recipe and let's try to run it:

```make
hello-world:
    echo "Hello World!"
```
```
$ just hello-world
echo "Hello World!"
Hello World!
```

As you can see just **shows the command** that is about to run before running it, while we can't say the same for global or used defined `alias`es in various shells (unless using something like `set -x` for bash). If you want to suppress this behaviour you can put a `@` in front of the command to hide.

```make
hello-world:
    @echo "Hello World!"
```
```
$ just hello-world
Hello World!
```

Let's try to create a second recipe with an argument.

```make
hello-world:
    @echo "Hello World!"

salute guy:
    @echo "Hello {{guy}}!"
```
```
$ just salute
error: Recipe `salute` got 0 arguments but takes 1
usage:
    just salute guy

$ just salute Tonio
Hello Tonio!

$ just --dry-run salute Tonio
echo "Hello Tonio"
```

The recipe cannot obviously run without an argument, since that argument is referred in the body of the recipe using just syntax `{{ argument_or_variable_name }}`. If you want to "debug" the recipe that will run with the provided arguments you can use the `--dry-run` command-line flag. This can come handy if a command is long and complex and you have, for example, to schedule it in your crontab file. Just copy it from there.

Arguments are really powerful, since they can have **default values** and can be **variadic** (both in the form `zero or more` or `one or more`):

```make
hello target="World":
    @echo "Hello {{target}}!"

hello-all +targets="Tim": # One or more, with default
    @echo "Hello to everyone: {{targets}}!"

hello-any *targets: # Zero or more
    @echo "Hello {{targets}}!"
```
```
$ just hello
Hello World!

$ just hello-all
Hello to everyone: Tim!

$ just hello-all "Tim" "Martha" "Lisa"
Hello to everyone: Tim Martha Lisa!

$ just hello-any
Hello !

$ just hello-any "Bob" "Lucas"
Hello Bob Lucas!
```

We know enough syntax, let's try to build a meaningful example for our **messed-up work machine** and let's try new features **just** if we need them (no pun intended :smile:).

Di che é hipster ed é fatto in rust

Cita il plugin di VsCode

Passa articolo in Grammarly

variabili e templating
set shell cosí tutti usano lo stesso interprete
ricette che dipendono le une dalle altre e esempio vero con tail
commenti come documentazione e list unsorted con default nascosto
shell completion

conditionals, loops `for i in variad argument?`
altri interpreti
variabili ambiente esportate
choose
chiamabile da altro percorso


[Just]: https://github.com/casey/just
[README]: https://github.com/casey/just#just
[Decline]: https://ben.kirw.in/decline/
[Ciris]: https://cir.is/
[ShellCheck]: https://www.shellcheck.net/
[Stephen Bourne]: https://en.wikipedia.org/wiki/Stephen_R._Bourne