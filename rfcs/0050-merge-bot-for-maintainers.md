---
feature: merge-bot-for-maintainers
start-date: 2019-08-17
author: Frederik Rietdijk
co-authors: (find a buddy later to help our with the RFC)
shepherd-team: @aanderse, @globin, @grahamc, @worldofpeace
shepherd-leader: @globin
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Allow maintainers of packages in Nixpkgs to submit their own changes
when a trusted reviewer reviewed their change and other criteria are fullfilled.
When the criteria are fullfilled a change can be merged using

    @grahamcofborg merge

# Motivation
[motivation]: #motivation

Nixpkgs is growing. Community members want to be able and should be able to help out
with merging changes. Merging changes typically requires write permission, however,
that gives the possibility for Nixpkgs-wide changes and decreases the security.

By allowing maintainers of packages and modules to submit their own changes the
load on members of the @nixpkgs-committers that have write permission group is
reduced.

A new group, trusted reviewers, is introduced to help out with the reviewing
process to improve the reviewing culture by introducing peer-review and making
the whole process more inclusive.

# Detailed design
[design]: #detailed-design

Community members will be able to submit their changes using a bot after a
positive review of both the maintainers of the expressions they modify
("relevant maintainers") as well that of a trusted reviewer.

## Scope

- Only packages are considered. Modules are excluded because of how intertwined modules are.
- Only `master` and `staging` branches are considered. In the future release branches may be included as well.

## Trusted reviewers

A new trusted reviewers group is introduced, called @nixpkgs-reviewers. This
group is permission-wise positioned between @nixpkgs-maintainers and
@nixpkgs-committers and can be considered a stepping stone towards becoming a
member of @nixpkgs-committers and obtaining push permission.

This new group is initially implemented with GitHub Teams. In the future this
may be done differently, e.g. when narrower control lists are pursued.

## Merge bot behavior

The bot @grahamcofborg will support two new commands, `@grahamcofborg merge` and
`@grahamcofborg stop` for respectively merging a PR and aborting a PR merge.

### Merging a change

The following requirements need to be fullfilled for the bot to be able to merge:
1. Target branch of PR is `master` or `staging`.
2. Review is green. A review is green when the relevant maintainers gave a positive review as well as a member of the trusted reviewers. Alternatively, a positive review of a committer is needed.
3. Build is green. This always applies, even when a committer gave a positive review. Furthermore, the builds of all supported platforms need to pass.
4. PR is at the same revision as when the `@ofborg merge` request was done.
5. Amount of rebuilds is smaller than 500 packages unless a committer gave a positive review. That way large rebuilds are supported.

In the above "relevant maintainers" corresponds to one maintainer for each of
the modified expressions.

When an expression is modified that has no maintainer, then a committer needs to
approve. This should hopefully also lead to community members taking up a maintainer
role.

### Aborting a merge

A merge can be aborted when an `@ofborg stop` is issued by any of:
1. PR author
2. Maintainer of any of the modified expressions
3. Trusted reviewer
4. Committer

Note a committer can always force a merge by performing the merge without the bot.

### Flow chart

TODO

# Drawbacks
[drawbacks]: #drawbacks

There are major concers regarding security. First of all, @grahamcofborg will
have permission to push which can make it a more interesting target, resulting
in potentially unauthorized changes to Nixpkgs.


# Alternatives
[alternatives]: #alternatives

1. Hand out write permissions more freely. More people will be able to make changes anymore.
2. Reduce the size and scope of Nixpkgs. Include only core packages and function in Nixpkgs or
a Nixpkgs-core and use e.g. Flakes for leaf packages.

# Unresolved questions
[unresolved]: #unresolved-questions

Should the possibility of merging PR's be part of @grahamcofborg or should it be a
separate bot. For now it is assumed it would be part of @grahamcofborg.

# Future work
[future]: #future-work

1. Merge functionality would have to be implemented in @grahamcofborg or another bot.
