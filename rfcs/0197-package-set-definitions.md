---
feature: nixpkgs package set location
start-date: 2026-01-24
author: quantenzitrone
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Different ideas on how to handle package sets in nixpkgs.

# Motivation
[motivation]: #motivation

- get rid of the package categories as directories (decided in RFC 140 and 146)
- bring the benefits of by-name to package sets
  - merge bot maintainer merging
  - scaleability
  - isolation
  - vetting
- *your goal here*

<details>
<summary>

# Idea 1: new directory for package sets with by-name structure

</summary>

Proof-Of-Concept implementation in https://github.com/NixOS/nixpkgs/pull/482538

## Detailed design

- Create a new directory under `pkgs/`, e.g. `pkgs/sets-by-name` that contains package sets.
  - For example `pkgs/sets-by-name/fishPlugins`, `pkgs/sets-by-name/python3Packages`.
- Each packageset has a `packageset.nix`, that functions as an entrypoint to the package set.
  - The `packageset.nix` has some code like `top-level/by-name-overlay.nix` that autocalls packages
    in the folder.
    - with sharding for large package sets like `python3Packages`
    - without sharding for small package sets like `fishPlugins`
    - threshold for sharding is to be discussed
      - 1000 (including extra files like `README.md` and `packageset.nix`) should the the absolute
        maximum because of GitHubs UI
  - the `packageset.nix` can include aliases, functions like `fishPlugins.buildFishPlugin` and
    overrides.
- The `packageset.nix` files are autocalled by some `pkgs/top-level/by-name-overlay.nix` like file.
- Versioned package sets like `python316Packages` are done in `all-packages.nix` by calling the
  `packageset.nix` again with different arguments.

```
pkgs
├── by-name
│   └── ...
└── sets-by-name
    ├── fishPlugins <- small package set so no sharding
    │   ├── async-prompt
    │   │   └── package.nix
    │   ├── autopair
    │   │   └── package.nix
    │   ...
    │   ├── z
    │   │   └── package.nix
    │   └── packageset.nix <- entrypoint to package set
    │
    ├── python3Packages <- large package set with sharding
    │   ├── a2
    │   │   └── a2wsgi
    │   │       └── package.nix
    │   ├── aa
    │   ...
    │   ├── zx
    │   │   ├── zxcvbn
    │   │   │   └── package.nix
    │   │   ├── zxcvbn-rs-py
    │   │   │   └── package.nix
    │   │   └── zxing-cpp
    │   │       └── package.nix
    │   └── packageset.nix <- entrypoint to package set
    ...
```

## Advantages

- accessibility through github ui navigation (better than idea 2 and 3)
- clear package separation
- reuse of RFC 140 concepts
- making maintainer merging work for this is probably relatively simple
  - implement tooling to work for a non-sharded by-name structure
  - enable tooling on all subdirectories of `pkgs/sets-by-name`

## Drawbacks

- autocalling logic has to be duplicated for each package set
- only allows top level package sets
- *your drawback here*

## Unresolved Questions

- *your question here*

</details>

<details>
<summary>

# Idea 2: nested by-name structure

</summary>

Proof-Of-Concept implementation in https://github.com/NixOS/nixpkgs/pull/483432

## Detailed design

- Package sets are done in a nested `by-name` structure under `pkgs/by-name`, e.g.
  `fishPlugins.puffer` would be in `by-name/fi/fishPlugins/pu/puffer`.
- To distinguish packages from packagesets we have to mark packagesets somehow, for example with a
  file `by-name/fi/fishPlugins/.packageset`, if that file exists, it's called as a packageset,
  if not the `package.nix` must exist and is called as a package.

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

## Advantages

- clear package separation
- reuse of RFC 140 concepts
- making maintainer merging work for this is probably relatively simple
- allows nested package sets

## Drawbacks

- unresolved questions
- `lixPackages` (behind all `lib*` packages) will not be accessible through GitHubs UI
- having package sets in `pkgs/by-name` may not fit the spirit of rfc 140
- *your drawback here*

## Unresolved Questions

- How do we handle functions like `fishPlugins.buildFishPlugin`?
- How do we handle aliases?
- How do we handle versioned package sets?
- How do we move large package sets?

</details>

# Detailed design
[design]: #detailed-design

TODO: decide for one of the above ideas

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

TODO

# Drawbacks
[drawbacks]: #drawbacks

TODO

# Alternatives
[alternatives]: #alternatives

TODO: move other designs here once decided

<details>
<summary>

# Idea 3: package sets in `pkgs/by-name` (scrapped)

</summary>

Proof-Of-Concept implementation in https://github.com/NixOS/nixpkgs/pull/483128

## Detailed design

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

## Advantages

- clear package separation
- reuse of RFC 140 concepts
- making maintainer merging work for this is probably easy
- allows nested package sets

## Drawbacks

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
- having package sets in `pkgs/by-name` may not fit the spirit of rfc 140
- it's called pkgs/by-**name** and not pkgs/by-**attrpath**
- directory names as attrpaths is sketchy
- unresolved questions

## Unresolved Questions

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

What parts of the design are still TBD or unknowns?

# Future work
[future]: #future-work

What future work, if any, would be implied or impacted by this feature without being directly part of the work?
