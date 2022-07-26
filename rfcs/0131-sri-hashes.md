---
feature: sri-hashes
start-date: 2022-07-25
author: Winter
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Use SRI hashes and the `hash` parameter for fetchers.

# Motivation
[motivation]: #motivation

Currently in Nixpkgs, the hash formats that are used in parameters to fetchers range from SRI and base-32 (the most common ones) to hex. In addition to this, packages use the algorithm-specific arguments (`sha256`, `sha512`, etc.) or the generic `hash` argument at random. This creates inconsistencies that we'd rather not have.

# Detailed design
[design]: #detailed-design

1. Require all new packages to use SRI hashes + `hash` when possible
2. Do a treewide migration for the majority of cases (single fetcher in `src`, using a fetcher that supports `hash` and SRI hashes (`fetchFromGitHub`, `fetchurl`, etc.)) to `hash` + SRI hashes

# Drawbacks
[drawbacks]: #drawbacks

None at this time.

# Alternatives
[alternatives]: #alternatives

- Do nothing: further inconsistencies will continue to be introduced

# Unresolved questions
[unresolved]: #unresolved-questions

- How can we do the treewide migration efficently?
  - Text replacement for the majority of cases, with an AST-based solution for others?
- Do we want to eventually deprecate the use of `sha256`, `sha512`, etc. in fetchers that support SRI hashes, leading to their eventual removal?
  - This would require updating every script that uses these arguments, and would cause breakage for any usage of them out-of-tree; we'd need to weigh the benefits of this
- Is `hash` the correct name to use for the argument?
  - Nix builtins use `narHash`

# Future work
[future]: #future-work

Currently none.
