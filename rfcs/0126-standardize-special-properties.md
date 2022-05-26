---
feature: standardize-special-properties
start-date: 2022-05-26
author: Anselm Schüler
co-authors: None
shepherd-team: None
shepherd-leader: None
related-issues: None
---

# Summary
[summary]: #summary

Rename attrset attribute names treated specially by Nix to start with a double underscore.
Add a builtin function `guardSpecial` that returns `null` for double underscore prefixed strings.

# Motivation
[motivation]: #motivation

Nix treats many attributes specially with unique behaviours. Some of these are prefixed with double underscores to disambiguate them from everything else. But some aren’t: `recurseForDerivations` isn’t, `type`, when set to `"derivation"`, changes visual output.

It would also be a good idea to avoid accidentally using reserved special attribute names. Therefore I suggest `guardSpecial` that can be used in dynamic attribute names to avoid this.

# Detailed design
[design]: #detailed-design

Properties treated specially by the Nix tools and Nix language are renamed to start with a double underscore. Instances where this is not necessary are `__functor` and `__toString`. `recurseForDerivations` is renamed `__recurseForDerivations` and `type` is renamed `__type`.

A new builtin function is introduced, `builtins.guardSpecial`.
If called on a string, it returns the string if it does not start with a double underscore, and `null` otherwise. This can be used by semantically charged non-generic functions that update attrs dynamically to avoid unwanted interactions.

Nixpkgs & Nix need to be updated to reflect this. Therefore, it may be advisable to have a grace period during which unprefixed special properties are still supported, but warn.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

```nix
rec {
  set-val-to-null = k: attrs: attrs // {
    ${guardSpecial k} = null;
  };
  x = set-val-to-null "__functor" { __functor = _: _: { }; };
  y = set-val-to-null "y" { __functor = _: _: { }; };
}
```
evaluates to
```nix
{
  set-val-to-null = «lambda»;
  x = { __functor = «lambda»; };
  y = { y = null; __functor = «lambda»; };
}
```

# Drawbacks
[drawbacks]: #drawbacks

- This change is backwards-incompatible
- This requires judging if certain properties count as special attributes

# Alternatives
[alternatives]: #alternatives

- `guardSpecial` could be introduced on its own, thereby complicating its implementation
- These could be left alone

# Unresolved questions
[unresolved]: #unresolved-questions

I honestly don’t have a full list of these special names, I only listed the ones I know about.

It’s also unclear what exactly counts. I think attrsets passed to functions as de-facto named arguments shouldn’t count (e.g. for `derivation`). You could even argue the outputs of `listToAttrs` should be prefixed!

The name of `guardSpecial` might need some work.

# Future work
[future]: #future-work

This eases introduction of any future special names.

It can also be assumed the implementation of `guardSpecial` won’t need to be updated if this standard naming convention is adhered to.
