---
feature: nixpkgs-breaking-change-policy
start-date: 2020-09-24
author: Kevin Cox
co-authors: (TBD)
shepherd-team: @blaggacao, @jonringer, @nrdxp
shepherd-leader: @blaggacao
related-issues: (TBD)
---

# Summary

This defines a policy for how to manage nixpkgs changes that break dependent
derivations or tests. It specifies timeframes and procedures so that
maintainers of dependencies and dependents can know what to expect from each
other when making breaking changes.

While this policy should be followed as much as possible once accepted it is
primarily focused on getting agreement such that tools can be built that make
implementing this policy very easy. See the [Future Work section](#future-work)
for examples of the tools that will be built.

The direct intended result of this RFC is:

- Maintainers of dependencies have a clear framework for handling changes that
  break dependants.
- Maintainers of dependants have a clear framework for how dependency breacking
  changes will be handled.
- NixOS channels will very rarely (ideally never) stall due to build or test
  failures.

This document is only focused on changes to derivation builds and tests it
**does not** aim to make any opinion on changes that can break user machines or
configurations. (While this is an interesting topic it is harder to put
concrete rules on due to the difficulty of identifying these breakages. In
order to be covered by this policy please but tests on your packages.)

# Motivation

Right now the procedure for making breaking changes varies widely by maintainer
and is largely tribal knowledge. There are a wide variety of approaches ranging
from:

- After testing to confirm that a change is correct, merge and notify
  dependents that they need to update their packages.
- Merge to `staging`, notify dependents then eventually merge to `master`.
- Gather a large number of fixes in the PR branch then merge to `staging` or
  `master` once most or all dependencies are fixed.

This adhoc nature has a number of downsides:

- Change authors need to put effort into deciding how to handle each particular
  change.
- Maintainers of dependant packages don't know what to expect and have a hard
  time keeping up with upstream breakages.
- Merges to `master` or `staging` can result in broken channels which block all
  updates including security updates.

This aims to provide a uniform approach so that everyone involved knows what to
expect and to allow further workflows including automation to be build on top
of these procedures.

## Past Discussions

https://discourse.nixos.org/t/please-fix-all-packages-which-were-broken-by-the-qt-wrapping-changes/6444

# Detailed design

## Goals

The following procedure will be used for making breaking changes. It has a few
primary goals:

- Avoid putting more burden than necessary on the dependency maintainer. If the
  maintainers of core derivations face toil proportionally to the number of
  transitive dependencies they will quickly become overloaded. These
  maintainers are arguably the most critical to Nixpkgs and  their load needs
  to be kept manageable.
- Avoid unnecessarily breaking packages for any period of time. There are a
  number of users on the `*-unstable` channels and it is annoying if packages
  in their configuration get broken.
- Avoid breaking the `master` branch as much as possible. The `master` branch
  is used by the `*-unstable` channels and breaking this branch means that no
  updates can be pushed. This includes critical security updates as well as
  regular feature updates.

## Procedure

The target branch for a merge is not affected by this policy. It will be
picked, as it is today, according to
https://nixos.org/manual/nixpkgs/stable/#submitting-changes-commit-policy.

1. The maintainer will prepare a PR with their intended changes.
2. The maintainer should test a sample of dependent derivations to ensure that
their change is not unnecessarily or unintentionally breaking. (Example: Ensure
that a critical output file was not forgotten) Note that sometimes it **is**
necessary to break all dependent packages, and the maintainer is not required
to avoid this.
    1. A sample of at least 100 packages or 3h of build time is recommend as a guideline.
    2. The sample should include as many `passthru.tests` tests as is feasible.
3. The maintainer will get the PR reviewed and approved.
    1. It is **recommended but not required** to have some maintainers of
    dependent packages involved in the review to review if the breakage is
    justified.
4. The maintainer will contact the maintainers of all dependent, broken
packages (herein called sub-maintainers).
    1. The sub-maintainers will be provided a link to the PR with the breaking
    changes as well as any context that will help them resolve the breakages.
    2. The sub-maintainers are expected to update the derivations that they
    maintain within 7 days.
        1. These changes should be merged to the target branch following the regular
        nixpkgs PR process if they are backwards compatible. Otherwise they
        will be merged into the branch of the breaking PR.
5. The maintainer must provide a grace period of at least 7 days from when the
sub-maintainers were notified.
6. The maintainer must merge the target branch into their PR branch.
7. The maintainer must mark all still-broken packages as
[broken](https://nixos.org/manual/nixpkgs/stable/#sec-standard-meta-attributes).
8. The maintainer can now merge to the target branch.

This procedure should not result in a failing channel build in the target
branch at any point. In particular NixOS channel constituents are considered
blocking and are an exception to the 7 day breakage rule.

# Drawbacks

This delays the merge of "core" derivations as the author needs to wait for
sub-packages to be tested and possibly fixed up to the 7 day threshold.

# Alternatives

## Shorter grace period

A shorter grace period allows maintainers to move more quickly but requires
maintainers of defendant derivations to jump to action quickly which is not
always possible for volunteer driven work. For example if a maintainer is on
vacation they can't be expected to respond in a couple of days.

## Longer grace period

A longer grace period would give derivation maintainers more time to react to
changes in dependencies and provide more time to search for replacement
maintainers if the original maintainer has abandoned the derivation. The 7 day
number was mostly arbitrary and can easily be changed in the future. A longer
grace period would also result in more packages being fixed before the breaking
change is shipped, which results in less breakage for end-users.

# Unresolved questions

None.

# Future work
- Create a tool for automatically notifying maintainers of broken dependents
- Create a tool for automatically marking broken packages as broken.
- [This is a milestone on the way to implemented a queue-based merge process
  for nixpkgs.](https://paper.dropbox.com/doc/MTSY8xKH6y1xDEwavyDNW)
