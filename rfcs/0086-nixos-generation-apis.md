---
feature: nixos-generation-apis
start-date: 2021-02-09
author: Michael Lohmann <mial.lohmann@gmail.com>
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: https://github.com/NixOS/nixpkgs/pull/105910, https://github.com/NixOS/nixpkgs/issues/24374
---

# Summary
[summary]: #summary

On a typical system there are lots of generations. However rolling back to a
specific one without rebooting is hard and it is even more difficult to get an
overview of the available generations. This RFC proposes adding
`nixos-rebuild --generation <number>` for rolling back to a specific generation
and `nixos-rebuild list-generations` for showing details about the available
generations.

# Motivation
[motivation]: #motivation

The discoverability and usability of generations is limited on a running system.

I had an issue, where I didn't notice a package breaking ~10 generations ago and
while fixing it, I had to go back and forth multiple times.
Since I didn't know about
```sh
sudo nix-env --switch-generation 12345 -p /nix/var/nix/profiles/system
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
```
I repeated the rollback `n` times or rebooted and selected the respective
generation in the bootloader.

This RFC proposes to add
```sh
sudo nixos-rebuild switch --generation 12345
```

When doing this, it would be of great help for usage, if there was a way to show
some some detail about the available generations, as is shown in the bootloader
menu.

# Detailed design
[design]: #detailed-design

## --generation
Is basically a wrapper around the aforementioned `nix-env` command
and the implementation is very much aligned with implementation of the `--rollback`
flag.

## list-generations
Extract the relevant information about the generation from the
`$profile-<generation>-link` directories and display it in a comprehensive way.
This is similar to the creation of the
[bootloader entries](https://github.com/NixOS/nixpkgs/blob/c14f14eeaf919c914e4dec2ce485a5bdc8dd4fec/nixos/modules/system/boot/loader/generations-dir/generations-dir-builder.sh#L50)
but adds information like the configuration revision.

Proposed information for each entry:

- generation number
- build date: `date --date="@$(stat "$generation_dir" --format=%W)" "+%a %F %T"`
- NixOS version: `cat "$generation_dir/nixos-version" 2> /dev/null || echo "Unknown"`
- kernel version: `ls "$(dirname "$(realpath "$generation_dir/kernel")")"/lib/modules`
- configuration revision: `$generation_dir/sw/bin/nixos-version --configurationRevision 2> /dev/null`

For human readability, piping it through `column` is proposed.
Since the list of generations is potentially long, the output could be piped
through a pager (`less`).

## nixos-version
Since there is no current concise way to get the configuration revision for
`nixos-rebuild list-generation`, implementing `nixos-version --configurationRevision`
is proposed. Because the old implementation ignored unknown flags and echoed the
default output, they have to be checked for equality in the list of generations.


# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

## --generation
Switching to a specific generation:
```
# nixos-rebuild switch --generation 121
```
The other subcommands like `test`/`boot`/`build` are also working:
```
# nixos-rebuild test --generation 122
```

Other profiles are supported:
```
# nixos-rebuild switch --generation 1 --profile-name test
# nixos-rebuild switch --generation 2 -p test
```

## list-generations
```
$ nixos-rebuild list-generations
Generation  Build-date               NixOS version               Kernel   Configuration Revision
121         Sat 2021-02-05 12:25:55  21.03.20210206.9bd6a6c      5.9.9    2199dd2822638f7dce2a9895930c51abd1723234
122         Sat 2021-02-06 23:19:24  21.03.20210206.e6a8458      5.9.9    dirty
123         Sat 2021-02-06 23:20:21  21.03.20210206.e6a8458      5.9.9    5e3848ececf21a1ee6b2ac4944bc5db2c02dd281  (current)
```

Other profiles are supported:
```
$ nixos-rebuild list-generations -p test
Generation  Build-date               NixOS version           Kernel   Configuration Revision
1           Sat 2021-02-05 12:25:55  21.03.20210206.9bd6a6c  5.9.9    2199dd2822638f7dce2a9895930c51abd1723234
2           Sat 2021-02-06 23:19:24  21.03.20210206.e6a8458  5.9.9    dirty  (current)
3           Sat 2021-02-06 23:20:21  21.03.20210206.e6a8458  5.9.9    5e3848ececf21a1ee6b2ac4944bc5db2c02dd281
```

# Drawbacks
[drawbacks]: #drawbacks

## list-generations

- Displaying the `list-generations` in `column` decreases machine-readability (different amount of white-spaces).
Since the output is primarily intended for humans, this should not be a problem.
An alternative would be, to follow the `git` model and have `--porcelain` version,
which is machine readable and guarantees a stable output format.
- If the configuration revision was a hash of the flake-repository, truncating
it would make sense. But it could just as well be plain text, where this approach
would fail. There would be a lot of logic involved for distinguishing between
hashes and text and conditional truncation.
- The name `nixos-rebuild` isn't strictly fitting to the `list-generations` parameter
but a more general `nixos` command as proposed in
[100578](https://github.com/NixOS/nixpkgs/pull/100578) and
[54188](https://github.com/NixOS/nixpkgs/issues/54188).
Though @edolstra [said it would be okay for now](https://github.com/NixOS/nixpkgs/issues/105910#issuecomment-754036275).


# Alternatives
[alternatives]: #alternatives

## list-generations
It would be possible to run `sudo nix-env -p /nix/var/nix/profiles/system --list-generations`,
but that only prints the generation number and the build date, so a lot of
invaluable information about the generations is missing. It requires a lot
of knowledge about `nix-env`, profiles and the location/default profile for NixOS
and (less important) privileged access.

Putting the "(current)" tag into it's own column would make differentiating it
from the configuration revision easier. On the other hand it could lead to a
less readable output (because of separation) like
```
Generation  Build-date               NixOS version           Kernel   Configuration Revision
1           Sat 2021-02-05 12:25:55  21.03.20210206.9bd6a6c  5.9.9    2199dd2822638f7dce2a9895930c51abd1723234
2           Sat 2021-02-06 23:10:44  21.03.20210206.e6a8458  5.9.9
3           Sat 2021-02-06 23:19:24  21.03.20210206.e6a8458  5.9.9
4           Sat 2021-02-06 23:20:21  21.03.20210206.e6a8458  5.9.9                                              (current)
5           Sat 2021-02-06 23:29:12  21.03.20210206.e6a8458  5.9.9
```

Currently it only lists the generation of the `$profile` with the `system` on as default.
It would be possible to list all available generations, but that would result in
a much more difficult to understand output, since the profiles would need to be
labled. For a better discovery of available profiles, a `list-profiles` option
could be implemented, but I guess this is out of scope for this RFC.


# Unresolved questions
[unresolved]: #unresolved-questions

## list-generations

- Is there any other useful information to show?
- Default value for configuration revision field if unset? (probably not)
- Truncate revision (maybe if hash only)?
- Put the `(current)` tag in it's own column?
- Show only system-profile by default?
- How to handle machine-readability?
- Provide stable API (e.g. `--porcelain`) for futureprooving output changes for
scripts? (probably unnecessary, since usage in scripts probably limited)
- Use `column` format for human readability? => Evaluation is eager
- Use `pager` to avoid spamming terminal?
- Is the order fine?

# Future work
[future]: #future-work

`nixos list-profiles` could be implemented for a better discoverability of profiles.
