---
feature: Selective auto-merge on bot upgrades
start-date: 2022-07-07
author: superherointj
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Introduce a `meta.autoMerge` attribute to packages to allow committers to delegate merge rights to package maintainers for bot auto updates.

# Motivation
[motivation]: #motivation

* Reduce pending PRs for review and merge in nixpkgs.
* Save reviewers and commiters time.
* Speed up package upgrades.
* Motivate reviewers into becoming maintainers and reviewing PRs.

# Detailed design
[design]: #detailed-design

Add a new `meta.autoMerge` package attribute with type `bool` defaulting to `false`. To be documented in Nixpkgs manual.

Maintainer adds `auto-merge` label to PR which triggers GitHub Actions to enforce rules and merge.

Rules are:
1) `@r-ryantm` is PR's author.
2) Package `meta.autoMerge` attribute is enabled.
3) All CI checks passed.
4) Package maintainer has approved PR.

Due maintainers being able to add labels in GitHub, labels are untrusted and are only used to trigger GitHub Actions.
An extra check of the 4 conditions (without using labels) is necessary in GitHub Actions before merge can happen.

The appropriateness of setting `meta.autoMerge` is left up to committers. Commiters have to consider to whom and to which package is being granted auto-merge permission.

# Drawbacks
[drawbacks]: #drawbacks

* Reduced trustworthiness.
* Security issues:
  - Possible failures in the GitHub Action code used to enforce rules and merge.

# Alternatives
[alternatives]: #alternatives

* https://github.com/NixOS/rfcs/pull/50/

# Unresolved questions
[unresolved]: #unresolved-questions

* Reduced trustworthiness.
* Security risks.
