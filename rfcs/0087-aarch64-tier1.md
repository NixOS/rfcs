---
feature: aarch64-tier1
start-date: 2021-03-09
author: Vika Shleina
co-authors: Graham Christensen
shepherd-team: @samueldr, @Kloenk, @dhess, @grahamc
shepherd-leader: @samueldr
related-issues: TBD
---

# Summary
[summary]: #summary

Move `aarch64-linux` from a Tier 2 platform to Tier 1, as described in [RFC 0046](/rfcs/0046-platform-support-tiers.md)

# Motivation
[motivation]: #motivation

`aarch64-linux` support in Nixpkgs and NixOS matures over time and becomes
more and more stable, and more devices appear having NixOS on ARM support.
Moving it to a Tier 1 platform will allow us to block release channels on
aarch64-related build failures, making it easier and safer for ARM users
to upgrade their systems, and will help in keeping software versions in
sync between several architectures due to `x86_64-linux` and `aarch64-linux`
builds sharing a channel.

`aarch64-linux` will benefit from increased perceived binary cache coverage
as an additional result of channel bumps waiting for aarch64 builds to finish,
saving on build times for end users.

## Prior art
There were prior attempts at the same feat, but they failed due to technical
limitations of Hydra:
 - NixOS/nixpkgs@74c4e30 - disabled in 2017 because of memory issues
 - NixOS/nixpkgs#52534, NixOS/nixpkgs@36a0c13 - re-enabled in 2018 to pre-build important outputs
 - NixOS/nixpkgs@1bfe8f1 - demoted to partial support due to hydra-evaluator issues

As a result, since NixOS/nixpkgs@1bfe8f1, in late 2018 NixOS already is
blocking channel releases on the base system closure required to produce the
installer image.

Since then, hydra-evaluator has been rewritten, which probably will make
these concerns obsolete.

# Detailed design
[design]: #detailed-design

If this RFC is accepted, `aarch64-linux` builds will be added to stable
and unstable channels' `tested` aggregate jobs on Hydra, giving them ability
to block channel advances. Hydra will start building aarch64 packages and run
aarch64-based tests as part of stable and unstable channels, including them in
the binary cache, increasing its coverage as a result.

## Dealing with Capacity Issues
[design-capacity]: #design-capacity

It is possible that the availability of aarch64 builders from Equinix Metal will
at times be reduced, causing delays in aarch64 build capacity. We will extend the
nixos-org-configurations implementation of hydra-provisioner to dynamically allocate
aarch64 builders on AWS during these capacity shortfalls.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

<!-- This section illustrates the detailed design. This section should clarify all
confusion the reader has from the previous sections. It is especially important
to counterbalance the desired terseness of the detailed design; if you feel
your detailed design is rudely short, consider making this section longer
instead. -->

In [nixos/release-combined.nix](https://github.com/NixOS/nixpkgs/blob/master/nixos/release-combined.nix)
`aarch64-linux` will be moved to `supportedSystems`, enabling NixOS tests
to block channel advances in case of failures.

Merging this RFC should happen simultaneously with the merging of documentation
around configuring qemu-binfmt as a fallback method for building aarch64 packages on
x86_64 machines. Additionally, a sub-project that's out-of-scope for this RFC may be
established to catch build failures (of which sightings were reported) when using
emulation.

The list of NixOS AMIs on NixOS.org will also be extended to include aarch64 images.

# Drawbacks
[drawbacks]: #drawbacks

Some build failures could unneccesarily delay channel advances, delaying critical updates.

# Alternatives
[alternatives]: #alternatives

## Create a separate channel
Create an aarch64-focused channel that would build same things current `unstable` does,
but for aarch64 only. This has a significant drawback: it is possible for the x86_64
channel and the aarch64 channels to never pass on the same commit, making deployment
to a heterogeneous cluster of x86_64 and aarch64 machines very challenging.

### Use a separate channel as a stepping stone
Elaborating on the previous alternative, create an aarch64-focused channel. Show
there are enough resources and commitment to keep it green for half a year to a year.
Carry on with the RFC topic once this is the case.

# Unresolved questions
[unresolved]: #unresolved-questions

~~Do we have enough machines to handle aarch64 builds without delaying `x86_64-linux` builds?~~ (see [Dealing with Capacity Issues](#dealing-with-capacity-issues))

# Future work
[future]: #future-work

Track down build failures when using `boot.binfmt.emulatedSystems` and qemu-binfmt to build
aarch64 packages on `x86_64-linux` machines (e.g. by building a minimal closure fully without
binary caches and emulation).
