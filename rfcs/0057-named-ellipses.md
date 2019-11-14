---
feature: Named Ellipses OR function argument consistency
start-date: 2019-11-14
author: deliciouslytyped
co-authors: none
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues:
  Named Ellipses - https://github.com/NixOS/nix/issues/2998
---

# Summary
[summary]: #summary

It should be possible to bind ellipses to a name in a function argument definitions like `{ a, ...@extra }: null`, and `{ a, extra@... }: null`. This makes intuitive sense, and would remove the need for a lot of uses of `removeAttrs` that really just want to refer to the contents of ellipses.

TODO: The latter point should be substantiated.

# Detailed design
[design]: #detailed-design

`{...@extraargs}: extraargs` should yield as an attrset the extra arguments "in" `...`.

# Drawbacks
[drawbacks]: #drawbacks
None? This implements syntax that would not have worked before and so in theory shouldn't cause breakage in the Nix ecosystem. [Citation Needed]

# Alternatives
[alternatives]: #alternatives
Not doing this would not have any major impact besides not making nix and nixpkgs nicer to use.

# Unresolved questions
[unresolved]: #unresolved-questions
Should scope of this be expanded to binding any function argument to new names - for consistency, even though that might be considered redundant?
