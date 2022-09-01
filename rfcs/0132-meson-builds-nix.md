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
- improved support across platforms, especially outside NixOS and Linux
- shorter build times;
- improved testing;
- more reasonable dependency management;
- an overall improved user experience.

# Detailed design
[design]: #detailed-design

A carefully crafted set of Meson files should be included in order to describe how to deploy the Nix repository, generating all the expected artifacts (command line tools, libraries, configuration files, documentation etc.)

This novel building infrastructure should be able to provide at least feature parity with the current quasi-autotools implementation, albeit in a different user interface.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

Before the examples, some informative paragraphs:

## What is Meson?

Meson is an open source, multiplatform build system crafted to be fast, correct and user-friendly.

According to its main site,

> The main design point of Meson is that every moment a developer spends writing or debugging build definitions is a second wasted. So is every second spent waiting for the build system to actually start compiling code.

Among its features, we highlight:

- user-friendly non-Turing complete DSL
  - very readable Python-esque syntax and functional, stateless semantics
- multiplatform support
  - among operating systems: Linux, Apple MacOS, Microsoft Windows NT
  - among programming environments: GCC, Clang, Xcode, Visual Studio etc.
  - among programming languages: C, C++, D, Fortran, Java, Rust etc.
    - supports command customization
  - cross compilation
  - many useful modules included (pkg-config, filesystem inspection, internationalization etc.)
- Comprehensive documentation
  - including tutorials, reference manuals and real world projects using it

## What is Ninja?

Ninja is a small, speed-focused, build tool that fills a similar role of Unix `make` or GNU `gmake`.

Its main feature is a low-level approach to build description. Where other build systems act like high level languages, Ninja acts like an assembly.

Ninja is bare-bones and constrained by design, having only the necessary semantics to describe build dependency graphs, relegating decision-making to superior tools like Meson or CMake.

Ninja DSL is human-readable, however it is not convenient to be manually written by human beings. As said before, Ninja is commonly used in tandem with other, higher-level build system.

## Example interaction

Here is a table comparing some expected interactions:

| Action    | Current                        | Meson+Ninja                          | Meson, backend-agnostic              |
|-----------|--------------------------------|--------------------------------------|--------------------------------------|
| Configure | `./configure --enable-gc=true` | `meson setup build_dir -Dgc=enabled` | `meson setup build_dir -Dgc=enabled` |
| Build     | `make`                         | `ninja -C build_dir build`           | `meson -C build_dir compile`         |
| Install   | `make install`                 | `ninja -C build_dir install`         | `meson -C build_dir install`         |
| Uninstall | `make uninstall`               | `ninja -C build_dir unistall`        | `meson -C build_dir unistall`        |

## Implementation

Currently, @p01arst0rm is working on an implementation from scratch.

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
  + Meson is not an obscure project; a careful documentation update should be sufficient

# Alternatives
[alternatives]: #alternatives

The alternatives are

- Doing nothing

  It would keep the current code confusing and harder to work with.
  
- Other building systems (waf, premake, cmake etc.)
  - Their strenghts and weaknesses should be evaluated.
    - Tools strongly tied to other programming languages are strongly discouraged
      - They complexify the bootstrap route as discussed above.
      - Namely, waf is basically a Python library, whereas premake is a Lua library.
    - Cmake has many noteworthy advantages:
      + Can generates Make- and Ninja-compatible scripts;
      + Supports typical high level idiomatic constructions;
      - On the other hand, cmake language is arguably more complex.
      + Both Meson and Cmake support Microsoft Windows NT and Apple MacOS platforms;
        + including project file formats of both MSVC and Xcode.

# Unresolved questions
[unresolved]: #unresolved-questions

Questions that deserve further inquiry:

- Unexpected interactions with Meson and Ninja
  - Specially, vendoring and reproducibility.

# Future work
[future]: #future-work

- Update project's continuous integration and related stuff
- Deprecate and remove the current quasi-autotools scripts
  - Preferably, the removal should be allocated to a minor version release
- Evaluate the positive and negative impacts of such a change
  - Specially the most subjective ones

# References
[references]: #references

- [Meson](https://meson.build/) official site
  - [Muon](https://muon.build/), a C99 alternative implementation
- [Ninja](https://ninja-build.org/) official site
  - [Samurai](https://github.com/michaelforney/samurai), a C99 alternative implementation
- [CMake](https://cmake.org/)
- [Meson tutorial](https://mesonbuild.com/Porting-from-autotools.html) comparing autotools and Meson
- [NetBSD tutorial](https://wiki.netbsd.org/pkgsrc/how_to_convert_autotools_to_meson/) comparing Meson and autotools

- [Current work in progress from @p01arst0rm](https://github.com/NixOS/nix/pull/3160)
