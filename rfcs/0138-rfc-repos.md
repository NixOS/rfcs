---
feature: rfc-repos
start-date: 2022-01-10
author: Silvan Mosberger
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: @winterqt, @lheckemann 
shepherd-leader: @lheckemann 
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Develop and discuss RFCs in repositories instead of a pull request.

# Motivation
[motivation]: #motivation

RFC discussions are currently held in single pull requests on the [rfcs](https://github.com/NixOS/rfcs/pulls) repository.
- Due to GitHub's limitations on pull requests, this quickly becomes unmanageable.
  The most prominent example of this is [the Flakes RFC](https://github.com/NixOS/rfcs/pull/49) with over 500 comments.
- These PR threads easily get polluted with minor points like typos and wording improvements,
  which are not meaningful to the RFCs contents, but distract from other more important discussions.
- It's easiest to comment at the top-level, without threads,
  especially when there's no relevant line of the diff to comment on for a thread.
  This frequently causes multiple discussions to be interleaved at the top-level.

# Detailed design
[design]: #detailed-design

The RFC process is changed to use repositories to develop and review RFCs instead.
To create a new RFC, an issue on the [rfcs](https://github.com/NixOS/rfcs) repository is opened.
It should contain the following contents describing the process:

> This RFC is developed as the README.md of this repository: https://github.com/$owner/$repo
>
> To review the RFC
> - Open https://github.com/$owner/$repo/blob/master/README.md?plain=1
> - Select the lines you wish to comment on
> - Click the "..." menu on the left
> - Select "Reference in new issue" to open a new issue commenting on those lines
>
> To suggest changes, open a PR against the repository.
>
> All issues and pull requests must be resolved before the FCP can be initiated and completed.
>
> This issue may only be used for RFC meta-discussions, such as shepherd nominations, FCP periods, meeting schedules, etc.

The FCP must be initiated on a specific commit of the repository.
When the FCP passes, the repositories contents are committed to the [rfcs](https://github.com/NixOS/rfcs) repository by the [RFC steering committee](https://github.com/NixOS/rfcs#rfc-steering-committee) with a commit that closes the original issue.

## Workflow to get RFC updates
To get updates for RFC's, instead of subscribing to the PR, one has to watch the repository.

## Repository transfer

Once the RFC is merged, the repository has to be transferred to the NixOS organization under https://github.com/NixOS/rfc-NUMBER. This is to ensure the discussions aren't lost in the future. The repository will then be archived.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions


# Drawbacks
[drawbacks]: #drawbacks
- There's no line-comment view anymore (the "Files changed" tab for PR's), where you can see the entire proposal and all (up-to-date) line comments.
- Commenting on an RFC won't automatically subscribe you to updates anymore.
- Less separation between RFC authors and reviewers with edit suggestions, making it harder to decide who may be a shepherd, since authors can't be shepherds.
- Force pushes won't be visible anymore in the history.
  - Force pushing shouldn't be necessary for RFCs, since they always get squash merged anyways
    - With the previous approach, perhaps the main use case of force pushing was to reduce the PR items to be loaded,
      since commits also count towards the number of items loaded by GitHub.
      This is obviously not necessary anymore.
  - It would be good to protect the main branch for active RFCs,
    which could be done by requiring the RFC repo be moved to the NixOS organisation.

# Alternatives
[alternatives]: #alternatives

## Optional instead of required

Instead of requiring this process, it could be opt-in for "bigger" RFCs.
- (-) It's not clear how to decide whether an RFC should have a repository, there's no way to know how big discussions become in advance.

## Fork branch instead of separate repository

Instead of creating a new repository for each RFC, a new branch in a fork can be created instead.
- (-) Means that a single GitHub user/organization can't have more than one RFC open at a time without mixing of issues/PRs occurring (since GitHub only supports having a single fork of a repository).
  - (+) For time-distinct RFCs it can be worked around by [detaching the old fork](https://support.github.com/request/fork) and creating a new one
- (+) Simplifies the RFC process, since one can just create a PR to upstream it
  - (-) However this may again lead to the original problem of having too long PR discussions
  - (-) It's also confusing about whether a PR is needed

# Unresolved questions
[unresolved]: #unresolved-questions


# Future work
[future]: #future-work

- More RFC automation is possible in the future:
  - Creating repositories for discussing issues created in the rfcs repository
  - Assigning the shepherd team and requiring them to review PRs to the repository
  - Announce FCP when all issues/PRs are closed
  - Commit contents to rfcs repository once FCP passed without any new issues/PRs


