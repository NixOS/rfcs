---
feature: Nix release schedule
start-date: 2021-09-23
author: Eelco Dolstra
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: "@Ericson2314, @regnat, @Ma27, @tomberek"
shepherd-leader: "@tomberek"
related-issues: N/A
---

# Summary
[summary]: #summary

Do a new Nix release every 6 weeks.

# Motivation
[motivation]: #motivation

The last major Nix release, 2.3, came out in September 2019. Since
then, there has been a huge amount of work on the Nix master branch,
including major improvements to the new command line interface and new
experimental features such as flakes, the content-addressable Nix
store, and recursive Nix. This forces many users to use unstable Nix
releases, which is undesirable.

In the future, we should avoid having such long gaps between releases,
since it’s bad for both contributors and users that there is an
unbounded amount of time before a new feature shows up in a stable
release. The thing that has historically caused long gaps between Nix
releases is new experimental features landing in master that we
weren’t quite sure about, and doing a new release meant having to
support these features indefinitely. However, Nix 2.4 introduces an
experimental-features setting that enables us to add such features in
a way that they can be changed or removed, while still getting
feedback from adventurous users. So long as experimental features
don’t cause breakage in stable features, it’s fine to merge them into
master and include them in a new release.

# Detailed design
[design]: #detailed-design

* We do a new Nix release (named 2.5.0, 2.6.0, 3.0.0, ...) every 6
  weeks. The release process is already almost entirely automated so
  this is pretty easy.

* For each major release, we create a maintenance branch (named
  e.g. `2.5-maintenance`) and corresponding Hydra jobset. Patch
  releases (e.g. 2.5.1) are made as needed.

* The master branch should be kept in a releasable state at all
  times. This means that the jobset
  https://hydra.nixos.org/jobset/nix/master should be completely
  green.

* PRs should include release notes, if applicable. (Currently trawling
  through the history to dig up interesting stuff for the release
  notes is the most work in making a new release.) The PR template
  will be updated to reflect this.

# Drawbacks
[drawbacks]: #drawbacks

Infrequent releases give somewhat more stability to users. Users of Nix-stable
have been blissfully isolated from all the code churn on master for
the last two years.

# Alternatives
[alternatives]: #alternatives

Stick to the current release-when-it's-ready non-schedule.

# Previous work

[RFC 0009](https://github.com/NixOS/rfcs/pull/9) proposed a rapid
release policy where releases can be done at any time (e.g. on
request) rather than on a fixed schedule. It wasn't feasible at the
time because we didn't have a notion of experimental features, so we
had to give such features some time to stabilize before doing a new
release.

# Future work
[future]: #future-work

N/A
