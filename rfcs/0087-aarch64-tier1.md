---
feature: aarch64-tier1
start-date: 2021-03-09
author: Vika Shleina
co-authors: Graham Christensen
shepherd-team: TBD
shepherd-leader: TBD
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

`aarch64-linux` will benefit from increased percieved binary cache coverage
as an additional result of channel bumps waiting for aarch64 builds to finish,
saving on build times for end users.

# Detailed design
[design]: #detailed-design

If this RFC is accepted, `aarch64-linux` builds will be added to stable
and unstable channels' `tested` aggregate jobs on Hydra, giving them ability
to block channel advances. Hydra will start building aarch64 packages and run
aarch64-based tests as part of stable and unstable channels, including them in
the binary cache, increasing its coverage as a result.

It is possible that the availability of aarch64 builders from Equinix Metal will at times be
reduced, causing delays in aarch64 build capacity. We will extend the
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

Merging this RFC should happen simultaneously with the merging of documentation and perhaps
a NixOS module for configuring qemu-binfmt as an aarch64 builder on x86_64 machines.

(**To clarify**: should we add additional documentation around `boot.binfmt.emulatedSystems`
to increase its visibility?)

The list of NixOS AMIs on NixOS.org will also be extended to include aarch64 images.

# Drawbacks
[drawbacks]: #drawbacks

Some build failures could unneccesarily delay channel advances, delaying critical updates.

# Alternatives
[alternatives]: #alternatives

Create an aarch64-focused channel that would build same things current `unstable` does, but for aarch64 only. This has a significant drawback: it is possible for the x86_64 channel and the aarch64 channels to never pass on the same commit, making deployment to a heterogeneous cluster of x86_64 and aarch64 machines very challenging.

# Unresolved questions
[unresolved]: #unresolved-questions

Do we have enough machines to handle aarch64 builds without delaying `x86_64-linux` builds?

# Future work
[future]: #future-work

TBA
