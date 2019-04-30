---
feature: platform_support_tiers
start-date: 2019-04-28
author: Michael Raskin
co-authors: Matthew Bauer
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

### Tier 1

Aims: all packages should work (unless they don't make sense)

A platform-specific fix is expected to be applied in `master`

Support: good binary cache coverage, full support in tooling

Developer/user base: most of the Nix developers/users

* `x86_64-linux`, `gcc`+`glibc`

### Tier 1.5

Same aims and tooling support

Fewer developers and users, less testing — significantly more broken packages

* `aarch64-linux`, `gcc`+`glibc`

* `x86_64-darwin`, `clang`+Darwin/macOS

### Tier 2-ε

Aims: most of the popular packages work

Platform-specific things for arbitrary packages should not be too complicated

Support: native bootstrap tools are available, cross-build toolchains in the
binary cache, partial tooling support

Package updates might break build on the platforms of this tier and lower

* `i686-linux`, `gcc`+`glibc` — `ofBorg` builds via `pkgsi686Linux`, binary
  cache contains `wine` dependencies

### Tier 2

Aims: most of the popular packages work

Support: native bootstrap tools are available, cross-build toolchains in the
binary cache

* `armv{6,7,8}*-linux`, `gcc`+`glibc`

* `mipsel-linux`, `gcc`+`glibc`

* `x86_64-linux`, `gcc`+`musl`

* `x86_64-linux`, `clang`+`glibc`

### Tier 3

Aims: some packages are expected to work

Platform-specific fixes limited to general cleanups of non-standard
assumptions in the upstream code and basic toolchain fixes

* `aarch64-none`

* `avr`

* `arm-none`

* `i686-none`

* `x86_64-none`

* `powerpc-none`

* `powerpcle-none`

* `x86_64-mingw32`

* `i686-mingw32`

* `x86_64-linux`, `gcc`+`musl` — static

* `x86_64-linux`, `clang`+`glibc` — `llvm` linker

* `x86_64-linux` — Android

* `aarch64-linux` — Android

* `armv{7,8}-linux` — Android

### Tier 4

Aims: none

Support: none or accidental

Platform definitions present

A small amount of packages seems to work, maybe by luck

* `x86_64-linux`, `gcc`+`glibc` — static

* `x86_64-linux`, `gcc`+`glibc` — `llvm` linker

### Tier 4.5

Work ongoing to provide/merge Tier 4 support

* `wasm-wasi`

* `powerpc64le-linux`, `gcc`+`glibc`

### Tier 5

Aims: none

Support: none

No current support, but previous support of clear path to add support

* `aarch64-darwin`

* `i686-darwin`

* `x86_64-freebsd`

## Adding a new platform

It is expected that Tier-4 support can be added freely, and Tier-3 support is
added once enough packages are tested and sustained development happens.
Tier-2 support (and higher tolerance to platform-specific fixes in
non-toolchain packages) is generally linked to higher user interest and
sustainability of both the platform itself and Nixpkgs development for the
platform.

Support above Tier-2 (and expectation that platform non-users pay attention to
the platform support on updates) requires deployment of test infrastructure
for the platform.

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
