---
feature: meson_builds_nix
start-date: 2022-08-25
author: Anderson Torres
co-authors: @p01arst0rm
shepherd-team:
shepherd-leader:
related-issues:
---

# Summary
[summary]: #summary

Use meson as an alternative build system for the reference implementation of Nix.

# Motivation
[motivation]: #motivation

Currently, the reference implementation of Nix evaluator and its companion toolset generated from the Nix source tree are built using the typical `./configure` shell script that relies on autoconf and the standard GNU Make utility.

This build system became clunky and plastered, and consequently hard to understand, modify, improve and port to other systems besides Linux.

Such state of things hinders development, specially outside the Linux and NixOS niches.

In light of this, we propose a novel, from-scratch alternative build infrastructure.

We expect to accomplish, among other goals,

- better code structuring;
- improved cross-platform support, especially in other programming environments, including but not limited to Unix-like operating systems;
- shorter build times;
- an overall improved user experience.

# Detailed design
[design]: #detailed-design

A carefully crafted set of files written in Meson should be included in the Nix repository, in order to describe how to deploy the Nix repository, generating all the expected artifacts (command line tools, libraries, configuration files etc.)

This novel build infrastructure should be able to provide at least all the features already present on the current quasi-autotools implementation, possibly with a different user interface.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

Currently @p01arst0rm is writing an implementation from scratch.

Some typical expected interactions are:

- Configuring: `meson setup build_dir`
- Building: `ninja -C build_dir` (or the backend-agnostic `meson -C build_dir compile`)
- Installing: `ninja -C build_dir install` (or the backend-agnostic `meson -C build_dir install`)

Usually, commandline options assume the format `-Dname=value`. This small change in user interface when compared to the typical `--name=value` is mostly harmless.

# Drawbacks
[drawbacks]: #drawbacks

Some possible drawbacks:

- A new build system would require changes on the code
  + On the other hand, such changes are likely to improve the code base.
  
- A new build system requires the developers become familiarized with it
  - Specially when this build system uses its own description language.
  + However, Meson is well documented, and its language is easy to grasp, specially for those familiarized with Python.

- A new build system indirectly brings its own dependencies to the Nix project
  - In particular, the reference implementation of Meson is written in Python.
  - Further, this reference implementation generates script files meant to be consumed by Ninja, a tool written in C++ that acts like a Make replacement.
  - This particular setting brings concerns about complexifying the bootstrap route.
  + Given that Nix is currently written in C++, we can assume a C++ compiler as part of such a bootstrap route.
  + There are full-featured alternative tools that replace Meson and Ninja. 
    + Namely, Muon and Samurai are implementations of Meson and Ninja that require only a C compiler and a set of POSIX standard tools.

- A new build system would require new strategies from the end users
  - In particular, package managers that deploy Nix for their respective platforms.
  + However, Meson and Ninja are nowadays a widespread toolset.
    + Many open source projects use it, from mpv and dosbox-staging to Xorg and GNOME
    + According to Repology, Meson is present in 53 package manager's families

- The transition between between the old and new build systems should be smooth
  - A wrapper script, maybe?
  + Meson is not an obscure project; a mere documentation update should suffice

# Alternatives
[alternatives]: #alternatives

The alternatives are

- Doing nothing

  It would keep the current code confusing and harder to work with.
  
- Other building systems (cmake, waf, premake etc.)
  - Their strenghts and weaknesses should be evaluated.
    - Tools strongly tied to other programming languages are strongly discouraged, because they further complexifies the bootstrap route as discussed above.
      - Namely, waf is basically a Python library, whereas premake is a Lua library.
    - Cmake has many noteworthy advantages:
      + Can generates Make- and Ninja-compatible scripts;
      + Supports Windows NT;
      + Supports typical high level idiomatic constructions;
      - On the other hand, the language is arguably more complex.

# Unresolved questions
[unresolved]: #unresolved-questions

Questions that deserve further inquiry:

- Unexpected interactions with Meson and Ninja
  - Specially, vendoring and reproducibility.

# Future work
[future]: #future-work

- Deprecate the current build scripts
- Backport the new build system to Nix 2.3
  - It was the latest release without Flakes support; it is important to bring such a deep modification to it.

# References
[references]: #references

- [Current work in progress from @p01arst0rm](https://github.com/NixOS/nix/pull/3160)
- [Muon](https://muon.build/), a C99 implementation of [Meson](https://meson.build/)
- [Samurai](https://github.com/michaelforney/samurai), a C99 implementation of [Ninja](https://ninja-build.org/)
- [Cmake](https://cmake.org/)
