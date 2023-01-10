---
feature: rfc-repos
start-date: 2022-01-10
author: Silvan Mosberger
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Develop and discuss RFCs in repositories instead of a pull request.

# Motivation
[motivation]: #motivation

RFC discussions are currently held in single pull requests on the [rfcs](https://github.com/NixOS/rfcs/pulls) repository.
Due to GitHub's limitations on pull requests, this quickly becomes unmanageable.
The most prominent example of this is [the Flakes RFC](https://github.com/NixOS/rfcs/pull/49) with over 500 comments.

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
When the FCP passes, the repositories contents are committed to the [rfcs](https://github.com/NixOS/rfcs) repository by the [RFC steering committee](https://github.com/NixOS/rfcs#rfc-steering-committee) via a pull request that closes the original issue.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions


# Drawbacks
[drawbacks]: #drawbacks


# Alternatives
[alternatives]: #alternatives


# Unresolved questions
[unresolved]: #unresolved-questions


# Future work
[future]: #future-work

