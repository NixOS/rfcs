---
feature: common-override-interface-derivations
start-date: 2020-03-17
author: Frederik Rietdijk
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Define commonly used attributes for overriding of derivations in Nixpkgs.

# Motivation
[motivation]: #motivation

In Nixpkgs several methods exist to override functions calls. The primary ones are:

1. `.override` to override, typically, the first function call.
2. `.overrideAttrs` to override the call to `stdenv.mkDerivation`.
3. `.overrideDerivation` to override the call to `derivation`.

Also used in several places but out of scope for this RFC because it is for
overriding package sets is `lib.overrideScope'`.

The first two are mainly used and are typically sufficient. The third one should
typically be avoided and can be considered legacy.

However, how can we override generic package builders, such as `buildPythonPackage` and `buildGoPackage`?

For the `buildPythonPackage` function the `.overridePythonAttrs` was introduced that would override the call to `buildPythonPackage` because using `.overrideAttrs` would often not result in what the user expect would happen. In hindsight, it would have been better to attach a custom `.overrideAttrs` to `buildPythonPackage`.

This RFC thus proposes to let generic builders define a custom `.overrideAttrs` that overrides the call to the generic builder.

# Detailed design
[design]: #detailed-design

The method `.overrideAttrs` will be modified so that instead of

- `.overrideAttrs` to override the call to `stdenv.mkDerivation`.

it will be

- `.overrideAttrs` to override the call to the generic builder.

The generic builders such as `buildGoPackage` would thus apply the function `makeOverridable` to it.

In case of Python that already has `.overridePythonAttrs`, support for
```nix
buildGoPackage = makeOverridable buildGoPackage;
```

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

-

# Drawbacks
[drawbacks]: #drawbacks

After invoking a generic builder it is no longer possible to override the call to `stdenv.mkDerivation`.

# Alternatives
[alternatives]: #alternatives

An alternative would be to add a new method for overriding, `.overrideArgs`, thus allowing one to still call `.overrideAttrs` to override `stdenv.mkDerivation`.

# Unresolved questions
[unresolved]: #unresolved-questions

-

# Future work
[future]: #future-work

Implement the custom `.overrideAttrs` for the generic builders.
