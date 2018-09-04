---
feature: deprecation
start-date: 2018-08-25
author: Silvan Mosberger (@infinisil)
co-authors: (find a buddy later to help our with the RFC)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

We propose to add a deprecation guideline and a set of accompanying functions and tools to deprecate functionality in nixpkgs. Instead of removing an attribute which would result in an `attribute missing` error for users, one can deprecate a function, which will then first throw a warning and later throw an error. This is intended to be used for anything accessible from `import <nixpkgs> {}`, including the standard library, packages, functions, aliases, package sets, etc.

# Motivation
[motivation]: #motivation

Currently nixpkgs doesn't have any standard way to deprecate functionality. When something is too bothersome to keep around, the attribute often just gets dropped (490ca6aa8ae89d0639e1e148774c3cd426fc699a, 28b6f74c3f4402156c6f3730d2ddad8cffcc3445), leaving users with an `attribute missing` error, which is neither helpful nor necessary, because Nix has functionality for warning the user of deprecation or throwing useful error messages. This approach has been used before, but on a case-by-case basis (6a458c169b86725b6d0b21918bee4526a9289c2f). (Todo: link to 1aaf2be2a022f7cc2dcced364b8725da544f6ff7 and find more commits that remove aliases/packages/function args).

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

Everything else you might assume of nixpkgs isn't meant to be kept compatible, such as how many elements are in `pkgs.hello.buildInputs` or that `pkgs.hello.outPath` stays the same, therefore we don't include them here. Function arguments are secondary to this RFC, as most functions are rarely changed (Todo: Maybe extend this RFC to function arguments or rename it to "attribute deprecation"). Therefore attributes and their existence will be the focus.

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
- The may be undone/changed without any UX inconsistencies. This means users shouldn't get a warning about deprecation when this might get undone later, e.g. when it gets decided that deprecation isn't wanted after all, or that a compatibility package can be added. Once a warning of deprecation has been issued, it should be deprecated.

Types of deprecation

Deprecation happens in a sequence of phases, which will correspond to the release cycle of nixpkgs.

- Warn(delayed): Don't warn at first, then warn, then throw. Meaning: "We don't know if we really want to deprecate it as of now"
- Warn: First warn, then throw. Meaning: "We're sure to deprecate it, but we'll keep it usable for now"
- Throw: Throw. Meaning: "It is deprecated and not supported anymore"
- Removal: Remove code instantly. Meaning: "It has been deprecated and we want to get our codebase rid of it now" or "This attribute wasn't even meant to be used in the first place"

Which types have which properties

| Property                                                     | Removal | Throw | Warn | Warn(delayed) |
| User knows deprecation reason                                | No      | Yes   | Yes  | Yes           |
| Old code can be instantly removed                            | Yes     | Yes   | No   | No            |
| Users expressions continue to evaluate                       | No      | No    | Yes  | Yes           |
| The change can be undone/replaced without UX inconsistencies | No      | No    | No   | Yes           |

#### State transitions

The properties of the four deprecation types along with the properties they ensure lead us to a set of allowed transitions between them. We will use the following primitives to represent deprecation. Here `r` represents the current release as an integer.

- `val` signifies a non-deprecated value `val`. In Nix this corresponds to `val` itself
- `warn d n val` signifies deprecation since release `d` and unsupported since release `d + n`. In Nix this corresponds to a function like this:
    ```nix
    if r < d then val # The deprecation time is the future, don't emit any message right now
    else if r >= d + n then throw "Deprecated since ${d}, removed in ${d + n}" # The current time is after the time of the planned throw
    else builtins.trace "Deprecated since ${d}, will be removed in ${d + n}" val` # The deprecation time is not in the future and before the planned throw
    ```
- `throw d n` signifies a deprecation since release `d` and unsupported since release `d + n`, the same as `warn` without a `val`. In Nix this corresponds to `throw "Deprecated since ${d}, removed in ${d + n}`.
- `removed`, the attribute is removed. In Nix this corresponds to an `attribute missing` error.

Our deprecation types map to these primitives like this:

- Warn(delayed) is `warn d n val` with `r < d`, aka deprecate in the future
- Warn is `warn d n val` with `r == d`, aka deprecate now
- Throw is `throw d n`
- Removal is `removed`

This leads us to the following allowed state transitions between our primitives:

- `val` -> `warn d n val`, if `r <= d`, aka can't deprecate in the past
- `warn d n val` -> `val`, if `r < d`, aka no warning has been issued yet, we can safely remove the deprecation again without causing any inconsistencies
- `val` -> `throw d n`, if `d == r`, aka can't deprecate in past nor future, because we won't have the value anymore
- `warn d n val` -> `throw d n`, if `r >= d -> r >= d + n`, aka if a warning has been issued, we need to wait until the warning time has passed to transition to a throw. This is the same as just `r >= d + n`
- `warn d n val` -> `removed`, if `r >= d + n + long`, aka it should be a while before we can remove throw messages. `long` stands for the number of releases the `throw` should have been issued for.
- `throw d n` -> removed, if `r >= d + n + long`, aka it should be a while before we can remove throw messages. `long` stands for the number of releases the `throw` should have been issued for.

