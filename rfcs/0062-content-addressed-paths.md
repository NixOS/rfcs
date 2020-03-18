---
feature: Simple content-adressed store paths
start-date: 2019-08-14
author: Théophane Hufschmitt
co-authors: (find a buddy later to help our with the RFC)
shepherd-team: @layus, @edolstra and @Ericson2314
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary

[summary]: #summary

Add some basic but simple support for content-adressed store paths to Nix.

We plan here to give the possibility to mark certain store paths as
content-adressed (ca), while keeping the other dependency-adressed as they are
now (modulo some mandatory drv rewriting before the build, see below)

By making this opt-in, we can impose arbitrary limitations to the paths that
are allowed to be ca to avoid some tricky issues that can arise with
content-adressability.

In particular, we restrict ourselves to paths that are:

- without any non-textual self-reference (_i.e_ a self-reference hidden inside a zip file)
- known to be deterministic (for caching reasons, see [caching]).

That way we don't have to worry about the fact that hash-rewriting is only an
approximation nor by the semantics of the distribution of non-deterministic
paths.

We also leave the option to lift these restrictions later.

This RFC already has a (somewhat working) POC at
<https://github.com/NixOS/nix/pull/3262>.

# Motivation

[motivation]: #motivation

Having a content-adressed store with Nix (aka the "Intensional store") is a
long-time dream of the community − a design for that was already taking a whole
chapter in [Eelco's PHD thesis][nixphd].

This was never done because it represents a quite big change in Nix's model,
with some non-totally-solved implications (regarding the trust model in
particular).
Even without going all the way down to a fully intensional model, we can
make specific paths content-adressed, which can give some important benefits of
the intensional store at a much lower price. In particular, setting some
critical derivations as content-adressed can lead to some substancial build
cutoffs.

# Detailed design

[design]: #detailed-design

The gist of the design is that:

- Derivations can be marked as content-adressed (ca), in which case each
  one of their output will be moved to content-addressed `ca` store path.
  This extends the current notion of "fixed-output" derivations.
- We introduce the notion of "resolving" a derivation, which extends to
  arbitrary `ca` derivations the current behavior of replacing fixed-outputs
  derivations by their output hash.
- We refine the build process so that every derivation is first normalized
  before being realized

## Nix-build process

### Output mappings

For each output `output` of a derivation `drv`, we define

- its output id **DrvOutputId(drv, output)** as the tuple `(hash(drv), output, truster)`, where `truster` is a reserved field for future use and currently always set to `"world"`.
  This id uniquely identifies the output.
  We textually represent this as `hash(drv)!output[@truster]`.
- its concrete path **PathOf(outputId)** as the path on which the output will be stored on disk.

> Unresolved: should we already include the `truster` field in `DrvOutputId`
> even if it's not used atm? What would be the cost of adding it later?

In a dependency-addressed-only world, the concrete path for a derivation output was a pure function of this output's id that could be computed at eval-time. However this won't be the case anymore once we allow content-addressed derivations, so we now need to store the results the `PathOf` function in the Nix database as a new table:

```sql
create table if not exists PathOf (
    drv integer not null,
    output text not null,
    truster integer not null,
    path integer not null,
)
```

### Building a normal derivation

#### Resolved derivations

We define a **resolved derivation** as a derivation whose only references are either:

- Self references
- References to the outputs of other (non content-addresed) resolved derivations
- Existing store paths

For a derivation `drv` whose input derivations have all been realised, we define its **associated resolved derivation** `resolved(drv)` as `drv` in which we replace every input derivation `inDrv` of `drv` by `pathOf(inDrv)` (and update the output hash accordingly).

> This doesn't have the property that for a derivation that doesn't depend on any CA derivation `resolved(drv) == drv`. I think that this is a rather big issue so we'll have to find a way to get this property back (but feel free to correct me if you think that it isn't a big deal)

`resolved` is (intentionally) not injective: If `drv` and `drv'` only differ because one depends on `dep` and the other on `dep'`, but `dep` and `dep'` are content-addressed and have the same output hash, then `resolved(drv)` and `resolved(drv')` will be equal.

#### Build process

When asked to build a derivation `drv`, we instead:

1. Compute `resolved(drv)`
2. Substitute and build `resolved(drv)` like a normal derivation.
   Possibly this is a no-op because it may be that `resolved(drv)` has already been built.
