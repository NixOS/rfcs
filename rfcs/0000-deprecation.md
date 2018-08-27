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

The main point of deprecation is to provide a limited amount of backwards compatibility for external code using our codebase when we remove or change some functionality. An important part to consider is the scope of backwards compatibility, because in theory full backwards compatibilty in every way can only be achieved by not ever changing anything: What if Bob built his code on the assumption that `stringLength (readFile <nixpkgs/default.nix>)` would always return 732? Of course nobody will actually do this and we don't need to nor want to keep file lengths constant. Compatibility is therefore always in regards to *how the codebase gets used* in external code. We look at how nixpkgs gets used externally:

1. Anything accessible through the top-level attribute set `pkgs = import <nixpkgs> {}`
  a. Packages (`pkgs.hello`, `pkgs.gcc`, ...) including their resulting attribute sets
  b. The standard library (`pkgs.lib`)
  c. Functions (`pkgs.mkDerivation`, `pkgs.fetchzip`, ...)
  d. Other package sets (`pkgs.haskellPackages`, `pkgs.pythonPackages`) and their packages and functions
2. The standard library through `import <nixpkgs/lib>`
3. NixOS system evaluation `import <nixpkgs/nixos> {}`
  a. All NixOS options from modules in `<nixpkgs/nixos/modules/module-list.nix>`
  b. NixOS profiles in `<nixpkgs/nixos/modules/profiles>` (TODO: Couldn't these be implemented as a NixOS option?)

Point 3a is already dealt with through `mkRemovedOptionModule`, `mkRenamedOptionModule`, etc. and is therefore not in scope for this RFC (TODO: These however don't work in submodules -> options in submodules can't use them). Point 3b is very low-traffic and therefore neither in scope. Point 2 is pretty much the same as 1b. We'll also not distinguish between standard library functions and other functions in `pkgs`. We also won't be trying to keep expressions backwards compatible in regards to e.g. what elements a list contains.

We end up with 2 categories and their compatibility properties:

- Attributes: An existing attribute continues to exist.
- Functions: All accepted function arguments continue to be accepted.

Note: These apply recursively starting an `pkgs`, and there may be exceptions to this.

Examples:
- `pkgs.pythonPackages.pytest` continues existing
- `pkgs.fetchurl` continues existing and accepting arguments of the form `{ url = ...; sha256 = ...; }`
- `pkgs.haskellPackages.xmonad.env` continues existing
- A potential exception: `pkgs.fzf.bin` may stop existing in the future and you should rely on `pkgs.lib.getBin` for getting the binary output instead.

## Implementation 

### Types of deprecation

Desired deprecation properties

- User knows deprecation reason
- Old code can be removed
- External code continues to work
- The change can be undone/changed without any UX inconsistencies "predeprecation". Users shouldn't get a warning about deprecation when later a compatibility package will be added to make it work again.

Types of deprecation

- Soft: Don't warn at first, then warn, then throw. "We don't know if we really want to deprecate it as of now"
- Firm: First warn, then throw. "We're sure to deprecate it"
- Hard: Throw. "It is deprecated and not supported anymore"
- Instant: Remove code instantly. "It has been deprecated and we want to get the warning out of our codebase"

Which types have which properties

| Property                                                     | Instant | Hard | Firm | Soft |
| User knows deprecation reason                                | No      | Yes  | Yes  | Yes  |
| Old code can be instantly removed                            | Yes     | Yes  | No   | No   |
| Users expressions continue to evaluate                       | No      | No   | Yes  | Yes  |
| The change can be undone/replaced without UX inconsistencies | No      | No   | No   | Yes  |

## When to deprecate

- Unsupported (version of a) package

## Deprecation Timeline

Because nixpkgs gets a new release every 6 months, it also makes sense to change deprecation behaviour on these boundaries. To implement this, the already existing `<nixpkgs/.version>` file can be used.

## Presets

A: Deprecate with warning now, throw error in next release, remove in distant future
B: Throw error now, remove in distant future
C: Low priority deprecation: Silent warning now, 


## Allowed State transitions

firm d val  "Been deprecated since d, but your code using it will still work up to including release r(d), but not after that. Do the other thing instead" will change to the hard message when current release > r(d)
hard d "Been deprecated since d, do the other thing instead"


Current time is t :: month, next release for a month is r :: month -> release, deprecation time is d :: month

val -> firm d val, if
  - d >= t, can't deprecate in the past
val -> hard d, if
  - d == t, can't deprecate in past nor future, because we won't have the value anymore
firm d val -> hard d, if
  - r(t) > r(d), we have to wait for the next release to promote a firm to a hard deprecation
firm d val -> removed, if
  - d + 24 >= t, a long time has passed
firm d val -> val, if
  - d > t, no warnings have been issued before
hard d val -> removed, if
  - d + 24 >= t, a long time has passed


## Deprecation messages

Should include
- Date of deprecation
- (optional) Date of expected removal
- Reason
- (optional) Remedy

## Cases

An attribute or function argument gets renamed -> Add alias and soft or hard deprecate
An attribute or function argument gets changed in functionality -> Rename it, if possible add functional equivalent alias and soft deprecate, otherwise hard deprecate
An attribute or function argument gets removed -> Soft or hard deprecate

nixpkgsVersion -> version. Don't warn by default (but do when user turned on more warnings).

## Implementation

Attributes containing the current release year and month, parsed from `<nixpkgs/.version>`. Deprecation is done like this:
```nix
nix-repl = deprecate.hard 2018 8 "foo has been deprecated in favor of bar";
nix-repl = deprecate.firm 2018 8 "foo has been deprecated in favor of bar" "foo";
nix-repl = deprecate.soft 2018 8 "foo has been deprecated in favor of bar" "foo";
```

```nix
fetchGit = { url, sha256 }: "foo";
fetchGit = { url, sha256 ? null }: "foo";

```


## PRs

https://github.com/NixOS/nixpkgs/pull/32776#pullrequestreview-84012820

https://github.com/NixOS/nixpkgs/issues/18763#issuecomment-406812366

https://github.com/NixOS/nixpkgs/issues/22401#issuecomment-277660080

soft can be the same as firm with an increased deprecation date

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

What parts of the design are still TBD or unknowns?

What about errors in library functions? Correct or keep backwards compatible. #41604
What about function arguments?

# Future work
[future]: #future-work

What future work, if any, would be implied or impacted by this feature
without being directly part of the work?

From the scope defined above it should be possible to implement a program that creates an index over nixpkgs, containing everything that's intended to be used. This can then be used for automatically verifying backwards compatibility for commits. Also this can be used for providing a tags file to look up functions and attributes.
