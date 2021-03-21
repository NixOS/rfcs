---
feature: nixos-release-stablization
start-date: 2021-01-17
author: Jonathan Ringer (@jonringer)
co-authors:
shepherd-team: @ryantm, @garbas, @Mic92
shepherd-leader: @ryantm
related-issues: [NixOS release schedule](https://github.com/NixOS/rfcs/pull/80)
---

# Summary
[summary]: #summary

To bring more certainty to the release cycle, add short periods where
breaking changes are partially restricted. A list of Release Critical
Packages is defined. Also, move most release stablization work from
the `release` branch to the `master` branch to reduce backports.

# Motivation
[motivation]: #motivation

We want to release on time without herculian efforts. Limited
restrictions to merging breaking changes should avoid the common
practice of forcing many, largely-untested, commits into master before
branch-off.

This happened for the 20.09 release in which ~640 staging
commits were pushed through in the days leading up to the branch off
([#95492](https://github.com/NixOS/nixpkgs/pull/95492),
[#96280](https://github.com/NixOS/nixpkgs/pull/96280),
[#96437](https://github.com/NixOS/nixpkgs/pull/96437),
[#97146](https://github.com/NixOS/nixpkgs/pull/97146)). The last PR included a
release blocker fix (introduced in [one of the mentioned
PRs](https://github.com/NixOS/nixpkgs/pull/96437)) which delayed the
branch-off from 4 Sept 2020 to 7 Sept 2020, and ZHF had to be delayed
another day to get a semi-accurate hydra build status. The systemd
bump was also largely responsible delaying the release until after the
scheduled release date where basic login features in plasma [weren't
restored until Oct 5th, a week after the planned release
date](https://github.com/NixOS/nixpkgs/pull/99629) and a backlog of
other plasma related issues [weren't resolved until Oct 19th, almost a
month after the planned release
date](https://github.com/NixOS/nixpkgs/pull/101078).  This is not to
discredit any individual, but demonstrate that certain packages have
many dimensions of compatibility which need a longer time to stabilize
on unstable before being included in a release.


# Definitions
[definitions]: #definition
- Breaking change
  - A changes that is likely to break downstream.
  - For projects following Semantic Versioning, disallow major version bumps.
- Restricted
  - Breaking changes are disallowed.
  - Breaking changes for security or critical bugs are allowed. (Patching is preferred over updates.)
  - New packages and NixOS modules are welcome.
- Unrestricted
  - Breaking changes are allowed.
  - New packages and NixOS modules are welcome.
- ZHF: Zero Hydra Failures
  - Period in which packages are stabilized in preparation of a release.

# Changes

## Release Critical Packages

A list of Release Critical Packages will be maintained in the nixpkgs
manual.  Release Critical Packages are important packages which have
many dimensions of build or runtime behavior. Generally these will be
packages which are a part of `stdenv`, or bootstrapping a system
(e.g. systemd). The Release Managers are empowered to decide which
packages are Release Critical Packages without additional RFCs.

Initially these will be `stdenv.cc`,`binutils`, and `systemd`.

## Restriction Timeline

This timeline represents when certain branches and packages will be
restricted. It is not a complete timeline of all release activities.
The actual timeline will still be determined by the Release Managers
and may be adjusted as needed. The current position in the timeline
will be communicated on Discourse.

| Weeks from Release | Branches Affected | Events |
| --- | --- | --- |
| -8 Weeks | | Gnome and Plasma(YY.11) packaging begins |
| -6 Weeks | `staging-next`, `staging` | Restrict breaking changes to Release Critical Packages |
| -4 Weeks | `staging-next`, `staging` | Restrict all breaking changes: allow only non-breaking updates and Desktop Manager changes |
| -3 Weeks | `master` | (Day before ZHF) merge in `staging-next`, prep for ZHF |
| -3 Weeks | `master` | Begin ZHF |
| -3 Weeks | `master` | Focus on minimizing regressions in PRs |
| -2 Weeks | `master` | Merge first `staging-next` fixes; begin second `staging-next` fix cycle |
| -2 Weeks | `staging` | Unrestrict all breaking changes; new changes will not be present in `master` before branch-off |
| -1 Weeks | `master` | Merge second `staging-next` fix cycle |
| -1 Weeks | `staging-next` | Unrestrict all breaking changes; new changes will not be present in `master` before branch-off |
| -1 Weeks | `master`, `release` | Perform Branch-off, create release channels, create new beta / unstable tags |
| -1 Weeks | `master`, `release` | ZHF transitions to "backporting" workflow |
| -1 Weeks | `release` | Prepare for release, finish remaining issues |
| 0 Weeks | `release` | Release! |
| 0 Weeks | | ZHF Ends |

# Drawbacks
[drawbacks]: #drawbacks

Breaking changes to Release Critical Packages will have to wait a
maximum of 4 weeks to be merged into `staging`. Other breaking changes
will have to wait a maximum of 2 weeks to be merged into
`staging`. Staging development will have to follow a faster paced
development cycle during the release timeline. Breaking changes to
Release Critical Packages cannot be merged into `master` for 8 weeks,
but this typically isn't done anyway, so typical `master` development
will be uninterrupted.

# Alternatives
[alternatives]: #alternatives

## Maintain the status quo regarding release dates

Continue with cramming staging changes right before branch-off,
keeping a significant amount of stabilization work and risk before a
release, and likely continuing the trend of delayed releases.

# Future work
[future]: #future-work

- Update [release wiki to reflect changes](https://github.com/NixOS/release-wiki)
- Inform community about changes (Discourse).
