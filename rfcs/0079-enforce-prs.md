---
feature: No more direct pushes to master and release branches
start-date: 2020-09-25
author: Janne Heß <janne@hess.ooo>
co-authors: Matthias Beyer <mail@beyermatthias.de>
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: None
---

# Summary
[summary]: #summary

Enforce usage of Pull Requests for **all** contributions to nixpkgs master and release branches, which implies that these branches do not allow direct pushes anymore.

This implements the four-eyes principle and allows easier change discussion, both before and after the merge, and improves overall security since each Pull Request has to be approved by at least one other person prior to merging.

# Motivation
[motivation]: #motivation

In its current state every [Nixpkgs committer](https://github.com/orgs/NixOS/teams/nixpkgs-committers/members) is able to push arbitrary code to every branch, including master and all release branches.

Pushing to critical branches branches of a software development project is not a good practice in more-than-one-contributor environments.
Security vulnerabilities, breaking changes which are not tested, and regressions are easily introduced this way.
Those issues can been prevented by a proper workflow and tooling that comes with the workflow.

In the last year (as of 2020-09-25), we had
- 19471 commits on the master branch in nixpkgs
- of which 10347 (53.14%) were merges
- of which 9124 (46.85%) were non-merge commits

<small>
(`git log --oneline --since="1 year ago" --first-parent [--[no-]merges] | wc -l`)
</small>

This is an improvement over the previous statistic from 2019-04-13 (where 51.85% commits went directly to master) and proves the point that committers are able to work properly without pushing directly.

By changing our branching workflow to a no-push-to-master workflow, we can achieve more security, stability and even more important: better scalability.

# Detailed design
[design]: #detailed-design

In GitHubs [branch protection](https://github.com/NixOS/nixpkgs/settings/branch_protection_rules) rules, branch protection rules which require pull request reviews, include administrators, forbid force pushes and branch deletions must be created.
There must be rules for:
- master
- nixos-*
- nixpkgs-*
- release-*

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

This only affects nixpkgs committers.
When pushing to a protected branch directly, they get the same message as everyone else and they have to push to an unprotected branch and create a Pull Request from there.

# Drawbacks
[drawbacks]: #drawbacks

It might break the workflow of some committers which are only a small portion of the community.

Also, Pull Requests might take a bit of time before they are approved by somebody else, which should't matter too much since the trust in committers is already very high and their Pull Requests are likely to be merged fast.

# Alternatives
[alternatives]: #alternatives

Do nothing.
This has the downsides mentioned in the motivation and weakens the percieved trust in the project.

# Unresolved questions
[unresolved]: #unresolved-questions

Whose workflows will break?
Why are they not adoptable to a Pull Request workflow?

# Future work
[future]: #future-work

Handle complaints from people who are used to direct pushing.

Maybe increase the number of required approvals in the future. This however requires more active committers or Pull Requests are stalled for long times.
