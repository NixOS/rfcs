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

Use meson as an alternative build system for Nix.

# Motivation
[motivation]: #motivation

Currently, the Nix evaluator and its companion toolset generated from the Nix source tree are built using the typical `./configure` shell script that relies on autoconf, along with standard GNU Make utility.

Over time, this build system has been modified to keep up with the development needs of Nix project. However, it has reached a state where the build system became clunky and plastered, hard to understand and modify, consequently making improvements to the project as a whole very difficult.

In particular, many changes have been introduced that impact compatibility outside Linux and NixOS niches. These issues can hinder development on other platforms, including but not limited to Unix-like systems.

In light of this state of things, we propose a novel alternative to the current building infrastructure.

We expect to accomplish, among other goals,

- better code structuring and documentation;
- improved cross-platform support, especially outside NixOS and Linux programming environments
- shorter build times;
- improved unit testing;
- an overall improved user experience.

# Detailed design
[design]: #detailed-design

A carefully crafted set of Meson files should be included in the Nix repository, providing a description on how to deploy the Nix repository, generating all the expected artifacts (command line tools, libraries, configuration files etc.)

This novel building infrastructure should be able to provide at least feature parity with the current quasi-autotools implementation, albeit in a different user interface.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

Currently @p01arst0rm is writing an implementation from scratch.

Here is a table comparing some expected interactions:

|----------------------|--------------------|------------------------------|
| Action               | Current            | Meson                        |
|----------------------|--------------------|------------------------------|
| Configuring          | `./configure`      | `meson setup build_dir`      |
| Building             | `make`             | `meson -C build_dir compile` |
| Installing           | `make install`     | `meson -C build_dir install` |
| Command-line Options | `--enable-gc=true` | `-Dgc=enabled`               |
|----------------------|--------------------|------------------------------|

# Drawbacks
[drawbacks]: #drawbacks

Some possible drawbacks:

- A new build system would require changes on the code
  + On the other hand, such changes are likely to improve the code base.
  
- A new build system requires the developers become familiarized with it
  - Specially when this build system uses its own description language.
  + However, Meson is well documented, and its Python-esque language is easy to grasp.

- A new build system indirectly brings its own dependencies to the Nix project
  - In particular, the reference implementation of Meson is written in Python.
  - Further, this reference implementation generates script files meant to be consumed by Ninja.
  - Ninja is a tool written in C++ that acts like a `make` replacement.
  - This particular setting brings concerns about complexifying the bootstrap route.
  + Given that Nix is currently written in C++, we can assume a C++ compiler as part of such a bootstrap route.
  + There are full-featured alternative tools that replace Meson and Ninja. 
    + Namely, Muon and Samurai are implementations of Meson and Ninja that require only a C compiler and a set of POSIX standard tools.
  + Autotools also have its own set of dependencies, and a fair comparison should include them

- A new build system would require new strategies from the end users
  - In particular, package managers that deploy Nix for their respective platforms.
  + However, Meson and Ninja are a widespread toolset.
    + Many open source projects use Meson, from mpv and dosbox-staging to Xorg and GNOME
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
      + Supports Windows NT and MacOS platforms
      + Supports typical high level idiomatic constructions;
      - On the other hand, cmake language is arguably more complex.
      - Both Meson and Cmake support Apple Xcode and Microsoft MSVC project file formats

# Unresolved questions
[unresolved]: #unresolved-questions

Questions that deserve further inquiry:

- Unexpected interactions with Meson and Ninja
  - Specially, vendoring and reproducibility.

# Future work
[future]: #future-work

- Deprecate and remove the current quasi-autotools scripts
- Backport the new build system to Nix 2.3
  - It was the latest release without Flakes support; it is important to bring such a deep modification to it.

# References
[references]: #references

- [Current work in progress from @p01arst0rm](https://github.com/NixOS/nix/pull/3160)
- [Muon](https://muon.build/), a C99 implementation of [Meson](https://meson.build/)
- [Samurai](https://github.com/michaelforney/samurai), a C99 implementation of [Ninja](https://ninja-build.org/)
- [Cmake](https://cmake.org/)
