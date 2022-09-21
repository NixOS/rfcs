---
feature: custom-asserts
start-date: 2022-09-21
author: Anselm Schüler
co-authors: None
shepherd-team: None
shepherd-leader: None
related-issues: None
---

# Summary
[summary]: #summary

Allow users to use attribute sets with a boolean attribute `success` and a string attribute `message` instead of a boolean in `assert …; …` expressions.

# Motivation
[motivation]: #motivation

Since Nix is an untyped language, asserts are often needed to ensure that a function or program works correctly. However, the current assert system is unsuitable for more sophisticated error reporting that aims to inform the user as to what has happened.

Consider a nixpkgs package expression that wants to validate its arguments. Currently, the best way to
provide a custom error message is to use `assert … || throw …; …`.
This method has several disadvantages: Since the assertion itself is not triggered by the error,
the function of the `assert` keyword is reduced to providing an imperative shorthand for `seq`. This also means that by default,
the error location is not printed, and there is no mention of an assert in the error message.
Instead, expressions could use this more natural syntax:

```nix
{ foo, bar }:
assert {
  success = foo || bar;
  message = "At least one of foo or bar must be set";
};
[ foo bar ]
```

Also consider, for instance, this simple type system:

```nix
rec {
  assertType = type: locDescr: value:
    if ! type.check value
    then throw "Value at ${locDescr} was not of type ${type.name}"
    else builtins.traceVerbose "Successfully checked type ${type.name} at ${locDescr}" value;
  assertTypeSeq = type: locDescr: value1: value2:
    builtins.seq (assertType type locDescr value1) value2;
  intType = {
    check = builtins.isInt;
    name = "integer";
  };
  attrsOfType = subType: {
    check = value:
      builtins.isAttrs value
      && builtins.all subType.check (builtins.attrValues value);
    name = "attribute set of ${subType.name}";
  };
}
```

Users of this system would be forced to forgo the convenience of imperative-style `assert …; …` in favor of `seq`-like syntax in order to benefit from improved type errors. With this change, no longer! A variant `isType` function could be declared:

```nix
{
  isType = type: locDescr: value:
    let
      success = type.check value;
      message = if success
        then "Value at ${locDescr} was not of type ${type.name}"
        else "Successfully checked type ${type.name} at ${locDescr}";
    in { inherit success message; };
}
```

Compare three implementations of a function that only takes attribute sets of integers:

```nix
with types;
{
  onlyTakesAttrsOfInt1 = value:
    assertType (attrsOfType intType) "onlyTakesAttrsOfInt1" value;
  onlyTakesAttrsOfInt2 = value:
    assertTypeSeq (attrsOfType intType) "onlyTakesAttrsOfInt1" value value;
  onlyTakesAttrsOfInt3 = value:
    assert isType (attrsOfType intType) "onlyTakesAttrsOfInt1" value;
    value;
}
```

While these implementations get more and more verbose, they also get more and more idiomatic and flexible.

# Detailed design
[design]: #detailed-design

Allow users to use attribute sets with a boolean attribute `success` and a string attribute `message` instead of a boolean in `assert …; …` expressions.
If the `success` attribute is false, the assertion fails with a message including the `message` attribute.

This change requires no change to the language grammar.

# Drawbacks
[drawbacks]: #drawbacks

- Implementation clutter
- This could end up as a confusing and underutilized feature that hardly anybody knows about

# Alternatives
[alternatives]: #alternatives

- Doing nothing and continuing to use whichever assertion method is most appropriate for a given use case
- Deprecating `assert …; …` expressions in favour of user-made type systems

# Unresolved questions
[questions]: #unresolved-questions

- What should the exact name of `message` and `success` be?
- What should the error messsage be?
