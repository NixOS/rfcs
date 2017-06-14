---
feature: nix-rapid-release
start-date: 2017-04-04
author: Shea Levy
co-authors: John Ericson (@Ericson2314)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Nix master is always release-ready and new releases are cut often.

# Motivation
[motivation]: #motivation

Currently, Nix releases are unpredictable and new features (and, less often, bug fixes) sit on master for a long time before people can rely on them.
Nix 1.12 in particular has a large number of changes that are not generally available yet.
A rapid release policy would allow more users to benefit from the latest greatness while also forcing us to make our improvements to Nix more incremental and unitary and to be more considerate of what we consider merge-ready.

# Detailed design
[design]: #detailed-design

1. Do new non-trivial work in feature branches.

2. If a feature branch may introduce regressions, including performance regressions, ensure they are tested by relevant parties before merge.

3. Release master frequently.
   Community members can make a request for a new release and it's almost always granted.

4. If need arises, start maintenance branches that *only* do bug fixes.

# Drawbacks
[drawbacks]: #drawbacks

This will change developer workflows.
It also may make some large-scale features harder to develop, though in practice when following this policy on other projects it hasn't seemed much of an issue.

# Alternatives
[alternatives]: #alternatives

Status quo, mostly.
We could also switch to a more up-front planned releases, or merge windows, or time-based releases.

# Unresolved questions
[unresolved]: #unresolved-questions

The steps needed to get 1.12 out.

# Future work
[future]: #future-work

1. Get a new Nix out ASAP.
   Identify the bugs that need fixing and optionally features that absolutely need finishing (or possibly temporary reverting), get people to test, and release it as `2.0.0`.
2. Switch to semver.
