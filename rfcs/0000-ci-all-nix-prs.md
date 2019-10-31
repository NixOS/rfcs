---
feature: ci-all-nix-prs
start-date: 2019-10-30
author: John Ericson (@Ericson2314)
co-authors: (find a buddy later to help our with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Build all Nix PRs in CI.
Do not merge any PR until it passes CI.

# Motivation
[motivation]: #motivation

There is a (famous blog post)[blog-post] that everyone is sloppy and doing CI wrong.
This isn't just bad for releasing software smoothly, but also increases the burden for new contributors because it is harder to judge the correctness of PRs at a glance (is it broken? Did I break it?).
I personally find it harder to contribute, I have to worry about double checking all my work on platforms I don't have as-easy access to, like Darwin.

We cannot yet do this for all of Nixpkgs, sadly, due to resource limits.
But, there is no reason we cannot do it for Nix itself.

# Detailed design
[design]: #detailed-design

Set up Hydra declarative jobsets to build all Nix PRs.
Those with merge access should be instructed not to merge a PR until CI passes.
Merge master into PRs or rebase before merge as a crude stop-gap to avoid master becoming an untested tree due to a merge commit.

If Hydra gains the ability to keep master always working obviating the manual steps above beyond the PR jobs, use that ability.

If a new CI is used, ensure that is also keeps master in an always-building state.

# Drawbacks
[drawbacks]: #drawbacks

More process to follow.

# Alternatives
[alternatives]: #alternatives

Merely build all PRs, and maintainers are still allowed to merge broken ones / not take care to avoid untested merge commits.

# Unresolved questions
[unresolved]: #unresolved-questions

Nothing.

# Future work
[future]: #future-work

- Remove the manual parts of this process.

- Also apply to other smaller official repos, like `cabal2nix`.

[blog-post]: https://graydon2.dreamwidth.org/1597.html
