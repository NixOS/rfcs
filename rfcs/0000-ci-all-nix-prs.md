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

There is a [famous blog post](blog-post) about how everyone is sloppy and doing CI wrong.
This isn't just bad for releasing software smoothly, but also increases the burden for new contributors because it is harder to judge the correctness of PRs at a glance (is it broken? Did I break it?).
I personally find it harder to contribute, I have to worry about double checking all my work on platforms I don't have as-easy access to, like Darwin.

We cannot yet do this for all of Nixpkgs, sadly, due to resource limits.
But, there is no reason we cannot do it for Nix itself.

# Detailed design
[design]: #detailed-design

Optional first step: we can set up OfBorg to build all PRs.

Set up Hydra declarative jobsets to build all approved Nix PRs.
This might involve extending Hydra somewhat.
Those with merge access should be instructed not to merge a PR until CI passes.
Merge master into PRs or rebase before merge as a crude stop-gap to avoid master becoming an untested tree due to a merge commit.

If Hydra gains the ability to keep master always working obviating the manual steps above beyond the PR jobs, use that ability.

If a new CI is used, ensure that is also keeps master in an always-building state.

# Drawbacks
[drawbacks]: #drawbacks

More process to follow.

# Alternatives
[alternatives]: #alternatives

1. Merely build all PRs with OfBorg.
   This is still far better than the status quo, but has the disadvantage that master must still be rebuilt as OfBorg and Hydra do not share a cache.

2. Merely build all approved PRs, and maintainers are still allowed to merge broken ones / not take care to avoid untested merge commits.
   This is better still, but master could still be broken, even if only working branches are merged due to the merges not being tested.

3. Build all PRs with Hydra.
   This was my original proposal, which has the benefit of not requiring new Hydra features.
   Unfortunately there is a slight security risk.
   While we generally trust Nix sandboxing---Nixpkgs PR reviewers do not do a full security audit or anything close---fixed output derivations have no network sandboxing.
   This means a mischievous PR could is free to do some work and communicate its result to the outside world, rather than have it be lost for ever.
   So yes, people could mine crypto-currency or something from within their filesystem-but-not-network sandbox.
   Worse, conceivably through some side channel that Linux namespaces do not guard, a rouge fixed-output derivation could try to slowly exfiltrate secrets or something.

   Only building approved PRs is a crude, but probably adequate workaround.
   A rogue fixed-output derivation should be much harder to hide than arbitrary malicious code, especially as the Nix code of any PR should be understandable to our reviewers, and much smaller than the C++.

# Unresolved questions
[unresolved]: #unresolved-questions

Nothing.

# Future work
[future]: #future-work

- Remove the manual parts of the "it's not rocket science" process.
  This means that either one can only merge when it would be a "fast forward" merge, or CI does the merging for your.
  This enforces that the tip of master is always building and cached, even as it is pushed to a new commit, race free.

- Also apply process to other smaller official repos, like `cabal2nix`.

[blog-post]: https://graydon2.dreamwidth.org/1597.html
