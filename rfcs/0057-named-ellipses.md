---
feature: Named Ellipses
start-date: 2019-11-14
author: deliciouslytyped
co-authors: none
shepherd-team: Eelco Dolstra, Michael Raskin, jD91mZM2
shepherd-leader: Michael Raskin
related-issues:
  Named Ellipses - https://github.com/NixOS/nix/issues/2998
---

# Summary
[summary]: #summary

It should be possible to bind a name to ellipses in a function definition like `{ a, ...@extra }: null`, and `{ a, extra@... }: null`. This makes intuitive sense, and could remove the need for a lot of uses of `removeAttrs` that really just want to refer to the contents of ellipses.

Nixpkgs often gets commits like https://github.com/NixOS/nixpkgs/commit/a50653295df5e2565b4a6a316923f9e939f1945b with code that would be cleaner without the need for extra `removeAttrs`.

# Detailed design
[design]: #detailed-design

The intent of this syntax is for `{...@args}:` to behave as consistent with `{...} @ args:`
 as practical. As both `args @ {…}` and `{…} @ args` forms happen in Nixpkgs, both would be supported for named ellipses, too. 
 
 As `args @ {args}: ` is an error in Nix because of duplicate argument names, so should be `{extra, ...@extra}: `. As `(a @ { ... }: a) {a=1;}` returns `{a=1;}`, so should `({ a @ ... }: a) {a=1;}`. ```

TODO: consider what other languages like Haskell do

# Drawbacks
[drawbacks]: #drawbacks
This increases the amount of syntax Nix has, thus creating some maintenance cost both for Nix itself, and for tools intended to work with Nix syntax (from highlighting to hnix)

# Alternatives
[alternatives]: #alternatives
Not doing this would not have any major impact besides not making Nix and nixpkgs nicer to use.
