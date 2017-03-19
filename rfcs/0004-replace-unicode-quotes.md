---
feature: replace-unicode-quotes
start-date: 2017-03-19
author: layus
co-authors: zimbatm
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
   See "nix installer produces broken output on Darwin"
   https://github.com/NixOS/nix/issues/915.
   and the detailed explanation in https://github.com/NixOS/nix/issues/910.

   As an example, on the following code the shell is treating the 1st UTF-8
   byte of `’` as part of the variable name (which is undefined, thus "").
   This results in `echo ""$'\x80\x99'`

       $ x=y
       $ echo "$x"
       y
       $ echo "$x’" # WTF is going on here!?
       ??

   Also, such quotes should be removed from code snippets in the documentation.
   Otherwise, they cannot be used as is. See
   http://lists.science.uu.nl/pipermail/nix-dev/2010-April/004286.html

2. _Compatibility_: Most terminal emulators do not recognise unicode quotes as
   string delimiters. This makes string copy/paste from the terminal clumsy.

   For example, with a double-click in the following text, gnome-terminal will
   correctly select the derivation path without the quotes, while rxvt-unicode
   and st will select the string with the quotes. The string without quotes
   needs to be tediously edited to be reused anywhere.

   > building path(s) ‘/nix/store/hdlkn4pnc7l79jbawlkvssx1hc7gqmj8-gnum4-1.4.18’

   Some terminals like Eterm seem unable to print these characters correctly.

3. _Consistency_: As some quotes were replaced for compatibility with shells and
   terminal emulators, we end up with a mix of both styles.

See also
 - https://github.com/NixOS/nix/pull/947#r71710959
 - https://github.com/NixOS/nix/pull/1140 (Get rid of unicode quotes)
 - https://github.com/NixOS/nix/commit/b3fc0160618d89bf63ce87ccad27fc68360c9731

# Detailed design
[design]: #detailed-design

Implementing this requires to replace every unicode quote glyph by an ASCII
character. This change needs only happen in strings intended to be part of
build logs or otherwise printed in the console.

The automated change should not alter comments nor documentation, except for
code snippets within that documentation. Neither should it alter derivations
outputs by changing input variables.

After the change, using ASCII quotes should be enforced to maintain consistency.

The change mainly needs to happen in Nix, but nixpkgs should follow for consistency.
For example, https://github.com/NixOS/nixpkgs/blob/c86f05e7ce13e64238960ebf3ee9706142db961b/nixos/modules/tasks/filesystems.nix#L236 should be updated.

# Drawbacks
[drawbacks]: #drawbacks

Snippets of nix output in documentation and blogs will be out of sync (their
quotes would not match the real printed output).
Also, ASCII quotes are less aesthetic.

# Alternatives
[alternatives]: #alternatives

As a decision needs to be take, we could also prefer to keep these nice unicode
glyphs and fix issues as we encounter them.
This also requires to push patches upstream in terminal emulators, and provide
documentation as how to use them safely in shell scripts.

# Unresolved questions
[unresolved]: #unresolved-questions

Should we also force ASCII quotes in pkgs meta fields and nixos options description ?
These are displayed on the web (see https://nixos.org/nixos/options.html) and in the console
with nixos-option.
It would be simpler to consider these as documentation, leaving them as-is.


