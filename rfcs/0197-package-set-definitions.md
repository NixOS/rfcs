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

- get rid of the package categories as directories.
- make packages in package sets take advantage of the by-name greatness
  - auto updates with r-ryantm + merge bot maintainer merging
- *your goal here*

# Idea 1: new directory for package sets

Proof-Of-Concept implementation in https://github.com/NixOS/nixpkgs/pull/482538 and https://github.com/NixOS/nixpkgs/pull/482543

## Detailed design

- Create a new directory under `pkgs/`, e.g. `pkgs/sets` that contains package sets.
  - For example `pkgs/sets/fishPlugins` `pkgs/sets/python3Packages`.
- Each packageset has a `packageset.nix`, that functions as an entrypoint to the package set.
- The `packageset.nix` files are autocalled by some `pkgs/top-level/by-name-overlay.nix` like file.
- Versioned package sets like `python316Packages` are done in `all-packages.nix` by calling the
  `packageset.nix` again with different arguments.

## Advantages

- flexibility
- easy transition
  - for a lot of package sets just move the folder and rename the `default.nix` to `packageset.nix`

## Drawbacks

- all packagesets have to handle their shit themselves, so no maintainer merging, by-name
  autocalling and stuff without the additional work
- *your drawback here*

## Unresolved Questions

- *your question here*

# Idea 2: nested by-name structure

Proof-Of-Concept implementation in https://github.com/NixOS/nixpkgs/pull/483432

## Detailed design

- Package sets are done in a nested `by-name` structure under `pkgs/by-name`, e.g.
  `fishPlugins.puffer` would be in `by-name/fi/fishPlugins/pu/puffer`.
- To distinguish packages from packagesets we have to mark packagesets somehow, for example with a
  file `by-name/fi/fishPlugins/.packageset`, if that file exists, it's called as a packageset,
  if not the `package.nix` must exist and is called as a package.

## Advantages

- clear package separation
- reuse of RFC 140 concepts
- making maintainer merging work for this is probably relatively simple

## Drawbacks

- unresolved questions
- *your drawback here*

## Unresolved Questions

- How do we handle functions like `fishPlugins.buildFishPlugin`?
- How do we handle aliases?
- How do we handle versioned package sets?
- How do we move large package sets?

# Idea 3: package sets in `pkgs/by-name` (probably worse than Idea 2 in every way)

Proof-Of-Concept implementation in https://github.com/NixOS/nixpkgs/pull/483128

## Detailed design

- Instead of `by-name/<shard>/<pname>` we have `by-name/<shard>/<attrpath>`, so e.g.
  `fishPlugins.puffer` would go in `by-name/fi/fishPlugins.puffer`.
- The `top-level/by-name-overlay.nix` will call all folders in a `<shard>` that contain a dot as a
  package set.

## Advantages

- clear package separation
- reuse of RFC 140 concepts
- making maintainer merging work for this is probably easy

## Drawbacks

- huge shards due to package sets
  - currently only few shards like `li` are too large for GitHubs UI, but with this idea a lot of
    shards like `py` (`python3Packages`), `ha` (`haskellPackages`) or `vi` (`vimPlugins`) will be
    huge as well.
- unresolved questions

## Unresolved Questions

- How do we handle functions like `fishPlugins.buildFishPlugin`?
- How do we handle aliases?
- How do we handle versioned package sets?
- How do we move large package sets?

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

# Prior art
[prior-art]: #prior-art

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
