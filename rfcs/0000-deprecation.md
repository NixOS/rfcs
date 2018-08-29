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

## Discussion

### Scope

Backwards compatibility should only concern the intended usage of nixpkgs:

1. Anything accessible through the top-level attribute set `pkgs = import <nixpkgs> {}`
  a. Packages (`pkgs.hello`, `pkgs.gcc`, ...) including their resulting attribute sets
  b. The standard library (`pkgs.lib`)
  c. Functions (`pkgs.mkDerivation`, `pkgs.fetchzip`, ...)
  d. Other package sets (`pkgs.haskellPackages`, `pkgs.pythonPackages`) and their packages and functions
2. The standard library through `import <nixpkgs/lib>`
3. NixOS system evaluation `import <nixpkgs/nixos> {}`
  a. All NixOS options from modules in `<nixpkgs/nixos/modules/module-list.nix>`
  b. NixOS profiles in `<nixpkgs/nixos/modules/profiles>` (TODO: Couldn't these be implemented as a NixOS option?)

Point 3a is already dealt with through `mkRemovedOptionModule`, `mkRenamedOptionModule`, etc. and is therefore not in scope for this RFC (TODO: These however don't work in submodules -> options in submodules can't use them). Point 3b is very low-traffic and therefore neither in scope (see https://github.com/NixOS/nixpkgs/pull/32776). Point 2 is pretty much the same as 1b. We'll also not distinguish between standard library functions and other functions in `pkgs`.

We'll therefore limit ourselves to everything accessible through `import <nixpkgs> {}`. The two main categories and their compatibility properties are:

- Attributes: An existing attribute continues to exist.
- Functions: All accepted function arguments continue to be accepted.

Function arguments are secondary to this RFC, as most functions are rarely changed. Therefore attributes and their existence will be the focus.

Examples:
- `pkgs.pythonPackages.pytest` continues existing
- `pkgs.fetchurl` continues existing
- A potential exception: `pkgs.fzf.bin` may stop existing in the future and you should rely on `pkgs.lib.getBin` for getting the binary output instead.

### Types of deprecation

There can be multiple ways of dealing with deprecation, each having different properties, which we will discuss here.

Desired deprecation properties

- User knows deprecation reason
- Old code can be removed
- External code continues to work
- (optional) The change can be undone/changed without any UX inconsistencies "predeprecation". Users shouldn't get a warning about deprecation when later a compatibility package will be added to make it work again. Once a warning of deprecation has been issued, it should be deprecated.

Types of deprecation

- Soft(delayed): Don't warn at first, then warn, then throw. "We don't know if we really want to deprecate it as of now"
- Soft: First warn, then throw. "We're sure to deprecate it"
- Hard: Throw. "It is deprecated and not supported anymore"
- Instant: Remove code instantly. "It has been deprecated and we want to get the warning out of our codebase"

Which types have which properties

| Property                                                     | Instant | Hard | Soft | Soft(delayed) |
| User knows deprecation reason                                | No      | Yes  | Yes  | Yes           |
| Old code can be instantly removed                            | Yes     | Yes  | No   | No            |
| Users expressions continue to evaluate                       | No      | No   | Yes  | Yes           |
| The change can be undone/replaced without UX inconsistencies | No      | No   | No   | Yes           |


### Allowed State transitions

soft d val  "Been deprecated since d, but your code using it will still work up to including release r(d), but not after that. Do the other thing instead" will change to the hard message when current release > r(d)
hard d "Been deprecated since d, do the other thing instead"


Current time is t :: month, next release for a month is r :: month -> release, deprecation time is d :: month

val -> soft d val, if
  - d >= t, can't deprecate in the past
  
val -> hard d, if
  - d == t, can't deprecate in past nor future, because we won't have the value anymore
  
soft d val -> hard d, if
  - r(t) > r(d), we have to wait for the next release to promote a soft to a hard deprecation
  
soft d val -> removed, if
  - d + 24 >= t, a long time has passed
  
soft d val -> val, if
  - d > t, no warnings have been issued before
  
hard d val -> removed, if
  - d + 24 >= t, a long time has passed

### Cases

- Unsupported/deprecated (version of a) package, like `foobar_0_1` which is for some reason still in the code
- A package gets renamed for consistency reasons

## Deprecation messages

Should include
- Date of deprecation
- (optional) Date of expected removal
- Reason
- (optional) Remedy

## Implementation

### Nix

For simple cases, there should be a function `lib.deprecate` working like this:
```nix
# Takes current year/month, deprecation reason and the original value
foo = deprecate 2018 8 "Foo has been deprecated" "foo";
```

The behaviour of this function should be based on the current release (from `<nixpkgs/.version>`):
- If the deprecation date is after the current release, just return the value without warning
- If the deprecation date is before the current release but after the last one, emit a warning while evaluating the value
- If the deprecation date is before the current release and before the last one, throw an error

This corresponds to a soft type deprecation after the given deprecation date for one release, then dropping to a hard deprecation.

Sometimes more flexibility is needed, for which the following function will get introduced:

```nix
foo = deprecate' {
  year = 2018;
  month = 8;
  removeWarningAfter = 2; # Number of releases to warn for before hard deprecating
  reason = "Foo has been deprecated";
} "foo";
```

The former function can be defined via the latter.

To implement this, a file has to be introduced for tracking the past releases. The choice of only tracking year and month (and not the day) is due to it corresponding to nixpkgs' version numbers and anything more than that seems unnecessary while complicating the implementation (is 2018-09-15 before or after the 18.09 release?).

```nix
{
  releases = [
    {
      name = "hummingbird";
      year = 2018;
      month = 3;
    }
  ];
}
```

## PRs

https://github.com/NixOS/nixpkgs/pull/32776#pullrequestreview-84012820

https://github.com/NixOS/nixpkgs/issues/18763#issuecomment-406812366

https://github.com/NixOS/nixpkgs/issues/22401#issuecomment-277660080

https://github.com/NixOS/nixpkgs/pull/45717

## Todo

- Option to silence warnings, option to show warnings

## Examples

Can be used for deprecating versions when they're not supported anymore by upstream at the exact day.

Single file with all deprecations as an overlay? Can't implement everything, what about deprecated function args? What about stuff you can't overlay?

# Drawbacks
[drawbacks]: #drawbacks

Why should we *not* do this?

# Alternatives
[alternatives]: #alternatives

What other designs have been considered? What is the impact of not doing this?

# Unresolved questions
[unresolved]: #unresolved-questions

What about errors in library functions? Correct or keep backwards compatible. #41604
What about function arguments?

# Future work
[future]: #future-work

What future work, if any, would be implied or impacted by this feature
without being directly part of the work?

From the scope defined above it should be possible to implement a program that creates an index over nixpkgs, containing everything that's intended to be used. This can then be used for automatically verifying backwards compatibility for commits. Also this can be used for providing a tags file to look up functions and attributes. Possibly also for providing an out-of-tree documentation and examples.
