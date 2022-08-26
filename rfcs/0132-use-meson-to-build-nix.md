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

Use meson as an alternative build system for the reference implementation of
Nix.

# Motivation
[motivation]: #motivation

Currently, the reference implementation of Nix evaluator and its companion
toolset generated from the Nix source tree are built using an autotools-like
script.

This quasi-autotools script became clunky and plastered, and consequently hard
to understand, modify, improve and port to other systems besides Linux.

Such state of things hinders development, specially outside the Linux and NixOS
niches.

In light of this, we propose a novel, from-scratch alternative build
infrastructure.

We expect to accomplish, among other goals,

- better code structuring
- improved cross-platform support, especially in other programming environments,
  including but not limited to Unix-like operating systems;
- shorter build times;
- an overall improved user experience.

# Detailed design
[design]: #detailed-design

A carefully crafted set of files written in Meson should be included in the Nix
repository, in order to describe how to deploy the Nix repository, generating
all the expected artifacts (command line tools, libraries, configuration files
etc.)

This novel build infrastructure should be able to provide at least all the
features already present on the current quasi-autotools implementation, possibly
with a different user interface.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

Currently @p01arst0rm is writing an implementation from scratch.

# Drawbacks
[drawbacks]: #drawbacks

Some possible drawbacks:

- A new build system would require changes on the code
  + On the other hand, such changes are likely to improve the code base.
  
- A new build system requires the developers become familiarized with it
  - Specially when this build system uses its own description language
  + However, the Meson language is easy to grasp, specially for those
    familiarized with Python, besides being well documented.

- A new build system indirectly brings its own dependencies to the Nix project
  - In particular, the reference implementation of Meson is written in Python.
  - Further, this reference implementation generates script files meant to be
    consumed by Ninja, a tool written in C++ that acts like a Make replacement.
  - This particular setting brings concerns about complexifying the bootstrap
    route.
  + Given that Nix is currently written in C++, we can assume a C++ compiler as 
    part of such a bootstrap route.
  + There are full-featured alternative tools that replace Meson and Ninja.
    Namely, Muon and Samurai are implementations of Meson and Ninja that require
    only a C compiler and a set of POSIX standard tools.

- A new build system would require new strategies from the end users
  - In particular, package managers that deploy Nix for their respective
    platforms
  + However, Meson is nowadays a widespread tool, used in many open source
    projects ranging from DOSBox Staging and mpv to GNOME and Xorg; therefore it
    is already included in many package managers' databases

# Alternatives
[alternatives]: #alternatives

The alternatives are

- Doing nothing

  It would keep the current code confusing and harder to work with.
  
- Other building systems (cmake, waf, scons etc.)
  - Their strenghts and weaknesses should be evaluated.
    - Tools like waf and scons are strongly discouraged, because they are tied
      to other programming languages, bringing the bootstrap concerns already
      discussed above.

# Unresolved questions
[unresolved]: #unresolved-questions

Questions that deserve furtehr inquiry:

- Unexpected interactions with Meson and Ninja
  - Specially, vendoring and reproducibility.
- Smooth the transition between the old and new build systems
  - A wrapper script, maybe?

# Future work
[future]: #future-work

- Deprecate the quasi-autotools script set
- Backport the new build system to Nix 2.3
  - It was the latest release without Flakes support; it is important to
    bring such a deep modification to it.