3. Add a new mapping `pathOf(drv!${output}) == ${output}(resolved(drv))` for each output `output` of `drv`

### Building a ca derivation

A **ca derivation** is a derivation with the `__contentAddressed` argument set
to `true` and the `outputHashAlgo` set to a value that is a valid hash name
recognized by Nix (see the description for `outputHashAlgo` at
<https://nixos.org/nix/manual/#sec-advanced-attributes> for the current allowed
values).

The process for building a content-adressed derivation `drv` is the following:

- We build it like a normal derivation (see above).
  For each output `$outputId` of the derivation, this gives us a (temporary) output path `$out`.
  - We compute a cryptographic hash `$chash` of `$out`[^modulo-hashing]
  - We move `$out` to `/nix/store/$chash-$name`
  - We store the mapping `PathOf($outputId) == "/nix/store/$chash-$name"`

[^modulo-hashing]:

  We can possibly normalize all the self-references before
  computing the hash and rewrite them when moving the path to handle paths with
  self-references, but this isn't strictly required for a first iteration

## Example

In this example, we have the following Nix expression:

```nix
rec {
  contentAddressed = mkDerivation {
    name = "contentAddressed";
    __contentAddressed = true;
    … # Some extra arguments
  };
  dependent = mkDerivation {
    name = "dependent";
    buildInputs = [ contentAddressed ];
    … # Some extra arguments
  };
  transitivelyDependent = mkDerivation {
    name = "transitivelyDependent";
    buildInputs = [ dependent ];
    … # Some extra arguments
  };
}
```

Suppose that we want to build `transitivelyDependent`.
What will happen is the following

1. We instantiate the Nix expression, this gives us three drv files:
   `contentAddressed.drv`, `dependent.drv` and `transitivelyDependent.drv`
2. We build `contentAddressed.drv`.
   - We first compute `resolved(contentAddressed.drv)`.
   - We realise `resolved(contentAddressed.drv)`. This gives us an output path
     `out(resolved(contentAddressed.drv))`
   - We move `out(resolved(contentAddressed.drv))` to its content-adressed path
     `ca(contentAddressed.drv)` which derives from
     `sha256(out(resolved(contentAddressed.drv)))`
   - We register in the db that `pathOf(contentAddressed.drv!out) == ca(contentAddressed.drv)`
3. We build `dependent.drv`
   - We first compute `resolved(dependent.drv)`.
     This gives us a new derivation identical to `dependent.drv`, except that `contentAddressed.drv!out` is replaced by `pathOf(contentAddressed.drv!out) == ca(contentAddressed.drv)`
   - We realise `resolved(dependent.drv)`. This gives us an output path
     `out(resolved(dependent.drv))`
   - We register in the db that `pathOf(dependent.drv!out) == out(resolved(dependent.drv))` We build `transitivelyDependent.drv`
4. We build `transitivelyDependent.drv`
   - We first compute `resolved(transitivelyDependent.drv)`
     This gives us a new derivation identical to `transitivelyDependent.drv`, except that `dependent.drv!out` is replaced by `pathOf(dependent.drv!out) == out(resolved(dependent.drv))`
   - We realise `resolved(transitivelyDependent.drv)`. This gives us an output path `out(resolved(transitivelyDependent.drv))`
   - We register in the db that `pathOf(transitivelyDependent.drv!out) == out(resolved(transitivelyDependent.drv))`

Now suppose that we replace `contentAddressed` by `contentAddressed'`, which evaluates to a new derivation `contentAddressed'.drv` such that the output of `contentAddressed'.drv` is the same as the output of `contentAddressed.drv` (say we change a comment in a source file of `contentAddressed`).
We try to rebuild the new `transitivelyDependent`. What happens is the following:

1. We instantiate the Nix expression, this gives us three new drv files:
   `contentAddressed'.drv`, `dependent'.drv` and `transitivelyDependent'.drv`
