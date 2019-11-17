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
such discussions more efficient. Building a consensus about a standard list of
restrictions for less-popular platform support can also streamline most
of the decisions of this type.

# Detailed design
[design]: #detailed-design

## Concrete actions

If this RFC is accepted, the following changes will happen:

* The definition of support tiers and a list of platforms with the
corresponding support tiers is added as an appendix to the Nixpkgs manual. The
list of platforms is further maintained as a part of the Nixpkgs manual. The
platform list in the manual will be initially based on the list in the appendix
of the present RFC.

* Other official documentation and marketing materials of the Nix/Nixpkgs/NixOS
project are edited and maintained to be consistent with the platform list in
the manual.

* NixOS GitHub organisation teams @NixOS/aarch64-maintainers and
@NixOS/exotic-platform-maintainers are created.

* Platform support status at the Tier 4 and below is updated according to
achievement of the requirements defined in this RFC.

* Discussions of platform support at the Tier 3 and above start using the
vocubulary based on this RFC and ensure that the requirements of this RFC are
met.

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

## Mutual obligations between the platform developers and the community

It is expected that the work necessary for supporting a platform is done by
people using the platform, as they have both qualification and motivation for
such work. In many cases a part or the entire build capacity will also be
provided by the platform users. The only cost recognising platform support is
allowed to impose on all the developers and users of Nixpkgs is the additional
code and additional conditions for a proposed change to be considered correct.

The platform support tier defines how intrusive and widespread the changes
needed to support the platform are allowed to be, and the amount of effort
spent on avoiding the changes causing platform-specific regressions.

To qualify for a tier, the platform support should meet requirements on package
coverage (how useful it is to users), and tooling (how easy it is to check the
changes on the platform without access to the platform, and to start using the
platform). Recognition of the lower tiers (Tier 5 and below) is based on
a technical review of the platform support code quality and requirements. For
higher tier an explicit decision has to be made based on the technical merits,
future expectation. resource allocation and project priorities. As this is not
a purely technical decision, this RFC only stipulates that a serious discussion
occurs once any new platform meets technical requirements of a high tier.

It is expected that a platform in a stable situation doesn't come close to
satisfying the technical requirements of the next higher tier, neither in terms
of coverage nor in terms of tooling. So in a stable situation the permitted
impact, the package coverage and the tooling for a platform correspond to the
same tier.

## Main support dimensions

### Impact (support tier)

This dimension describes the permissible impact of a platform on the Nixpkgs
repository. This includes the necessary patches as well as the handling of the
build failures of updates in Nixpkgs.

### Tooling requirments

This dimension measures how easy it is to find out what works and what doesn't
on the platform (in particular, without being a user of the platform).

### Package coverage.

This dimension measures avilability of the most important packages on the
platform. It is intended to describe how useful is the current state of the
platform support to the current and potential users.

## Support tiers

This section defines requirements and permitted impact for different support
tiers.

### Tier 1

#### Impact

Problems on these platforms can block updates for as long as necessary to
resolve the issue.

Platform-specific patches can be applied as necessary.

Many ordinary packages are channel-blockers on Hydra.

#### Tooling requirements

Most of packages built by Hydra, full ofBorg support.

#### Package coverage expectations

Almost everything that is not explicitly platform specific and that is not
abandoned (in Nixpkgs) works.

### Tier 2

#### Impact

Updates are  expected not to break the build on these platforms, problems
should be investigated. If no solution is easily found, the problems should be
reported to the platform maintainers with a reasonable amount of time provided
for fixing the issue.

Platform-specific patches are applied as needed.

Some ordinary packages are channel blockers on Hydra.

#### Tooling requirements

A lot of packages built by Hydra, full ofBorg support.

#### Package coverage expectations

Most packages work, credible ambition to reach Tier 1 coverage at some point.

### Tier 3

#### Impact

Completely platform-specific fixes are expected to be rare and non-intrusive.
Fixes to the compilation toolchains are expected.
General cleanups of non-standard assumptions (e.g. «everything that is no x86
is a kind of ARM» or «malloc(0) behaviour is a reliable indicator of other
malloc features») useful for this platforms are welcome.

Updates might break builds on this platform .

No channel-blocking jobs on Hydra.

#### Tooling requirements

Native bootstrap tools available, cross-build toolchains in the binary cache.

It is recommended to provide a derivation to test the software on this platform
(e.g. a Qemu-based derivation with all the necessary scripts).
As it is impossible to provide a legal testing setup for a Tier-2 platform
(macOS), this requirement is not strictly mandatory for Tier-3 tooling.