## Implementation

### Release tracking

To implement deprecation functions that can vary their behaviour depending on the number of releases that have passed since initial deprecation, we need to track past releases. A file `<nixpkgs/lib/releases.nix>` should be introduced with contents of the form
```nix
map ({ release, ... }@attrs: attrs // {
  yearMonth = let
    year = lib.toInt (lib.versions.major release);
    month = lib.toInt (lib.versions.minor release);
    in (2000 + year) * 12 + month;
}) [
  {
    name = "Impala";
    release = "18.03";
    year = 2018;
    month = 4;
    day = 4;
  }
  {
    name = "Hummingbird";
    release = "17.09";
    year = 2017;
    month = 9;
    day = ??;
  }
  {
    name = "Gorilla";
    release = "17.03";
    year = 2017;
    month = 3;
    day = 31;
  }
  # ...
]
```

Additional fields can be added if the need arises. This file should be updated at date of release. It may also be updated already at branch-off time (TODO: Think about this some more).

### Deprecation functions

A function `lib.deprecate` will be introduced. When an attribute should be deprecated, it can be used like follows:
```nix
{
  foo = lib.deprecate' {
    year = 2018;
    month = 8;
    warnFor = 2;
    reason = "Use bar instead";
    value = "foo";
  };
}
```

Optionally, for convenience, a shorthand `lib.deprecate'` can be provided as well:
```nix
{
  bar = lib.deprecate 2018 8 "Bar is a burden to the codebase" "bar";
}
```

Which will correspond to
```nix
{
  bar = lib.deprecate' {
    year = 2018;
    month = 8;
    warnFor = 1;
    reason = "Bar is a burden to the codebase";
    value = "bar";
  };
}
```

The basic implementation and meaning of arguments is a follows (Note: I didn't test this yet).
```nix
{
  releaseYearMonth = let
    year = lib.toInt (lib.versions.major lib.trivial.release);
    month = lib.toInt (lib.versions.minor lib.trivial.release);
    in (2000 + year) * 12 + month;
    
  allReleases = [ releaseYearMonth ] ++ map (r: r.yearMonth) releases;
  
  takeWhile = pred: list: ...;
    
  deprecate' =
    { year # Year of deprecation as an integer
    , month # Month of deprecation as an integer
    , warnFor ? 1 # Number of releases to warn before throwing
    , reason # Reason of deprecation
    , value ? null # The value to evaluate to, may be null if the current release throws
    }:
    if warnFor < 0 then abort "the warnFor argument to lib.deprecate needs to be non-negative" else
    let
      deprecationYearMonth = year * 12 + month;
      depReleases = takeWhile (ym: ym > deprecationYearMonth) allReleases;
        
      isDeprecated = depReleases != [];
      deprecationRelease = if isDeprecated then last depReleases else
        releaseYearMonth + ((deprecationYearMonth - releaseYearMonth) / 6) * 6);
      isRemoved = depReleases > warnFor;
      removedRelease = if isRemoved then elemAt depReleases (length depReleases - warnFor) else
        releaseYearMonth + ((deprecationYearMonth - releaseYearMonth) / 6 + warnFor) * 6);
      prettyRelease = yearMonth: "${toString (div yearMonth 12 - 2000)}.${toString (mod yearMonth 12)}";
      deprecationString = if isDeprecated then "Deprecated since ${prettyRelease deprecationRelease}" else
        "Will be deprecated in ${prettyRelease deprecationRelease}";
      removedString = if isRemoved then ", removed since ${prettyRelease removedRelease}" else
        ", will be removed in ${prettyRelease removedRelease}";
      message = "${deprecationString}${removedString}. Reason: ${reason}";
    in
      if ! isDeprecated then assert value != null; value
      else if isRemoved then throw removedString
      else assert value != null; builtins.trace deprecationString value;
  
  deprecate = year: month: reason: value: deprecate {
    inherit year month reason value;
  };
}
```

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

### Cases

- Unsupported/deprecated (version of a) package, like `foobar_0_1` which is for some reason still in the code
- A package gets renamed for consistency reasons

## Deprecation messages

Should include
- Date of deprecation
- (optional) Date of expected removal
- Reason
- (optional) Remedy

## PRs

https://github.com/NixOS/nixpkgs/pull/32776#pullrequestreview-84012820

https://github.com/NixOS/nixpkgs/issues/18763#issuecomment-406812366

https://github.com/NixOS/nixpkgs/issues/22401#issuecomment-277660080

https://github.com/NixOS/nixpkgs/pull/45717

https://github.com/NixOS/nixpkgs/pull/19315

https://github.com/NixOS/nixpkgs/pull/45717#issuecomment-418424080

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
