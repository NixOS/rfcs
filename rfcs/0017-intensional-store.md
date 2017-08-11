---
feature: intensional_store
start-date: 2017-08-11
author: Wout.Mertens@gmail.com
co-authors: (find a buddy later to help our with the RFC)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

One paragraph explanation of the feature.

# Motivation
[motivation]: #motivation

* Better re-use of inputs between compiles
* Faster updates via nix-channel
* Less compiling
* More benefit from reproducible compiles, so more reason to work on that

# Detailed design
[design]: #detailed-design

Terms used:
* derivation: a `nix-build` output product depending on some inputs and resulting in a file or directory under `/nix/store`
* dependent derivation: a derivation built using the currently considered derivation
* `$out`: name of the location where a derivation is built, e.g., `zyb6qaasr5yhh2r4484x01cy87xzddn7-unit-script-1.12`
  * calculated based on the hashes of all the inputs, including build tools
* `$cas`: output hash, the total hash of all the files under $out, with the derivation name appended, e.g., `qqzyb6bsr5yhh2r5624x01cy87xzn7aa-unit-script-1.12`

## Concept

The basic concept is aliasing equivalent input derivations in such a way that dependent derivations won't need to change if only `$out` changes but not the input derivation contents.

After building a derivation, `$cas` is calculated, and `$out` is renamed to `$cas`. Then, if another build requires the input `$out`, it gets `$cas` instead, and all references to that build input will be `$cas` instead of `$out`. That dependent derivation will also have its input hash calculated with the `$cas` instead of the `$out`.

This means that if 2 different derivations of the same input have a different `$out` but the same `$cas`, any dependent builds will not need to rebuild due to the inputs being different. For example, the 12MB input `poppler-data` is often the same across multiple different input derivations, so many `$out`s for `poppler-data` all result in the same `$cas`. Similarly, a compiler flag change might leave most derivations unchanged.

In order to know which `$out`s refer to a particular `$cas`, symlinks can be used (`$out` pointing to `$cas`), or that data can be stored in the store database. The database can help with doing reverse lookups from `$cas` to all the `$out`s.

## Calculating `$cas`

There is one important corner case that needs special handling: if a derivation refers to itself, it will be referring to `$out`, because `$cas` is not known at the time of the build. This means that each `$out` of a furthermore equivalent build would have a different hash, due to the different `$out`s.

To fix this, the `$cas` calculation has to replace all occurrences of `$out` with an equal-length string of (for example) NULL bytes. After that, `$out` is renamed to `$cas` and all occurrences of `$out` are replaced with `$cas`.

This also means that `$out` and `$cas` should have the same length. The easiest way to achieve that is to use the same hash function for the output hash as used for the input hashes.

To calculate `$cas` we need to include all the data that uniquely defines a derivation: the file contents, case-sensitive names, and the permission bits, traversed in a fixed order, no matter what the filesystem or platform. Not to be included are the owning `uid` of the store and timestamps.

## Distributing derivations

Since `$cas` is only known when `$out` is built, binary caches would need to retain that information. When you look up `$out` to see if it was built already, the response should be _"Yes, this is available as `$cas`"_.

## Maintaining the Nix store

When garbage collecting, the Nix store should also remove `$out` references (be they symlinks or db entries) when removing a `$cas`.

## Micro-optimizations not worth considering

* By stripping the version from `$cas`, it could be the same for multiple versions of the same derivation.
  * However, increased version numbers mean the derivation actually changed, so there is no point in doing that.
* By stripping the name and the version from `$cas`, it could be the same for multiple different derivations.
  * However, this makes it hard to find out what derivation a certain `$cas` is
  * Furthermore, different inputs with the same contents are very unlikely, and there is no reduction in builds that need to be done.

Finally, `nix-store` supports hardlinking duplicate files, so the above optimizations are useless.

# Drawbacks
[drawbacks]: #drawbacks

* Extra code to maintain
* Slightly more processing after a build

# Alternatives
[alternatives]: #alternatives

* No change: This is only an optimization, it won't change the fundamental working of Nix in any way

# Unresolved questions
[unresolved]: #unresolved-questions

* Whether to store mappings as symlinks or db entries
* Exactly how the Hydra protocol needs to be changed

# Future work
[future]: #future-work

## Input-agnostic derivations

If a derivation with a new input is the same except that it has a changed reference to that input (e.g., a script referring to its interpreter, or a binary using a new library version), we call this an input-agnostic derivation for those two input versions (old and new input).

  * To detect this, calculate the hash over the derivation, replacing *all* input references with NULL bytes. If that resulting hash is the same as a previous derivation, it is input-agnostic for those versions.
  * This means that instead of downloading for installing it, it could be patched together from the previous version, by patching the old input `$cas`s with the new `$cas`s.
  * This could keep storage and network traffic for Hydra down, by storing the previous `$cas` and the strings that need to be patched.

### …and beyond:

Knowing this also could enable a building shortcut: If a dependent derivation needs rebuilding, and a previous version is available depending on an input-agnostic derivation, it could be generated by patching in the new `$cas`.

This will not always work, i.e., when the input-agnostic derivation is used to copy data from the input it is agnostic over, it results in a change besides the input reference.

Therefore, this optimization should be optional, defaulting to off.

## Reproducible builds

If two derivations are the same except for some irrelevant build-environment changes, they won't get the same `$cas`. Since this impacts rebuilds, there is more incentive to have fully reproducible builds.

Hopefully this means we'll have it at some point, so we can crowd-source `$out` to `$cas` mappings by trusting many systems that get the same result.
