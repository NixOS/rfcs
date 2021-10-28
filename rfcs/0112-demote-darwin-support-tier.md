---
feature: demote_darwin_support_tier
start-date: 2021-10-27
author: piegames
co-authors: many
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Move x86_64-darwin from a Tier 2 platform to Tier 3, as described in [RFC 0046](https://github.com/NixOS/rfcs/blob/master/rfcs/0046-platform-support-tiers.md).

# Motivation
[motivation]: #motivation

Darwin is constantly adding additional maintainer burden. Especially, it does not live up to the requirements:

- "A lot of packages built by Hydra, full ofBorg support."
    - There is only one ofBorg builder. It can take several hours or days for an ofBorg build to finish for Darwin, if it finishes at all.
    - Hydra builders a greatly understaffed.
    - If Apple follows through on [their announcement to discontinue](https://www.businessinsider.com/apple-macbook-pro-discontinued) x86-based devices, the situation won't improve due to a physical lack of hardware.
- "Most packages work, credible ambition to reach Tier 1 coverage at some point."
    - Tier 1 support is far out of reach.
    - We lack expertise in the greater community to support Darwin.
- "Some ordinary packages are channel blockers on Hydra."
    - Due to Hydra being understaffed, this is a problem (see above).

We are not only lacking CI machines, but also maintainers that can dedicate their time to work on fixing broken Darwin packages.

## Exemplary collection of issues with Darwin

The issues that are constantly encountered in relation to the Darwin platform have a genuine negative impact on the `nixpkgs` development experience. People are forced to deal with these problems even though they have no hardware to test on, lack the proper expertise, and are reluctant when it comes to investing additional time and energy to patch for the failing platform. Demoting Darwin to Tier 3 will allow more developers to refocus their attention on better supported platforms, care less about Darwin issues, and push that burden onto the Darwin maintainers.

An excerpt of these issues are:

- The only way to debug issues without owning a Mac is to run Darwin in a VM, of which the legal situation is unclear.
   - Those licensing requirements are causing friction with our CI setup as well.
- The sandboxing capabilities on MacOS are limited. This results in a special category of test failures only relevant to Darwin. It also prevents us from providing a community builder, because it could not be shared between multiple people that cannot trust each other.
- The MacOS SDK cannot be updated and is stuck on 10.12 (released 2016/09) because Apple does not publish the required sources.
    - https://github.com/NixOS/nixpkgs/issues/101229#issuecomment-938747052
    - It is highly unlikely that we can report bugs to projects with such an outdated and unsupported SDK version
- The MacOS SDK being outdated blocks nixpkgs moving to go 1.17:
    - https://github.com/NixOS/nixpkgs/pull/127519#issuecomment-864926149
    - This will become a growing pain point once more packages become go 1.17-only (tailscale, talosctl, …)
- Multiple Packages were marked as broken, because they require symbols from newer MacOS SDK versions.
    - https://github.com/NixOS/nixpkgs/commit/3ceb5ab5ed0d1fcbe53ef00621f44d61dc524796
    - https://github.com/NixOS/nixpkgs/commit/c9a3ac5d3cb5e910238d01e534d74d5d50e4b6b7
- Curl added a SystemConfiguration dependency for NAT64 support, which introduced a reference loop, requiring a downstream patch to workaround.
    - This blocked updating to more recent curl versions for most of the last release cycle.
    - https://github.com/NixOS/nixpkgs/pull/124502#issuecomment-850834981
- Enabling brotli support by default in curl broke the Darwin stdenv, which draws in a great number of packages.
    - https://github.com/NixOS/nixpkgs/pull/112947
    - https://github.com/NixOS/nixpkgs/pull/115498

# Detailed design
[design]: #detailed-design

- Together with this RFC, `0046-platform-support-tiers.md` will be updated accordingly (simply move `x86_64-darwin` down one section).
- Whatever needs to be done to make Darwin not block any channels anymore (TODO).

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

- Failing tests on `x86_64-darwin` will not block channel advances in case of failures anymore.
- The existing testing infrastructure will remain unchanged. Tests will continue to be run to the extent the infrastructure can provide.

# Drawbacks
[drawbacks]: #drawbacks
 
This will result in developers caring less about things breaking on Darwin. Consequently, the quality of the system will probably degrade for end users. While this is not the intent of this RFC (the intent being to better reflect the actual level of support that the platform has), this side effect is probably inevitable.

# Alternatives
[alternatives]: #alternatives

- Keep the current, unsatisfactory state of things.
- Improve Darwin support to match its declared support tier.
- Abandon the support tier system altogether.
- Add more granular support tiers in a subsequent RFC to augment those specified in [RFC 0046](https://github.com/NixOS/rfcs/blob/master/rfcs/0046-platform-support-tiers.md) to better reflect the currently achievable support for Darwin.

# Unresolved questions
[unresolved]: #unresolved-questions

How should the support tier list be updated? Is it okay to simply edit the RFC 46, or should a new list be appended to this RFC instead?

# Future work
[future]: #future-work

None that we are aware of.
