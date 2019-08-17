---
feature: merge-bot-for-maintainers
start-date: 2019-08-17
author: Frederik Rietdijk
co-authors: (find a buddy later to help our with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Allow maintainers of packages and modules in Nixpkgs to submit their own changes
when certain criteria are fullfilled.

# Motivation
[motivation]: #motivation

Nixpkgs is growing. More people should be able to help out with merging changes.
Merging changes typically requires write permission, however, that gives the
possibility for Nixpkgs-wide changes and decreases the security.

By allowing maintainers of packages and modules to submit their own changes the
load on members of the @nixpkgs-committers that have write permission group is
reduced.

# Detailed design
[design]: #detailed-design

Maintainers of packages and modules will be able to submit their own changes
when the following criteria are met:
1. The label `11.by: package-maintainer` is set by @grahamcofborg
2. The packages/modules are not new.
3. All packages/modules affected need to be maintained by the maintainer.

When these conditions are met the maintainer can write

    @grahamcofborg merge

Note that also another bot could be used than @grahamcofborg.

Criteria 1) is to be met to ensure that it is indeed the maintainer that wants
to submit the changeset. It is important that the label is adjusted with the
requirement set in criteria 3), that is, that all affected derivations, so also
reverse dependencies, are to be maintained by the maintainer. This is to ensure
that maintainers cannot make changes elsewhere in the tree and be permitted to
submit them because they have also made a change in an expression they own. This
also means that this process nearly only applies to leaf packages. Criteria 2)
exists to ensure that at least the initial expression was reviewed by a member
of @nixpkgs-maintainers.

# Drawbacks
[drawbacks]: #drawbacks

There are major concers regarding security. First of all, if e.g. due to a bug
in @grahamcofborg it sets the required label by accident, then that could open
up Nixpkgs for other unauthorized changes.

Second, after the initial expression was approved and submitted, the new
maintainer is free to make whatever changes in that attribute and submit them
without reviewing, making it trivial to include malicious content.
Members of @nixpkgs-committers can also do this, however, membership of that
group is not given directly to anybody.

# Alternatives
[alternatives]: #alternatives

1. Hand out write permissions more freely. More people will be able to make changes anymore.
2. Reduce the size and scope of Nixpkgs. Include only core packages and function in Nixpkgs or
a Nixpkgs-core and use e.g. Flakes for leaf packages.

# Unresolved questions
[unresolved]: #unresolved-questions

Should the possibility of merging PR's be part of @grahamcofborg or should it be a
separate bot.

# Future work
[future]: #future-work

1. The algorithm for deciding whether the label should be set would have to be changed as it is now stricter.
2. Merge functionality would have to be implemented in @grahamcofborg or another bot.