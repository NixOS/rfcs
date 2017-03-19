---
feature: replace-unicode-quotes
start-date: 2017-03-19
author: layus
co-authors: (find a buddy later to help our with the RFC)
related-issues:
    - https://github.com/NixOS/nix/pull/1140
    - https://github.com/NixOS/nix/issues/915
    - https://github.com/NixOS/nix/pull/910
---

# Summary
[summary]: #summary

Nix uses unicode glyphs to quote strings and paths in its output.
This RFC proposes to use only ASCII `"` and `'` for quoting purposes in strings
printed during evaluation.

# Motivation
[motivation]: #motivation

There are three main reasons for this change.

1. _Correctness_: By removing preventively these characters, we will not have
   to track the triggered issues separately. Unicode interact badly with
   variable interpolation in bash and will create more issues if we keep them.
2. _Compatibility_: Most terminal emulators do not recognise unicode quotes as
   string delimiters. This makes string copy/paste from the terminal clumsy.
3. _Consistency_: As some quotes were replaced for compatibility with shells and
   terminal emulators, we end up wit a mix of both styles.

# Detailed design
[design]: #detailed-design

Implementing this requires to replace every unicode quote glyph by an ASCII
character. This change needs only happen in strings intended to be part of
build logs or otherwise printed in the console. The automated change should not
alter comments nor documentation.

After the change, using ASCII quotes should be enforced to maintain
consistency. This rule should be added to the dev manuals of nix and nixpkgs.

# Drawbacks
[drawbacks]: #drawbacks

Snippets of nix output in documentation and blogs will be out of sync (their
quotes would not match the real printed output).
Also, ASCII quotes are less aesthetic.

# Alternatives
[alternatives]: #alternatives

No alternative have been considered.
There is always the option of keeping everything as is.

# Unresolved questions
[unresolved]: #unresolved-questions

Should we also force ASCII quotes in pkgs meta fields and nixos optiosn decription ?
These are displayed on the web (see https://nixos.org/nixos/options.html) and in the console
with nixos-option.
I think we should leave these as-is for now.


