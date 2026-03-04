---
feature: nixpkgs package sets
start-date: 2026-01-24
author: quantenzitrone
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: https://github.com/NixOS/nixpkgs/pull/482538
---

# Summary
[summary]: #summary

Package sets (definition see [Detailed Design](#detailed-design) e.g.`fishPlugins`, `python3Packages`)

- should be top-level attribute sets that contain
  - packages
  - functions helping these packages
  - variables like `version`, `withFoo`, ...
  - TBD: other package sets?
- should move to `pkgs/sets/<setname>` where
  - they must have a directory `pkgs/sets/<setname>/by-name`
    with a sharded `by-name` like structure
    that is checked in the CI with `nixpkgs-vet`
    - packages in this structure will get all the benefits of `pkgs/by-name`
  - they must have files `overrides.nix`, `aliases.nix`, `functions.nix` and `manual-packages.nix`
    containing aliases, overrides, functions and packages outside the `by-name` structure
  - are optionally are autocalled
    - this would be the case for manually defined package sets
      and auto generated package sets
  - if there exists a file `pkgs/sets/<setname>/packageset.nix`,
    they have to be manually called
    - this would be the case for versioned package sets
- can be versioned for which they:
  - are called multiple times through `packageset.nix`
    with the different interpreter/compiler/... versions
  - may have a top-level function `<setname>For` that allows convenient creation
    of new versions
  - may be in `passthru` of the package that they depend on
    - this can be archieved by using the `<setname>For` function

# Motivation
[motivation]: #motivation

- get rid of the package categories as directories (decided in RFC 140 and 146)
- bring the benefits of by-name to package sets
  - merge bot maintainer merging
  - scaleability
  - isolation
  - vetting
- unify the interface for package sets
- *your goal here*

# Detailed design
[design]: #detailed-design

## What are package sets?

Basically attribute sets of packages, functions and other package sets.

Package sets are often largely auto generated:
- `emacsPackages` from ELPA, MELPA, NONGNU, ...
- `haskellPackages` from hackage
- `rPackages` from CRAN (Comprehensive R Archive Network)
- ...

Package sets often depend on the version of a base program, such as an interpreter or compiler:
- `{python3*,jupyter,...,mypy*}.pkgs` depends on python interpreter, which can be different versions
   and or implementations of python
- `haskell.packages.ghc*` depends on the version of the haskell compiler
- `emacs*.pkgs` depends on the emacs version
- `{sbcl*,clisp,ccl,...}.pkgs` depends on the version/implementation of common lisp
- `ocaml-ng.ocamlPackages*` depends on the version of the ocaml compiler
- ...

Package sets are sometimes nested:
- `emacsPackages.{melpa,elpa,nongnu}{,Devel}Packages`
- `ocamlPackages.janeStreet`
- `vscode-extensions.*` but that's a whole another mess
- `kdePackages.{gear,frameworks,plasma}`
- ...

## What should package sets be?

Package sets should be top-level attribute sets. This means: 
- `ocaml-ng.*` will have to move to the top-level
- `vscode-extensions` will be flattened
- TODO: which package sets will have to move?

Package sets should have an attribute name that is lowerCamelCase.
This intentionally does not comply with the package naming conventions
because package sets are not packages.

Package sets can contain anything like packages (derivations), functions, booleans, strings
but all non-packages should be related to the package set.

Package sets will be moved to a new directory `pkgs/sets`. For example:
- `pkgs/sets/fishPlugins`
- `pkgs/sets/haskellPackages`
- `pkgs/sets/python3Packages`
- ...
This means package sets will have a "canonical name",
which will mostly also be the attribute name
with a few exceptions for versioned package sets that don't have a default version.
- e.g. `nextcloud*Packages` will be in `pkgs/sets/nextcloudPackages`,
  but there is no `pkgs.nextcloudPackages`

Package sets in `pkgs/sets` _must_ have a directory `pkgs/sets/<setname>/by-name`
which is a sharded directory structure for isolated package definitions as defined by RFC 140.
This sharded structure is checked in the CI by `nixpkgs-vet`
and will get the same benefits of `pkgs/by-name`
like merge bot maintainer merging, scaleability, isolation and vetting.
If there are no packages that fit into this structure, it may be empty.

Package sets in `pkgs/sets` _must_ have a file `pkgs/sets/<setname>/overrides.nix`
that is an overlay containing overrides for packages in the `by-name` structure
like `top-level/all-packages.nix` currently functions as an overlay for `by-name` packages
This is something we try to keep empty (`final: prev: {}`).
Most, maybe all, overrides can be inlined in the package.
e.g.
```nix
final: prev: {
  # inlineability debateable since it complicates overriding
  fooFull = final.foo.override {
    withMeow = true;
    withBeep = true;
  };

  # useless inlineable override
  bar = final.callPackage by-name/bar/package.nix {
    foo = final.fooFull;
  };
}
```

Package sets in `pkgs/sets` _must_ have a file `pkgs/sets/<setname>/functions.nix`
that is an overlay containing definitons of functions
like `buildFishPlugin`, `buildPythonPackage`.
e.g.
```nix
final: prev: {
  buildFooBarPackage = import ./buildFooBarPackage final;
}
```

Package sets in `pkgs/sets` _must_ have a file `pkgs/sets/<setname>/aliases.nix`
that is an overlay containing aliases for packages in package sets behind `optionalAttrs config.allowAliases`
like `top-level/aliases.nix` does for the top-level.
e.g.
```nix
final: prev:
let
  inherit (final) lib;
in
{
  # (warnAlias would have to move to lib for this)
  fooo = lib.warnAlias "'fooo' has been renamed to 'foo'" final.foo;
  awawa_1 = builtins.throw "'awawa_1' has been deprecated, please use a newer version of 'awawa' like 'awawa_2'";
}
```

Package sets in `pkgs/sets` _must_ have a file `pkgs/sets/<setname>/manual-packages.nix`
that is an overlay containing derivations outside the `by-name` structure
- **auto generated package sets** don't need to abuse the `overrides.nix`
- the migration of (large) package sets can initially keep the `by-name` structure empty and
  only fill it gradually, simplifying the migration of large package sets

Package sets in `pkgs/sets` _may_ have a file `pkgs/sets/<setname>/packageset.nix`
which results in them not being called automatically.
The `packageset.nix` _must_ handle the calling of the `by-name` structure
(which should be easy by using `pkgs/top-level/by-name-overlay.nix`)
as well as the files `overrides.nix`, `functions.nix`, `aliases.nix` and `manual-packages.nix`.
Since the `packageset.nix` is not automatically called
there is no need to place any more restrictions on this file,
which allows package sets to be flexible.
Calling these package sets should be done in a file in `pkgs/top-level` e.g.
- `top-level/package-sets.nix` → have all package sets in one place
- `top-level/all-packages.nix` → only have autocalled packages in a separate file → file is small

If a package set does not have a `packageset.nix`,
it is autocalled by a file in `pkgs/top-level` (e.g. `top-level/package-sets.nix`).

Versioned package sets
like `python*Packages`, `nextcloud*Packages`
will have to use the manual calling with `packageset.nix`
Example `packageset.nix` (I think this would work, but I haven't tested it):
```nix
{
  lib,
  newScope,
  config,
}:
python:
lib.makeScope newScope (
  self:
  lib.fix (
    lib.extend
      (x: {
        inherit python;
      })
      [
        (import ../../top-level/by-name-overlay.nix ./by-name)
        (self: super: lib.optionalAttrs config.allowAliases (import (./aliases.nix) self super))
        (import ./functions.nix)
        (import ./manual-packages.nix)
        (import ./overrides.nix)
      ]
  )
)
```

Versioned package sets may define a top-level function wrapping this e.g.
```nix
{
  pythonPackagesFor = callPackage ../sets/pythonPackages/packageset.nix {};
}
```

Versioned package sets may be in `passthru` of the package that they depend on e.g.
```nix
{
  lib,
  stdenv,
  # ...
  pythonPackgesFor,
  # ...
}:
stdenv.mkDerivation (finalAttrs: {
  # ...
  passthru.pkgs = pythonPackagesFor finalAttrs.finalPackage;
  # ...
})
```

## The full directory layout could look like

```
pkgs
├── sets
│   ├── fishPlugins
│   │   ├── by-name
│   │   │   ├── as
│   │   │   │   ├── async-prompt
│   │   │   │   ... └── package.nix
│   │   │   ├── au
│   │   │   ...
│   │   │   └── z_
│   │   │       └── z
│   │   │           └── package.nix
│   │   ├── aliases.nix
│   │   ├── functions.nix
│   │   ├── manual-packages.nix
│   │   ├── mkFishPlugin.nix (could also be inlined in functions.nix)
│   │   └── overrides.nix
│   │
│   ├── python3Packages
│   │   ├── by-name
│   │   │   ├── a2
│   │   │   │   └── a2wsgi
│   │   │   │       └── package.nix
│   │   │   ├── aa
│   │   │   ...
│   │   │   └── zx
│   │   │       ├── zxcvbn
│   │   │       │   └── package.nix
│   │   │       ├── zxcvbn-rs-py
│   │   │       │   └── package.nix
│   │   │       └── zxing-cpp
│   │   │           └── package.nix
│   │   ├── functions (could also be inlined in functions.nix)
│   │   │   ├── buildPythonApplication.nix
│   │   │   └── buildPythonPackage.nix
│   │   ├── aliases.nix
│   │   ├── functions.nix
│   │   ├── manual-packages.nix
│   │   ├── overrides.nix
│   │   └── packageset.nix ← entrypoint for versioned python3Packages
│   ...
└── top-level
    ├── aliases.nix ← aliases for deprecated versions of package sets
    ├── by-name-overlay.nix ← used to autocall sharded packages (no change required)
    ...
    └── package-sets.nix ← calls all package sets in pkgs/sets
```

## `pkgs/top-level/package-sets.nix` could look like

```nix
self: super:
let
  # Because of Nix's import-value cache, importing lib is free
  lib = import ../../lib;
in
# autocalled sets
lib.pipe ../sets [
  builtins.readDir
  # filter out non directories like README.md
  (lib.filterAttrs (_: value: value == "directory"))
  # filter out manually called package sets
  (lib.filterAttrs (name: _: !(lib.pathExists ../sets/${name}/packageset.nix)))
  # autocall
  (lib.mapAttrs (
    name: _:
    lib.pipe (self: { }) [
      # autocall all sharded by name packages
      (lib.extends (import ./by-name-overlay.nix ../sets/${name}/by-name))
      # overlay aliases
      (lib.extends (
        setself: setsuper:
        lib.optionalAttrs self.config.allowAliases (import (../sets/${name}/aliases.nix) setself setsuper)
      ))
      # overlay functions
      (lib.extends (import (../sets/${name}/functions.nix)))
      # overlay manual packages
      (lib.extends (import (../sets/${name}/manual-packages.nix)))
      # overlay overrides
      (lib.extends (import (../sets/${name}/overrides.nix)))
      # make a new scope and recurse into it
      (lib.makeScope self.newScope)
      lib.recurseIntoAttrs
    ]
  ))
]
# manually called sets
// {
  # python
  # we only recurse into the newest 2 python versions
  python3PackagesFor = self.callPackage ../sets/python3Packages/packageset.nix { };
  python311Packages = self.python3PackagesFor self.python311;
  python312Packages = self.python3PackagesFor self.python312;
  python313Packages = lib.recurseIntoAttrs (self.python3PackagesFor self.python313);
  python314Packages = lib.recurseIntoAttrs (self.python3PackagesFor self.python314);
  python3Packages = self.python3PackagesFor self.python314;
  pypy311Packages = self.python3PackagesFor self.pypy311;
  pypy312Packages = self.python3PackagesFor self.pypy312;
  pypy3Packages = pypy312Packages;

  # nextcloud
  nextcloudPackagesFor = self.callPackage ../sets/nextcloudPackages/packageset.nix { };
  nextcloud31Packages = self.nextcloudPackagesFor "31"; # idk if it works like this, this is an example
  nextcloud32Packages = self.nextcloudPackagesFor "32";
  nextcloud33Packages = self.nextcloudPackagesFor "33";

  # ...
}
```

Proof-Of-Concept implementation in https://github.com/NixOS/nixpkgs/pull/482538 (outdated)

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

## Adding a package to a package set

1. create `pkgs/sets/<setname>/by-name/<shard>/<pname>/package.nix`
2. write the derivation.
3. check if it works.

## Deprecating a package in a package set

1. remove the package
   e.g. by removing `pkgs/sets/<setname>/by-name/<shard>/<pname>`
2. add an alias or throw to `pkgs/sets/<setname>/aliases.nix`

## Deprecating an old version of a package set

1. remove it from `pkgs/top-level/package-sets.nix`
2. add a warning/throw to `pkgs/top-level/aliases.nix`

## Moving a package set to `pkgs/sets`

1. move all package definitions to `pkgs/sets/<setname>`
2. make sure all required files and folders exist and are in the right format
3. sort aliases, functions and derivations into their respective files
4. if the package is versioned
  - make sure the `packageset.nix` exists and includes all the required files
  - move the attribute definitons into `pkgs/top-level/package-sets.nix`
  - move aliases into `aliases.nix`
6. (optional) move packages to the `by-name` structure where possible

# Drawbacks
[drawbacks]: #drawbacks

- only allows top level package sets to benefit from `by-name` benefits
- *your drawback here*

# Alternatives
[alternatives]: #alternatives

<details>
<summary>

## Idea 2: nested by-name structure

</summary>

outdated Proof-Of-Concept implementation in https://github.com/NixOS/nixpkgs/pull/483432

### Detailed design

- Idea 1, but sets are in the existing `pkgs/by-name` structure instead of `pkgs/sets-by-name`, e.g.
  `fishPlugins.puffer` would be in `by-name/fi/fishPlugins/pu/puffer`.
- Additionally a marker is required in order to distinguish package sets from simple packages,
  such as using a `.packageset` file (example: `by-name/fi/fishPlugins/.packageset`).
  If not the `package.nix` must exist and is called as a package.

```
pkgs
└── by-name
    ├── 0_
    ...
    ├── fi
    │   ├── fiano
    │   ├── fiche
    │   ├── ...
    │   ├── fishnet
    │   ├── fishPlugins
    │   │   ├── .packageset
    │   │   ├── as
    │   │   │   └── async-prompt
    │   │   ├── au
    │   │   ...
    │   │   └── z_
    │   │       └── z
    │   ├── fishy
    │   ...
    ...
```

### Advantages

- no new directory, just extend `pkgs/by-name`
- allows nested package sets

### Drawbacks

- `lixPackages` (behind all `lib*` packages) will not be accessible through GitHubs UI
- having package sets in `pkgs/by-name` may not fit the spirit of RFC 140
- *your drawback here*

</details>

<details>
<summary>

## Idea 3: package sets in `pkgs/by-name`

</summary>

Proof-Of-Concept implementation in https://github.com/NixOS/nixpkgs/pull/483128

### Detailed design

- Instead of `by-name/<shard>/<pname>` we have `by-name/<shard>/<attrpath>`, so e.g.
  `fishPlugins.puffer` would go in `by-name/fi/fishPlugins.puffer`.
- The `top-level/by-name-overlay.nix` will call all folders in a `<shard>` that contain a dot as a
  package set.

```
pkgs
└── by-name
    ├── 0_
    ...
    ├── fi
    │   ├── fiano
    │   ├── fiche
    │   ├── ...
    │   ├── fishnet
    │   ├── fishPlugins.async-prompt
    │   ├── fishPlugins.autopair
    │   ├── fishPlugins.z
    │   ├── fishy
    │   ...
    ...
```

### Advantages

- no new directory, just extend `pkgs/by-name`
- allows nested package sets

### Drawbacks

- huge shards due to package sets
  - currently only few shards like `li` are too large for GitHubs UI, but with this idea more shards
    will be huge as well
    - specifically 12 more shards `em`, `gn`, `ha`, `ho`, `oc`, `pe`, `py`, `rp`, `sb`,
      `te`, `ty`, `vi` and `vi` (for `emacsPackages`, `gnomeExtensions`, `haskellPackages`,
      `home-assistant-component-tests`, `ocamlPackages`, `pearlPackages`, `python3Packages`,
      `rPackages`, `sbclPackages`, `texlivePackages`, `typstPackages` and `vimPlugins`) could become
      inaccessible.
- some package sets like `lixPackages` (behind all `lib*` packages) will not be accessible through
  GitHub UI
- having package sets in `pkgs/by-name` may not fit the spirit of RFC 140
- it's called pkgs/by-**name** and not pkgs/by-**attrpath**
- directory names as attrpaths is sketchy
- unresolved questions

### Unresolved Questions

- How do we handle functions like `fishPlugins.buildFishPlugin`?
- How do we handle aliases?
- How do we handle versioned package sets?
- How do we move large package sets?

</details>

# Prior art
[prior-art]: #prior-art

- `by-name` stucture for `python3Packages` https://github.com/NixOS/nixpkgs/pull/449896 https://github.com/NixOS/nixpkgs-vet/pull/180
- https://github.com/NixOS/nixpkgs/issues/482537
- https://github.com/NixOS/nixpkgs/issues/432625
- `tclPackages` has their own `by-name` structure https://github.com/NixOS/nixpkgs/pull/344716
- attempt to move `nushellPlugins` to `by-name` https://github.com/NixOS/nixpkgs/pull/482961

# Unresolved questions
[unresolved]: #unresolved-questions

- *your question here*

# Future work
[future]: #future-work

What future work, if any, would be implied or impacted by this feature without being directly part of the work?
