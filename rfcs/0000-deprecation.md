---
feature: deprecation
start-date: 2018-08-25
author: Silvan Mosberger (@infinisil)
co-authors: (find a buddy later to help our with the RFC)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

We propose to add a deprecation guideline and a set of accompanying functions to deprecate functionality in nixpkgs. This includes a way to deprecate packages, functions, aliases and function arguments (TODO: Nix version too?).

# Motivation
[motivation]: #motivation

Currently nixpkgs doesn't have any standard way to deprecate functionality. When a pinned package version gets too bothersome to keep around, the attribute often just gets dropped (490ca6aa8ae89d0639e1e148774c3cd426fc699a, 28b6f74c3f4402156c6f3730d2ddad8cffcc3445), leaving users with an `attribute missing` error, which is neither helpful nor necessary. Sometimes a more graceful removal is done by replacing the attribute with a `throw "<reason of removal and potential remidiation>"` (6a458c169b86725b6d0b21918bee4526a9289c2f). This also applies to aliases and function arguments, e.g. 1aaf2be2a022f7cc2dcced364b8725da544f6ff7. TODO: Find more commits that remove aliases/packages/function args.

These warnings often stay around for a long time and won't get removed until somebody notices them when passing by.

Why are we doing this? What use cases does it support? What is the expected
outcome?

# Detailed design
[design]: #detailed-design

This is the bulk of the RFC. Explain the design in enough detail for somebody
familiar with the ecosystem to understand, and implement.  This should get
into specifics and corner-cases, and include examples of how the feature is
used.

## Backwards Compatibility and its Scope

The main point of deprecation is to provide a limited amount of backwards compatibility for external code using our codebase when we remove some functionality. An important part to consider is the scope of backwards compatibility, because in theory full backwards compatibilty in every way can only be achieved by not ever changing anything: What if Bob built his code on the assumption that `stringLength (readFile <nixpkgs/default.nix>)` would always return 732? Of course nobody will actually do this and we don't need to nor want to keep file lengths constant. Compatibility is therefore always in regards to *how the codebase gets used* in external code. We look at how nixpkgs gets used externally:

1. Anything accessible through the top-level attribute set `pkgs = import <nixpkgs> {}`
  a. Packages (`pkgs.hello`, `pkgs.gcc`, ...) including their resulting attribute sets
  b. The standard library (`pkgs.lib`)
  c. Functions (`pkgs.mkDerivation`, `pkgs.fetchzip`, ...)
  d. Other package sets (`pkgs.haskellPackages`, `pkgs.pythonPackages`) and their packages and functions
2. The standard library through `import <nixpkgs/lib>`
3. NixOS system evaluation `import <nixpkgs/nixos> {}`
  a. All NixOS options from modules in `<nixpkgs/nixos/modules/module-list.nix>`
  b. NixOS profiles in `<nixpkgs/nixos/modules/profiles>` (TODO: Couldn't these be implemented as a NixOS option?)

Point 3a is already dealt with through `mkRemovedOptionModule`, `mkRenamedOptionModule`, etc. and is therefore not in scope for this RFC (TODO: These however don't work in submodules -> options in submodules can't use them). Point 3b is very low-traffic and therefore neither in scope. Point 2 is pretty much the same as 1b. We'll also not distinguish between standard library functions and other functions in `pkgs`.

We end up with 2 categories and their compatibility properties:

- Attributes: An existing attribute continues to exist.
- Functions: All accepted function arguments continue to be accepted.

Note: These apply recursively starting an `pkgs`, and there may be exceptions to this.

Examples:
- `pkgs.pythonPackages.pytest` continues existing
- `pkgs.fetchurl` continues existing and accepting arguments of the form `{ url = ...; sha256 = ...; }`
- `pkgs.haskellPackages.xmonad.env` continues existing
- A potential exception: `pkgs.fzf.bin` may stop existing in the future and you should rely on `pkgs.lib.getBin` for getting the binary output instead.

## Cases

Soft deprecate: Warn first, then throw, then remove. Needs compatible expression.
Hard deprecate: Throw, then remove. Doesn't need compatible expression.
Insta deprecate: Remove immediately. Only use in special occasions.

An attribute or function argument gets renamed -> Add alias and soft or hard deprecate
An attribute or function argument gets changed in functionality -> Rename it, if possible add functional equivalent alias and soft deprecate, otherwise hard deprecate
An attribute or function argument gets removed -> Soft or hard deprecate


# Drawbacks
[drawbacks]: #drawbacks

Why should we *not* do this?

# Alternatives
[alternatives]: #alternatives

What other designs have been considered? What is the impact of not doing this?

# Unresolved questions
[unresolved]: #unresolved-questions

What parts of the design are still TBD or unknowns?

What about errors in library functions? Correct or keep backwards compatible. #41604

# Future work
[future]: #future-work

What future work, if any, would be implied or impacted by this feature
without being directly part of the work?

From the scope defined above it should be possible to implement a program that creates an index over nixpkgs, containing everything that's intended to be used. This can then be used for automatically verifying backwards compatibility for commits. Also this can be used for providing a tags file to look up functions and attributes.
