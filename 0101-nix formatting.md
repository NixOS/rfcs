---
feature: nix_formatting
start-date: 2021-08-17
author: Raphael Megzari
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: Timothy DeHerrera (nrdxp), 0x4A6F
shepherd-leader: Jonas Chevalier (zimbatm)
related-issues: (will contain links to implementation PRs)
---

# Summary

[summary]: #summary

Decide on a recommended automated formatter for nix files in nixpkgs.

# Motivation

[motivation]: #motivation

Prevent debate around how things should be formatted.

# Detailed design

[design]: #detailed-design

The implementation of this RFC should include several parts

- Agree on an automated formatter. [nixpkgs-fmt](https://github.com/nix-community/nixpkgs-fmt) is proposed here.
- If adopted, agree on a schedule to format nixpkgs codebase. Should it be done at once, or on a per package basis.
- Potentially agree on a hook to enforce formatting

# Examples and Interactions

[examples-and-interactions]: #examples-and-interactions

This section is not needed for this RFC.

# Drawbacks

[drawbacks]: #drawbacks

- Having a commit that changes the formatting, can make git blame harder to use. It will need `--ignore-rev` flag.
- Every formatter will have bugs. An example of a bug for nixpkgs-fmt can be found [here](https://github.com/NixOS/nixpkgs/pull/129392)

# Alternatives

[alternatives]: #alternatives

- Alternative formatter [nixfmt](https://github.com/serokell/nixfmt)
- Keep the status quo of not having an official formatter. The danger is that this creates discord within the nix community. On top of fragmented the community it can generate lengthy discussions (which do not advance the eco-system).

# Unresolved questions

[unresolved]: #unresolved-questions

- Not sure how much work there is left on nixpkgs-fmt before most people would consider it ok to use. Not even sure how much it is actually used.
- Are there situation where automated formatting is worse than manual formatting? Do we want to have exceptions to automated formatting?

# Future work

[future]: #future-work

What future work, if any, would be implied or impacted by this feature
without being directly part of the work?
