---
feature: nixos-freeze-dates
start-date: 2021-01-17
author: Jonathan Ringer (@jonringer)
co-authors:
related-issues: [NixOS release schedule](https://github.com/NixOS/rfcs/pull/80)
---

# Summary
[summary]: #summary

To further minimize the amount of risk going into a NixOS release, I propose
to set freeze dates regarding changes to critical packages being merged to
staging. In addition, I also propose to stabilize the release on master
instead of the release branch, thus avoiding the need to backport every pull
request, and take advantage of the stabilization that unstable normally
receives.

# Motivation
[motivation]: #motivation

The motivation for putting in place freeze dates is to avoid the common practice
of forcing many, largely-untested, commits into master before branch-off. This
happened for the 20.09 release in which ~640 staging commits were pushed through in the 
days leading up to the branch off (https://github.com/NixOS/nixpkgs/pull/95492, 
https://github.com/NixOS/nixpkgs/pull/96280, https://github.com/NixOS/nixpkgs/pull/96437,
https://github.com/NixOS/nixpkgs/pull/97146). The last PR included a release blocker
fix (introduced in [one of the mentioned PRs](https://github.com/NixOS/nixpkgs/pull/96437))
which delayed the branch-off from 4 Sept 2020 to 7 Sept 2020, and ZHF had to
be delayed another day to get a semi-accurate hydra build status. The systemd bump
was also largely responsible delaying the release until after the scheduled release date
where basic login features in plasma [weren't restored until Oct 5th, a week after the planned release date](https://github.com/NixOS/nixpkgs/pull/99629)
and a backlog of other plasma related issues [weren't resolved until Oct 19th, a month after the planned release date](https://github.com/NixOS/nixpkgs/pull/101078).
This is not to discredit any individual, but demonstrate that certain packages
have many dimensions of compatibility which need a longer time to stabilize
on unstable before being included in a release.

## Core changes

Definitions:
 - Initial "critical packages": `stdenv.cc`,`binutils`, `systemd`
 - ZHF: Zero Hydra Failures
   - Period in which packages are stabilized in preparation of a release.

Staging-next iterations will change to one week.

The below table is sanitized of events not relating to merge criteria, staging events, or ZHF.

| Weeks from Release | Events |
| --- | --- |
| -8 Weeks | Gnome, Plasma(YY.11) packaging begins |
| -6 Weeks | Freeze "critical packages" |
| -4 Weeks | Freeze staging, allow only fixes and Desktop Manager changes |
| -3 Weeks | (Day before ZHF) merge staging-next, prep for ZHF |
| -3 Weeks | Begin ZHF on master branch |
| -3 Weeks | Strong emphasis on minimizing regressions in master PRs |
| -2 Weeks | Merge first staging-next fixes, begin second staging-next fix cycle |
| -2 Weeks | Unfreeze staging, allow for normal staging workflow (staging-next remains fixes only) |
| -2 Weeks | Unfreeze "critical packages" changes |
| -1 Weeks | Merge second staging-next fix cycle |
| -1 Weeks | Perform Branch-off, create release channels, create related tags |
| -1 Weeks | ZHF transitions to "backporting" workflow |
| -1 Weeks | Prepare for release, finish remaining issues |
| 0 Weeks | Release! |
| 0 Weeks | ZHF Ends |

Actual release schedule may adjust dates slightly due to unforeseen events.

Release team will retain the right to refine what constitutes "critical packages", as this may
change over time, and will likely not warrant an RFC to caputre changes.

# Drawbacks
[drawbacks]: #drawbacks

Normal staging development is disrupted for two weeks. (1 normal iteration)
Changes to "critical packages" may have to wait for a month to be merged into staging.
Master development is be uninterrupted, assuming all merges don't introduce new regressions.

# Alternatives
[alternatives]: #alternatives

## Maintain the status quo regarding release dates

Continue with cramming staging changes right before branch-off, keeping
a significant amount of stabilization work and risk before a release, and likely
continuing the trend of delayed releases.

# Future work
[future]: #future-work

- Update [release wiki to reflect changes](https://github.com/NixOS/release-wiki)
- Inform community about changes (Discourse).

