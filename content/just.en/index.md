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

[Just]: https://github.com/casey/just
[Decline]: https://ben.kirw.in/decline/
[Ciris]: https://cir.is/
[ShellCheck]: https://www.shellcheck.net/
[Stephen Bourne]: https://en.wikipedia.org/wiki/Stephen_R._Bourne