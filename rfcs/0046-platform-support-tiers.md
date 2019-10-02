---
feature: platform_support_tiers
start-date: 2019-04-28
author: Michael Raskin
shepherd-team: Ryan Mulligan, Jonas Pfenniger, Graham Christensen, John Ericson
shepherd-leader: John Ericson
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
* What platform-related builds are channel update blockers?
* Is the platform normally tested by the tools like ofBorg? Is it possible to
  get something tested with a reasonable effort?
* Is there expectation that updates do not break things for this platform?
* How many developers are interested in the platform? How easy it it to get a
  non-trivial fix reviewed?
* Is Nix supported?
* Are native bootstrap tools available?

## Main dimensions

Note that Tolerance tier is never higher than Tooling tier (and normally not
higher than Package coverage tier).

### Tooling

#### Tier 1

A lot of packages built by Hydra, full ofBorg support, some ordinary packages
are channel-blockers on Hydra.

#### Tier 2

Native bootstrap tools available, cross-build toolchains in the binary cache,
no channel-blocking jobs on Hydra.

#### Tier 3

None

### Tolerance/impact

#### Tier 1

Problems on these platforms can block updates.

#### Tier 1.5

Platform-specific patches expected to be applied as needed; updates expected
not to break the build on these platforms, problems should be investigated
(and reported to the platform maintenance team if no solution was found).

#### Tier 2

Platform-specific fixes are expected to be rare and non-intrusive. Updates
might break builds.

#### Tier 3

Fixes necessary for this platforms must be either limited to compilation
toolchains, or general cleanups of non-standard assumptions (e.g. «everything
that is no x86 is a kind of ARM» or «malloc(0) behaviour is a reliable
indicator of other malloc features»). These fixes must be generic: there
should be a reasonable expectation that other exotic platforms would equally
benefit from the exact same fix.

#### Tier 4

It is recommended to keep platform-specific patches to the toolchain in a
separate package. Cleanups not necessary on any tier-3 platforms can be
rejected.

### The number of working packages

#### Tier 1

Almost everything that is not explicitly platform specific and that is not
abandoned (in Nixpkgs) works.

#### Tier 1.5

Most packages work, credible ambition to reach Tier 1 at some point.

#### Tier 2

Most of the popular packages work.

#### Tier 3

Some packages work.

#### Tier 4

Platform definitions present, a small number of packages might be working.

## Current platforms

### Tier 1

Developer/user base: most of the Nix developers/users

* `x86_64-linux`, `gcc`+`glibc`

### Tier 1.5

Fewer developers and users, less testing; tier-1 tooling.

* `aarch64-linux`, `gcc`+`glibc`

A team @NixOS/aarch64-maintainers shall be created to include people who
understand the platform and use it.

If there is a complicated problem on this platform when updating a package
that was previously built succesfully on Aarch64, @NixOS/aarch64-maintainers
team should be informed.

* `x86_64-darwin`, `clang`+Darwin/macOS

If there is a complicated problem on this platform when updating a package
that was previously built succesfully on macOS, @NixOS/darwin-maintainers team
should be informed.

### Tier 2-ε

Pure stdenv for native builds is a channel-blocking job; `wine` dependencies
are available in the binary cache

* `i686-linux`, `gcc`+`glibc` — `ofBorg` builds via `pkgsi686Linux`, binary
  cache contains `wine` dependencies

### Tier 2

* `armv{6,7,8}*-linux`, `gcc`+`glibc`

* `mipsel-linux`, `gcc`+`glibc`

* `x86_64-linux`, `gcc`+`musl`

### Tier 3

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

* `x86_64-linux`, `clang`+`glibc`

* `x86_64-linux`, `clang`+`glibc` — `llvm` linker

* `x86_64-linux` — Android

* `aarch64-linux` — Android

* `armv{7,8}-linux` — Android

### Tier 4

* `x86_64-linux`, `gcc`+`glibc` — static

* `x86_64-linux`, `gcc`+`glibc` — `llvm` linker

### Tier 4.5

Work ongoing to provide/merge Tier 4 support

* `wasm-wasi`

* `powerpc64le-linux`, `gcc`+`glibc`

### Tier 5

No current support, but previous support or clear path to add support

* `aarch64-darwin`

* `i686-darwin`

* `x86_64-freebsd`

* `i686-solaris`

* `x86_64-illumos`

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