#### Package coverage expectations

Most of the popular packages work.

### Tier 4

#### Impact

Fixes necessary for this platforms must be either limited to compilation
toolchains, or general cleanups of non-standard assumptions (e.g. «everything
that is no x86 is a kind of ARM» or «malloc(0) behaviour is a reliable
indicator of other malloc features»). These fixes must be generic: there
should be a reasonable expectation that other exotic platforms would equally
benefit from the exact same fix.

#### Tooling requirements

None.

#### Package coverage requirements

Some packages work.

### Tier 5

#### Impact

It is recommended to keep platform-specific patches to the toolchain in a
separate package. Cleanups not necessary on any Tier-4 platforms can be
rejected if considered too intrusive.

#### Tooling requirements

None.

#### Package coverage requirements

Platform definitions present, a small number of packages might be working.

### Tier 6

Work ongoing to provide/merge Tier 5 support

#### Impact

Platform definitions and separate platform-specific toolchain packages can be
included.

### Tier 7

No current support, but previous support or clear path to add support

## Platform lifecycle

It is expected that Tier-5 support can be added freely, and Tier-4 support is
added once enough packages are tested and sustained development happens.
Tier-3 support (and higher tolerance to platform-specific fixes in
non-toolchain packages) is generally linked to higher user interest and
sustainability of both the platform itself and Nixpkgs development for the
platform. Note that Tier-3 tooling requirements imply allocation of some amount
of recurring build resources (for building and testing the toolchain).

Tier-2 and higher support (and expectation that platform non-users pay
attention to the platform on updates) requires deployment of test
infrastructure for the platform.

Note that from the impact point of view Tier-4 only allows the platform to be a
motivation for generic cleanups, and further tiers require commitment of
recurring resources. This is the reason for Tier-5 addition and Tier-4
promotion to happen inside the scope of normal technical review by the people
working with similar platforms; further tiers require allocation and of
hardware resources, and procedures for coordinating such financial decisions
are out of scope for this RFC.

When a platform starts falling out of use, its support tier (and permitted
impact) is reduced once it becomes clear that the current tier requirements
will stop being met in the near future. Platform-specifing patches no longer
permissible in the context of the new support tier can be removed at will by
the package maintainers.

# Drawbacks
[drawbacks]: #drawbacks

Maintaining the list of platforms (and coordinating agreement on explicit
support expectations) takes effort, both technical and organisational.

# Alternatives
[alternatives]: #alternatives

Do nothing; make decisions on platform support trade-offs on case-by-case
basis without a shared framework.

Defining a scope for Nixpkgs platform support and dropping/separating support
for some of the currently supported platforms.

Defining both requirements and impact based purely on the package sets.

# Unresolved questions
[unresolved]: #unresolved-questions

The list of currently supported platforms might still be incomplete.

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

Define the expetations of maintenance for specific packages; consider the
notion of platform-specific maintenance.

# Appendix A. Non-normative description of platforms in November 2019

We currently have a relatively steady state, so the tiers for each platform do
not differ too much and we can approximate it with a single tier per platform.

### Tier 1

Developer/user base: most of the Nix developers/users

* `x86_64-linux`, `gcc`+`glibc`

### Tier 2

Fewer developers and users, less testing; Tier-1 tooling.

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

### Tier 3

* `i686-linux`, `gcc`+`glibc` — `ofBorg` builds via `pkgsi686Linux`, binary
  cache contains `wine` dependencies

As an exception, pure stdenv for native builds is a channel-blocking job;
`wine` dependencies are available in the binary cache. These extra packages are
maintained as a part of `x86_64-linux` Wine support.

* `armv{6,7,8}*-linux`, `gcc`+`glibc`

* `armv{6,7,8}*-linux`, `gcc`+`glibc`, cross-compilation

* `aarch64-linux`, `gcc`+`glibc`, cross-compilation

* `mipsel-linux`, `gcc`+`glibc`

* `x86_64-linux`, `gcc`+`musl`

### Tier 4

A special team @NixOS/exotic-platform-maintainers is created and can be consulted about issues related to these platforms

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

### Tier 5

* `x86_64-linux`, `gcc`+`glibc` — static

* `x86_64-linux`, `gcc`+`glibc` — `llvm` linker

### Tier 6

Work ongoing to provide/merge Tier 4 support

* `wasm-wasi`

* `powerpc64le-linux`, `gcc`+`glibc`

### Tier 7

No current support, but previous support or clear path to add support

* `aarch64-darwin`

* `i686-darwin`

* `x86_64-freebsd`

* `i686-solaris`

* `x86_64-illumos`