2. We build `contentAddressed'.drv`.
   - We first compute `resolved(contentAddressed'.drv)`
   - We realise `resolved(contentAddressed'.drv)`. This gives us an output path `out(resolved(contentAddressed'.drv))`
   - We compute `ca(contentAddressed'.drv)` and notice that the path already exists (since it's the same as the one we built previously), so we discard the result.
   - We register in the db that `pathOf(contentAddressed.drv'!out) == ca(contentAddressed'.drv)` ( also equals to `ca(contentAddressed.drv)`)
3. We build `dependent'.drv`
   - We first compute `resolved(dependent'.drv)`.
     This gives us a new derivation identical to `dependent'.drv`, except that `contentAddressed'.drv!out` is replaced by `pathOf(contentAddressed'.drv!out) == ca(contentAddressed'.drv)`
   - We notice that `resolved(dependent'.drv) == resolved(dependent.drv)` (since `ca(contentAddressed'.drv) == ca(contentAddressed.drv)`), so we just return the already existing path
4. We build `transitivelyDependent'.drv`
   - We first compute `resolved(transitivelyDependent'.drv)`
   - Here again, we notice that `resolved(transitivelyDependent'.drv)` is the same as `resolved(transitivelyDependent.drv)`, so we don't build anything

# Drawbacks

[drawbacks]: #drawbacks

- Obviously, this makes the Nix model more complicated than what it is now. In
  particular, the caching model needs some modifications (see [caching]);

- We specify that only a sub-category of derivations can safely be marked as
  `contentAddressed`, but there's no way to enforce these restricitions;

- This will probably be a breaking-change for some tooling since the output path
  that's stored in the `.drv` files doesn't correspond to an actual on-disk
  path.

# Alternatives

[alternatives]: #alternatives

[RFC 0017][] is another proposal with the
same end-goal. The big difference between these two is in the scope they cover:
RFC 0017 is about fundamentally changing the base model of Nix, while this
proposal suggests to make only the minimal amount of changes to the current
model to allow the content-adressed model to live in parallel (which would open
the way to a fully content-adressed store as RFC0017, but in a much more
incremental way).

Eventually this RFC should be subsumed by RFC0017.

# Unresolved questions

[unresolved]: #unresolved-questions

## Caching

[caching]: #caching

The big unresolved question is about the caching of content-adressed paths.
As [Eelco's phd thesis][nixphd] states it, caching ca paths raises a number of
questions when building that path is non-deterministic (because two different
stores can have two different outputs for the same path, which might lead to
some dependencies being duplicated in the closure of a dependency).
There exist some solutions to this problem (including one presented in Eelco's
thesis), but for the sake of simplicity, this RFC simply forbids to mark a
derivation as ca if its build is not deterministic (although there's no real
way to check that so it's up to the author of the derivation to ensure that it
is the case).

## Client support

The bulk of the job here is done by the Nix daemon.

Depending on the details of the current Nix implementation, there might or
might not be a need for the client to also support it (which would require the
daemon and the client to be updated in synchronously)

## Old Nix versions and caching

What happens (and should happen) if a Nix not supporting the cas model queries
a cache with cas paths in it is not clear yet.

## Garbage collection

Another major open issue is garbage collection of the aliases table. It's not
clear when entries should be deleted. The paths in the domain are "fake" so we
can't use them for expiration. The paths in the codomain could be used (i.e. if
a path is GC'ed, we delete the alias entries that map to it) but it's not clear
whether that's desirable since you may want to bring back the path via
substitution in the future.

## Ensuring that no temporary output path leaks in the result

One possible issue with the ca model is that the output paths get moved after being built, which breaks self-references. Hash rewriting solves this in most cases, but it is only heuristic and there is no way to truly ensure that we don't leak a self-reference (for example if a self-reference appears in a zipped file − like it's often the case for man pages or java jars, the hash-rewriting machinery won't detect it).
Having leaking self-references is annoying since

- These self-references change each time the inputs of the derivation change, making ca useless (because the output will _always_ change when the input change)
- More annoyingly, these references become dangling and can cause runtime failures

We however have a way to dectect these: If we have leaking self-references then the output will change if we artificially change its output path. This could be integrated in the `--check` option of `nix-store`.

# Future work

[future]: #future-work

This RFC tries as much as possible to provide a solid foundation for building
ca paths with Nix, leaving as much room as possible for future extensions.
In particular:

- Add some path-rewriting to allow derivations with self-references to be built
  as ca
- Consolidate the caching model to allow non-deterministic derivations to be
  built as ca
- (hopefully, one day) make the CA model the default one in Nix
- Investigate the consequences in term of privileges requirements
- Build a trust model on top of the content-adressed model to share store paths

[rfc 0017]: https://github.com/NixOS/rfcs/pull/17
[nixphd]: https://nixos.org/~eelco/pubs/phd-thesis.pdf
