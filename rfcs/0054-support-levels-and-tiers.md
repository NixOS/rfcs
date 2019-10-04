---
feature: support_levels_and_tiers
start-date: 2019-10-03
author: CrystalGamma
co-authors: –
related-issues: –
---

# Summary
[summary]: #summary

A scheme for expressing and managing support of packages and for platforms in nixpkgs.

# Motivation
[motivation]: #motivation

Currently there is no consensus in the nixpkgs maintainer community regarding how to deal with platform-specific code and changes, as well as few official statements and processes to represent platform support to users.
As a growing distribution, the Nix community needs to establish a framework to determine platform support and decide what platform-specific packaging code is acceptable.

Providing a good base for platform discussions and defining support expectations should improve communication with users (especially those of non-mainstream platforms) and should allow establishing procedures to deal with developers wishing to add support for new architectures.

# Detailed design
[design]: #detailed-design

This RFC defines scopes for packages and the corresponding support and acceptance tiers for platforms.

## Support Level
The *scope* of a package is a designator of its importance for nixpkgs.

This RFC proposes an initial set of 4 scopes (in order of descending importance): `core`, `bootstrap`, `system` and `all`.
(Terminology: A scope to the left of another in this list is said to be 'narrower' or 'more significant' than it. Conversely a scope to the right of another is considered 'wider'/'broader' or 'less significant'.) Each broader scope includes the packages of the narrower ones. See [below](#relationship-between-scope-support-and-acceptance) for what by each scope comprises.

A `meta` attribute `scope` which is supposed to take a value from the aforementioned enumeration is introduced for this purpose.
A package with its `meta.scope` unset is assumed to have scope `all` (in fact, setting `scope` to `all` should only be done in special cases, such as for packages produced by overriding others).

Scrutiny required for packages increases with narrower scope, as such the scope for each package should be kept as broad as possible.

## Platforms and support tiers
A platform is a combination of these differentiations:

* CPU architecture
* kernel
* libc
* compiler
* other system differentiations (e. g. NixOS/non-NixOS on Linux)

Obviously, not all such combinations make sense and not all of these distinctions are relevant for all discussions.
Where some of these dimensions don't make a difference, platforms may be handled as a group (particularly the term 'platform-specific' may mean 'specific to a given group of similar platforms').

Each platform has a *support tier* that describes the expectations that one should have when attempting to use nixpkgs on that platform.

This RFC proposes an initial set of 5 support tiers (in decreasing order): `full`, `system`, `bootstrap`, `core` and `none`.

The `core`, `bootstrap` and `system` tiers are roughly characterized by the set of all packages with the corresponding scope being usable. More on this [below](#relationship-between-scope-support-and-acceptance). Note that higher support tiers correspond to the inclusion of broader scopes.

Platform support tiers are advertised to users and should help them decide what platforms to use or whether the nixpkgs ecosystem is suitable for their needs, given a platform.

## Acceptance tiers
Each platform is also assigned an *acceptance tier*. It describes the amount of maintenance, infrastructure and management effort specific to that platform (or group of platforms) that is considered acceptable.

Each acceptance tier corresponds to a support tier (and carries the same name): it is characterized by a reasonable estimation of effort required to reach that support tier.

A platform generally has an acceptance tier that is the same (for mature platforms) or higher (for platforms that target a higher support tier) than its support tier.

Acceptance tiers are used to discuss the acceptance of changes that introduce platform-specific features and workarounds: platform-specific changes that modify a package out of scope for its acceptance tier should generally be rejected with reference to that acceptance tier, as should introducing out-of-scope platform-specific packages.
Conversely, most platform-specific changes that improve packages required for the support tier corresponding to the acceptance tier should be accepted, unless an obviously better way to achieve the same improvement is known.

A complicated issue is changes that isolate platform-specific behavior, e. g. by adding conditionals in Nix expressions for flags that used to be applied unconditionally but have in fact platform-specific applicability (often this means x86-specific) or adding patches that correct unportable code in the package itself.
As long as the added burden on maintenance of nixpkgs is not unreasonable, these should be accepted even if they only benefit platforms whose acceptance tier does not cover the package in question.

## Relationship between scope, support and acceptance

| scope | tier | code included in scope | meaning of support tier | meaning of acceptance tier |
| --- | --- | --- | --- | --- |
N/A | none | N/A | There has been no testing done with packages on/for that platform, there may not even be `lib/systems` infrastructure for the platform | no code is accepted for this platform
core | core | `lib/systems` infrastructure, compiler/libc packages, cross-stdenv build infrastructure | A cross-stdenv can be built for the system | code is accepted to allow building a cross-stdenv
bootstrap | bootstrap | bootstrap files, packages required to build bootstrap files (stdenv bootstrap, busybox, …) | Bootstrap files (if required) can be cross- and native-built (most importantly this includes bootstrapping a stdenv on the platform itself). | changes to packages involved in bootstrapping (`bootstrap` scope) are accepted (if technically sound)
system | system | OS management tools, service management systems, daemons, bootloaders, mesa, core NixOS modules and tooling, … (and their dependencies) | NixOS-supporting systems (i. e. Linux): a bootable mostly-default configuration of NixOS can be built. Other OSes: reasonable set of OS-specific utilities is available and works (if applicable), all inapplicable packages in the `system` scope are marked as such with `meta.platforms` or `meta.badPlatforms`, all other `system` packages are expected to work. | (technically sound) changes are accepted for packages in the `system` scope
all | full | all other packages and modules | most software is expected to work, those that do not are marked as such with `meta.platforms`, `meta.badPlatforms` or `meta.broken` | Being specific to this platform is not an argument for rejection (as long as the change is technically sound)

## Management of scopes
Packages should be assigned the widest scope possible.
If the scope expands to include further packages (e. g. dependencies are added to a package already in scope), `meta.scope` for the relevant packages must increase.

To facilitate the detection of such cases, a nixpkgs configuration option `maxScope` (taking the same values as `meta.scope` and defaulting to `all`) is added that shall be checked in `pkgs/stdenv/generic/check-meta.nix`, disabling packages with wider scope.
Having Hydra evaluations defining each scope (i. e. stdenv for `core` and `bootstrap`, NixOS for `system` on Linux, lists of system utilities for non-Linux) should allow detecting packages with overly broad `meta.scope`.
Note that the evaluations should be mostly independent of platforms, since this is only about automatically detecting that packages required for a given scope are actually marked with at least the corresponding scope; the derivations needn't even be built for this purpose.

Should restructuring (e. g. of stdenv bootstrap or changing the 'reference' NixOS configuration for the `system` scope/support tier) exclude a package from the scope of a certain scope, the `meta.scope` should be widened appropriately. It remains TBD if this can be checked byautomatic means.

## Management of support/acceptance tiers
(Note: this part in particular is a first draft. Suggestions welcome)

As long as the relevant compiler supports the target, adding a platform to satisfy support tier `core` should be relatively simple. (Mainly involves adding support in `lib/platforms` and adding flags to compiler and libc if necessary)
For that reason, acceptance of such platforms should be at `core` by default.

Platform maintainer groups (PMGs) should exist for each supported platform (group). A single platform tuple may be covered by the scope of multiple PMGs (if one e. g. maintains x86 platforms and one maintains musl platforms).

For lower support tiers (`core`, `bootstrap`) a PMG may only consist of a few individuals that can be CCed on relevant issues/PRs. If maintainers become irresponsive over extended periods of time, they may be removed from the group.
There shall be lower limits on the number of active maintainers in the PMG for each support tier (Note that this requirement is mostly to guarantee responsiveness for important platforms, since most breakage is expected to be detected using CI):

* `core`: 1 maintainer
* `bootstrap`: 2 maintainers
* `system`: 5 maintainers
* `full`: 10 maintainers

PMGs should be notified and should publically give an (informal) report on the state of the platform as part of the release process for a major nixpkgs/NixOS version.
This can also serve as an occasion to gauge responsiveness of their individual members.

If the maintainers report maturity at the current support tier, the acceptance tier may be raised one above the support tier.
If then the PMG reports adequate quality of support for the next-highest support tier, the support tier may be raised appropriately.

Support tiers are dropped if the number of responsive maintainers in the PMG goes below the required number for the support tier or if major breakage is reported for multiple subsequent major releases. (Note that the acceptance tier may be kept if sensible)

Support tiers are advertised on nixos.org for the benefit of users. In particular, for smaller platforms, the maintainers are listed on the page so that they may be easily mentioned in issues/PRs.

Platforms that have potential for use beyond the embedded sector should have an easy path to reach `bootstrap` acceptance.

Support tiers `system` and `full` are expected to represent the platforms of the majority of nixpkgs/NixOS users.
As such platforms need a Hydra installation before they can be raised to those support tiers.
Platforms with `bootstrap`-tier support should have the cross-build (from major platforms) of bootstrap files in Hydra (and bootstrap files published).
The (native) bootstrap process should be automatically checked in emulation if possible (e. g. qemu-user using binfmt_misc).

Generally changes that cause Hydra-detected breakage or what is reported during the process of a PR need to fixed within a reasonable time frame (the length of which is approximately inversely proportional to the importance of the affected platforms and packages) or reverted/rejected, i. e. they fall in the responsibilty of the PR author.
Further breakage is the responsibility of the PMG. (Continued failure of the PMG to provide fixes will result in reduced support tier, as described above)

## Required action
In summary, this RFC calls for the following to be done:

* implementation of the PMG management and their integration into the release process
* establishment of PMGs for existing platforms
* assignment of support tiers for existing platforms
* implementation of `meta.scope` and the `maxScope` option
* categorization of packages into the scopes
* setup of evaluations to check for packages to with overly broad scope
* TBD: implementation of checks for overly-narrow `meta.scope`

# Drawbacks
[drawbacks]: #drawbacks

Allowing streamlined development of diverse platforms in nixpkgs may increase maintenance burdens for established platforms and increase administrative and infrastructural requirements of the project.

# Alternatives
[alternatives]: #alternatives

RFC 46 discussed marking different support levels for (package, platform) pairs.

Lack of a process to add new platforms and manage/advertise support is likely to result in frustration of developers and users of emerging platforms, which may impact viability of the project in the long run.

# Unresolved questions
[unresolved]: #unresolved-questions

As is, there are a lot of weasel words ("reasonable", "adequate" and friends) in the text.
How rigid should the definition of the relevant criteria be?

How exactly to `check-meta` the `core` and `bootstrap` scopes? (since cross-stdenv is built by a native stdenv) – accept `bootstrap` packages even if `maxSupportLevel` is `core` as long as target == host?

The decisions about changing support and acceptance tiers should be made based on PMG reports, but who has the final say on what tiers are assigned?

How is PMG membership managed?

Where are PMG reports (and requests for report) made? GitHub issues (or whatever PR/bug tracking system the community uses in the future) make sense, because contributors are already expected to be able to use GitHub, but many other platforms might also be possible.

Do the support/acceptance tier management scheme and the requirements for PMGs make sense?
Is their administrative overhead acceptable?

# Future work
[future]: #future-work

Adding further support tiers/scopes, e. g. `system-cross`. In general a more rigorous definition of supported cross-build vectors would be useful

Evolution of the support/acceptance tier management scheme when experience has been gathered.
