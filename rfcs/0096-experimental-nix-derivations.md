---
feature: experimental-nix-derivations
start-date: 2021-06-25
author: gytis-ivaskevicius
co-authors:
shepherd-team: edolstra, blaggacao, maljub01, nrdxp
shepherd-leader: edolstra
related-issues:
---

# Summary
[summary]: #summary

Add a way for users to use experimental Nix features with improved user-experience
and better communication to the user that they are using an experimental feature.

# Motivation
[motivation]: #motivation

Motivation:
- Revert of (this)[https://github.com/NixOS/nixpkgs/pull/123898].
- Noticed quite a few peeps who were very supportive of [this](https://github.com/NixOS/nixpkgs/pull/120141) PR (which got reverted).
- Lack of visibility for the end-users that they are using experimental features.

Expected outcome:
- Improved UX.
- Reduced risk of users using experimental features in production environments.
- Reduced non-bug questions/issues on common support channels.

# Detailed design
[design]: #detailed-design

`nixUnstable` derivation definitions should be updated in such a way so end users would be able to overwrite features with something along the lines of this:
```nix
nixUnstable.override { experimentalFeatures = ["flakes"]; }
```

What's so special about this override:
- Makes specified experimental features enabled by default. (A little similar to [this](https://github.com/NixOS/nixpkgs/pull/120141) PR)
- When using these overwritten derivations warning should be shown.


Warning expected to look something like this:
```
WARNING: You are using experimental Nix features which are up to a subject to change. For more information visit https://nixos.org/xyz
```

A webpage is expected to contain information as such:
- Support channels if any.
- A little rundown of the current state of the feature(s).
- Some "URL dump" kind of wiki page that that would contain a list of links to issues with existing bugs/workarounds/edge-cases.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

If we take Nix flakes as an example:
The additional line to `nix.conf` is not a deal-breaker for anyone who decides to
use Nix Flakes. Even if someone were to do so in a production environment is
likely to get by unnoticed. On another hand, if there is an explicit warning it is
likely to make multiple peeps question their decisions.

# Drawbacks
[drawbacks]: #drawbacks

I can't think of any drawbacks.

# Alternatives
[alternatives]: #alternatives

Not doing this would preserve a lack of visibility. Especially when using projects like [DevOS](https://github.com/divnix/devos) or [flake-utils-plus](https://github.com/gytis-ivaskevicius/flake-utils-plus/)

# Unresolved questions
[unresolved]: #unresolved-questions

How exactly warning should look like?
How exactly `experimentalFeatures` feature flag should be implemented? (Via CLI argument? Env variable? Dynamically generated patch/sed?)

# Future work
[future]: #future-work

Removal/Deprecation of Nix experimental packages on a per case basis.
