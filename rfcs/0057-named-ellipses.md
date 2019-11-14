---
feature: Named Ellipses OR function argument consistency
start-date: (fill me in with today's date, YYYY-MM-DD)
author: deliciouslytyped
co-authors: (find a buddy later to help our with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

It should be possible to bind ellipses to a name in a function argument definitions like `{ a, ...@extra }: null`, and `{ a, extra@... }: null`. This makes intuitive sense, and would remove the need for a lot of uses of `removeAttrs` that really just want to refer to the contents of ellipses.

# Motivation
[motivation]: #motivation
This is pretty simple so it#s redundant with the summary:
- I think it makes sense to be able to refer to "the rest of the arguments" as a first class object
- This should also allow nixing a lot of usages of the `removeAttrs` pattern TODO: substantiate this

# Detailed design
[design]: #detailed-design

Help?

This is the bulk of the RFC. Explain the design in enough detail for somebody
familiar with the ecosystem to understand, and implement.  This should get
into specifics and corner-cases, and include examples of how the feature is
used.

# Drawbacks
[drawbacks]: #drawbacks
None?
This implements syntax that would not have worked before and so in theory shouldn't cause breakage in the Nix ecosystem. [Citation Needed]

# Alternatives
[alternatives]: #alternatives
None?

Not doing this would not have any major impact besides not making nix and nixpkgs nicer to use.

# Unresolved questions
[unresolved]: #unresolved-questions
Should scope of this be expanded to binding any function argument to new names - for consistency, even though that might be considered redundant?


# Future work
[future]: #future-work
None?

# Bibliography
Named ellipses - https://github.com/NixOS/nix/issues/2998
