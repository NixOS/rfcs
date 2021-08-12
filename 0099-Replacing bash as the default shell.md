---
feature: oil-shell
start-date: 2021-08-11
author: Raphael Megzari (happysalada)
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues:
---

# Summary

[summary]: #summary

Use oilshell as the default shell for nixos. Oilshell aims to be compatible with bash while trying to bring real programming language features (like hashmap or dicts) to the shell.

## Motivation

[motivation]: #motivation

Two primary motivations

- Removing the footguns in bash that even experienced programmers find painful
- Making shell scripts more powerfull to remove the need to bring additional languages for scripting.

## Detailed design

[design]: #detailed-design

The [oil shell](https://www.oilshell.org/) has two parts osh and oil. Osh is compatible with bash and posix and it's goal is to run existing shell scripts. The oil language is a brand new incompatible language. The idea is to fix more than four decades of accumulated warts in the Unix shell. Many Unix users are angry that shell is so difficult, and Oil aims to fix that. Those definitions were taken verbatim from [reference](https://www.oilshell.org/blog/2021/01/why-a-new-shell.html)

Regarding oil

A high level overview is that it has a syntax similar to python, it brings dictionaries (hashmaps). For more details check the following posts

- [This post](https://www.oilshell.org/blog/2021/01/why-a-new-shell.html) aims at describing the goals in trying to create a new shell and the alternatives.
- [This post](https://www.oilshell.org/blog/2020/01/simplest-explanation.html) aims to provide a simple explanation of what oil is.
- [This post](https://www.oilshell.org/release/latest/doc/idioms.html) shows different oil idioms and how they fix some of bash problems.

There would be two steps to make the transition from bash to oil.

- From bash to osh. There is one incompatibility that came up so far. osh does not handle the `-i` flag on local and declare. The transition involves rewriting some shell scripts to get rid of the `-i` flag. There are about 5-10 uses in stdenv, and I've started PRs to remove them. After those changes, it would be possible to switch from bash to osh and test this for a while to verify there are no regression.
- From osh to oil. It will require to modify stdenv to be able to run with the `strict_errexit` flag. The changes will be a little more involved, but as long as nobody uses oil specific features, we could retain compatibility with bash and posix. The exact quantity of work involved is unknown.

One more things to consider here is that changes to stdenv are relatively slow and costly. Even for some seemingly simple changes they can break things in unexpected ways. One example was trying to split buildFlagsArray on whitespace, some packages use newlines for the split. The tests seemed to pass and breakage was discovered much later. For this reason, changes in stdenv can only be made sure to work by triggering a full hydra rebuild which takes several days. Even after that because of flaky tests, it's hard to be sure nothing was broken by the actual changes.

[reference](https://github.com/oilshell/oil/wiki/Migration-Guide)

Some more background context. Originally this is coming from this [PR](https://github.com/NixOS/nixpkgs/pull/105233) by zimbatm. After seeing this, I thought I would implement the changes needed to make the switch and generate a discussion in a PR. Somebody brought to my attention that this change is significant enought that it needs to go through an RFC.

## Examples and Interactions

[examples-and-interactions]: #examples-and-interactions

Some extracts from the post [why use oil](https://www.oilshell.org/why.html)

- better error handling. One of the confusing things about bash is how to handle errors in scripts. `err_exit` was a try at improving that but it has many pitfalls. Oil aims to have more straightforward error handling. Any error will exit, if you do not want that behavior there is the `try my_function` form.

`mkdir /tmp/dest && cp foo /tmp/dest` becomes simply

```Shell
mkdir /tmp/dest
cp foo /tmp/dest
```

- Oil has
- Introduce functions that need to explicitely define their parameters

```Shell
proc f(first, @rest) { # @ means "the rest of the arguments"
  write -- $first
  write -- @rest # @ means "splice this array"
}
```

instead of the traditional

```Shell
f() {
  echo $1
  shift 1
  echo "$@"
}
```

those functions are called procs and their variables don't mess with their outter scope.

- Oil has proper associative arrays (dictionaries or hashmaps) that don't have the problems that bash's have.

- No more quotes to prevent splitting

## Drawbacks

[drawbacks]: #drawbacks

- Currently oilshell has a bus factor of 1. While Andrew has been very motivated and responsive thus far, this could change in the future.
- Oil shell is pre 1.0 so the syntax might change.
- Parts of oil are rewritten in c++, while this could be good for performance, new user might discover bugs that are really hard to debug.
- Oil has had little usage so far, there might be bugs that will just be discovered by having a large user base.
- Using osh, could be straightforward, but using oil might take more work as basically the existing bash code need to rewritten with `strict_errexit`.
- The oil documentation is lacking at the moment.
- Oil has really lofty goals, which I think it's good, but some potential solutions are not documented or not implemented. One example is eggex which are meant to be a replacement for reggexes.

## Alternatives

[alternatives]: #alternatives

- I'm not aware of any other alternative shell that could enable a smooth transition with bash. [Here](https://github.com/oilshell/oil/wiki/Alternative-Shells) is a list of alternative shells.

## Unresolved questions

[unresolved]: #unresolved-questions

- What are the pittfalls and bugs in oilshell?
- How much work exactly is required to make the switch?

## Future work

[future]: #future-work

- Remove the `-i` flag uses in stdenv. An example can be found in [PR](https://github.com/NixOS/nixpkgs/pull/130597)
