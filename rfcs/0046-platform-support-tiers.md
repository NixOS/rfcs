---
feature: platform_support_tiers
start-date: 2019-04-28
author: Michael Raskin
co-authors:
related-issues:
---

# Summary
[summary]: #summary

Document the way to describe the level of support a platform can expect in
Nixpkgs.

# Motivation
[motivation]: #motivation

When adding a new platform, be it a new C library option, a new
cross-compilation target configuration or a new CPU architecture, there is a
discussion of support expectations and maintenance burden. Having a documented
vocabulary to describe the expectations and documented precedents should make
such discussions more efficient.

# Detailed design
[design]: #detailed-design

## Platform elements

* CPU architecture (possibly: subarchitecture, optional features)
* OS kernel
* C compiler
* C library
* NixOS/non-NixOS global layout, in case of Linux with glibc
* Global linking options

## Questions to answer for each platform

* What fraction of packages is expected to work?
* How many users there are / how much testing one can expect?
* How much complexity is a platform-specific fix allowed to carry?
* Is there a binary cache for the platform?
* Is the platform normally tested by the tools like ofBorg? Is it possible to
  get something tested with reasonable effort?
* Is there expectation that updates do not break things for this platform?
* How many developers are interested in the platform? How easy it it to get a
  non-trivial fix reviewed?
* Is Nix supported?
* Are native bootstrap tools available?

## Platforms

* `x86_64-linux`, native builds with `gcc` and `glibc`. Status: default
  platform, the only truly first-tier platform. All packages not specifically
  defined in terms of OS-specific or CPU-specific tooling for other platforms
  are expected to work if they work anywhere.

* `aarch64-linux`, native builds with `gcc` and `glibc`. `x86_64-darwin` as a
  name for macOS with `clang` compiler. Status: second-tier platforms. Many
  packages are supposed to work, the main Hydra puts a lot of binary packages
  into the binary cache, there is tooling support to check builds on these
  platforms and some level of effort is expected to be spent on investigating
  new failures after update.

* `i686-linux`, `armv7l-linux`, `x86_64-linux` with `musl`, static builds.
  Status: cross-compilation targets in different meanings of these words. No
  binary cache available, checking a cross-build via ofBorg is possible but
  complicated, no expectations on upgrade. Fixes not necessary on upper-tier
  platforms are expected to be either localised inside `stdenv` dependencies
  and other compilers/build tools, or to be general cleanups that just happen
  to be optional on upper-tier platforms.

## Adding a new platform

A proposal to add a new platform should justify the level of platform-specific
fixes to be tolerated.

Before adding an expectation that platform non-users pay attention whether
upgrades break a lower-tier platform, support for testing on this platform
must be available.

# Drawbacks
[drawbacks]: #drawbacks

Maintaining the list of platforms (and coordinating agreement on explicit
support expectations) takes effort, both technical and organisational.

# Alternatives
[alternatives]: #alternatives

Do nothing; make decisions on platform support trade-offs on case-by-case
basis without a shared framework.

# Unresolved questions
[unresolved]: #unresolved-questions

The list of currently supported platforms is incomplete.

# Future work
[future]: #future-work

Clarify what other considerations there are from the point of view of support
expectations.

Describe what expectations usually appear together.

Support expectations for packages (and package options), NixOS modules, and
hardware configurations could also be defined.

Levels of desirability for tricks that are sometimes the only way but are not
generally encouraged could be defined. (Example: when building an FHS
environment becomes a reasonable strategy to get something running on a NixOS
machine?)
