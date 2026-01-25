---
feature: nixpkgs package sets by-name
start-date: 2026-01-24
author: quantenzitrone
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: https://github.com/NixOS/nixpkgs/pull/482538
---

# Summary
[summary]: #summary

Package sets like `fishPlugins` or `python3Packages` move to a `pkgs/by-name` like structure in
`pkgs/sets-by-name/<setname>`.

This doesn't apply to package sets that are auto-generated like `haskellPackages`.

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

# Detailed design
[design]: #detailed-design

- Create a new directory under `pkgs/`, e.g. `pkgs/sets-by-name` that contains package sets.
  - For example `pkgs/sets-by-name/fishPlugins`, `pkgs/sets-by-name/python3Packages`.
- Each package set is sharded like `pkgs/by-name`.
- The following additional have to exist for each package set.
  - `functions.nix`: definitons of functions, like `buildFishPlugin`, `buildPythonPackage`.
  - `overrides.nix`: overrides of packages, like `top-level/all-packages.nix` currently functions as
    an overlay for `by-name` packages.
    - This is something we try to keep empty. Most, maybe all, overrides can be inlined in the
      package.
  - `aliases.nix`: aliases for aliases in package sets behind `optionalAttrs config.allowAliases`
    (like `top-level/aliases.nix`).
- All package sets with their sharded packages, overlayed with their functions, overrides and
  aliases are automatically called by `top-level/package-sets-by-name.nix`.
- Versioned package sets like `python316Packages` are done in `all-packages.nix` by overriding the
  default version package set.
- Versioned package sets without a default version will have to override the default version with
  an error.
  - e.g. `nextcloud*Packages` are in `sets-by-name/nextcloundPackages` and thus autocalled by
    `top-level/package-sets-by-name.nix`, however we will have an alias in `top-level/aliases.nix`
    that says
    ```nix
    {
      nextcloudPackages = throw "Please use nextcloudPackages for a specific nextcloud ersion e.g. nextcloud32Packages.";
    }
    ```

```
pkgs
├── by-name
│   └── ...
├── sets-by-name
│   ├── fishPlugins
│   │   ├── as
│   │   │   ├── async-prompt
│   │   │   ... └── package.nix
│   │   ├── au
│   │   ...
│   │   ├── z_
│   │   │   └── z
│   │   │       └── package.nix
│   │   ├── aliases.nix
│   │   ├── functions.nix
│   │   └── overrides.nix
│   │
│   ├── python3Packages
│   │   ├── a2
│   │   │   └── a2wsgi
│   │   │       └── package.nix
│   │   ├── aa
│   │   ...
│   │   ├── zx
│   │   │   ├── zxcvbn
│   │   │   │   └── package.nix
│   │   │   ├── zxcvbn-rs-py
│   │   │   │   └── package.nix
│   │   │   └── zxing-cpp
│   │   │       └── package.nix
│   │   ├── aliases.nix
│   │   ├── functions.nix
│   │   └── overrides.nix
│   ...
└── top-level
    ├── all-packages.nix <- calls all versioned package sets
    ├── by-name-overlay.nix <- used to autocall sharded packages (no change required)
    ...
    └── package-sets-by-name.nix <- autocalls all sets by name
```

Proof-Of-Concept implementation in https://github.com/NixOS/nixpkgs/pull/482538

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

TODO

# Drawbacks
[drawbacks]: #drawbacks

- only allows top level package sets
- *your drawback here*

## Unresolved Questions

- Does the handling of versioned package sets work like this?
- How do we move large package sets?
- *your question here*

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

## Idea 3: package sets in `pkgs/by-name` (scrapped)

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

What parts of the design are still TBD or unknowns?

# Future work
[future]: #future-work

What future work, if any, would be implied or impacted by this feature without being directly part of the work?
