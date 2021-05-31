---
feature: Simple content-adressed store paths
start-date: 2019-08-14
author: Théophane Hufschmitt
co-authors: (find a buddy later to help our with the RFC)
shepherd-team: "@layus, @edolstra and @Ericson2314"
shepherd-leader: "@edolstra"
related-issues: (will contain links to implementation PRs)
---

# Summary

[summary]: #summary

Add some basic but simple support for content-adressed store paths to Nix.

We plan here to give the possibility to mark certain store paths as
content-adressed (ca), while keeping the other input-adressed as they are
now (modulo some mandatory drv rewriting before the build, see below)

By making this opt-in, we can impose arbitrary limitations to the paths that
are allowed to be ca to avoid some tricky issues that can arise with
content-adressability.

In particular, we restrict ourselves to paths that only include textual
self-references (_e.g._ no self-reference hidden inside a zip file).

That way we don't have to worry about the fact that hash-rewriting is only an
approximation

We also leave the option to lift these restrictions later.

The implementation of this RFC is already partially integrated into Nix, behind
the `ca-derivation` experimental flag.

# Motivation

[motivation]: #motivation

Having a content-adressed store with Nix (aka the "Intensional store") is a
long-time dream of the community − a design for that was already taking a whole
chapter in [Eelco's PHD thesis][nixphd].

This was never done because it represents quite a big change in Nix's model,
with some non-trivial implications (regarding the trust model in
particular).
Even without going all the way down to a fully intensional model, we can
make specific paths content-adressed, which can give some important benefits of
the intensional store at a much lower price. In particular, setting some
critical derivations as content-adressed can lead to some substantial build
cutoffs.

# Detailed design

[design]: #detailed-design

When it comes to computing the output paths of a derivation, the current Nix
model, known as the “input-addressed” model (also sometimes referred to as the
“extensional” model) works (roughly) as follows:

- A Derivation is a data-structure that specifies how to build a package.
  Derivations can refer to other derivations
- All these derivations have a “hash-modulo” associated to them, which is defined by:
  - Some derivations known as “fixed-output” have a known result (for example
    because they fetch a tarball from the internet, and we assume that this
    tarball will stay immutable).
    These have their output hash manually defined (and this hash will be
    checked against the actual hash of their output when they get built)
  - All the others have a hash that's recursively computed by the following algorithm:
    - If a derivation doesn't depend on any other derivation, then we just hash its representation,
    - Otherwise, we substitute each occurence of a dependency by its hash modulo and hash the result.
- For each output of a derivation, we compute the associated output path by
  hashing the hash modulo of the derivation and the output name.

This proposal adds a new kind of derivation: “floating content-addressed
derivations”, which are similar to fixed-output derivations in that they are
stored in a content-addressed path, but don't have this output hash specified
ahead of time.

For this to work properly, we need to extend the current build process, as well
as the caching and remote building systems so that they are able to take into
account the specificies of these new derivations.

## Nix-build process

For the sake of clarity, we will refer to the current model (where the
derivations are indexed by their inputs, also sometimes called "extensional") as
the `input-addressed` model

### Output mappings

For each output `output` of a derivation `drv`, we define

- its **Output Id** `DrvOutput(drv, output)` as the tuple `(hashModulo(drv), output)`.
  This id uniquely identifies the output.
  We textually represent this as `hashModulo(drv)!output`.
- its **realisation** `Realisation(outputId)` containing
  1. The path `path` at which this output is stored (either content-defined or input-defined depending on the type of derivation)
  2. An optional set `signatures` of signatures certifying the above

In a input-addressed-only world, the concrete path for a derivation output was a pure function of this output's id that could be computed at eval-time. However this won't be the case anymore once we allow CA derivations, so we now need to store the results of the `Realisation` function in the Nix database as a new table:

```sql
create table if not exists Realisation (
    drvHash integer not null,
    outputName text not null,
    outputPath integer not null,
)
```

### Building a non-ca derivation

#### Resolved derivations

As it is already internally the case in Nix, we define a **basic derivation** as a derivation that doesn't depend on any derivation output (except its own). Said otherwise, a basic derivation is a derivation whose only inputs are either

- Placeholders for its own outputs (from the `placeholder` builtin)
- Existing store paths

For a derivation `drv` whose input derivations have all been realised, we define its **associated resolved derivation** `resolved(drv)` as `drv` in which we replace every input derivation `inDrv` of `drv` by `Realisation(inDrv).path`, and update the output hash accordingly.

`resolved` is (intentionally) not injective: If `drv` and `drv'` only differ because one depends on `dep` and the other on `dep'`, but `dep` and `dep'` are content-addressed and have the same output hash, then `resolved(drv)` and `resolved(drv')` will be equal.

#### Build process

When asked to build a derivation `drv`, we instead:

1. Compute `resolved(drv)`
2. Substitute and build `resolved(drv)` like a normal derivation.
   Possibly this is a no-op because it may be that `resolved(drv)` has already been built.
3. Add a new mapping `Realisation(drv!${output}) == ${output}(resolved(drv))` for each output `output` of `drv` (signing the mapping if needs be)

### Building a CA derivation

A **CA derivation** is a derivation with the `__contentAddressed` argument set
to `true` and the `outputHashAlgo` set to a value that is a valid hash name
recognized by Nix (see the description for `outputHashAlgo` at
<https://nixos.org/nix/manual/#sec-advanced-attributes> for the current allowed
values).

The process for building a content-adressed derivation `drv` is the following:

- We build it like a normal derivation (see above).
  For each output `$outputId` of the derivation, this gives us a (temporary) output path `$out`.
  - We compute a cryptographic hash `$chash` of `$out`[^modulo-hashing]
  - We move `$out` to `/nix/store/$chash-$name`
  - We store the mapping `Realisation($outputId) == "/nix/store/$chash-$name"`

[^modulo-hashing]:

  We can possibly normalize all the self-references before
  computing the hash and rewrite them when moving the path to handle paths with
  self-references, but this isn't strictly required for a first iteration

### Example

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

1. We instantiate the Nix expression. This gives us three derivations:
   `contentAddressed.drv`, `dependent.drv` and `transitivelyDependent.drv`
2. We build `contentAddressed.drv`.
   - We first compute `resolved(contentAddressed.drv)`.
   - We realise `resolved(contentAddressed.drv)`. This gives us an output path
     `out(resolved(contentAddressed.drv))`
   - We move `out(resolved(contentAddressed.drv))` to its content-adressed path
     `ca(contentAddressed.drv)` which derives from
     `sha256(out(resolved(contentAddressed.drv)))`
   - We register in the db that `Realisation(contentAddressed.drv!out) == { .path = ca(contentAddressed.drv) }`
3. We build `dependent.drv`
   - We first compute `resolved(dependent.drv)`.
     This gives us a new derivation identical to `dependent.drv`, except that `contentAddressed.drv!out` is replaced by `Realisation(contentAddressed.drv!out).path == ca(contentAddressed.drv)`
   - We realise `resolved(dependent.drv)`. This gives us an output path
     `out(resolved(dependent.drv))`
   - We register in the db that `Realisation(dependent.drv!out) == { .path = out(resolved(dependent.drv)) }`
4. We build `transitivelyDependent.drv`
   - We first compute `resolved(transitivelyDependent.drv)`
     This gives us a new derivation identical to `transitivelyDependent.drv`, except that `dependent.drv!out` is replaced by `Realisation(dependent.drv!out).path == out(resolved(dependent.drv))`
   - We realise `resolved(transitivelyDependent.drv)`. This gives us an output path `out(resolved(transitivelyDependent.drv))`
   - We register in the db that `Realisation(transitivelyDependent.drv!out) == { .path = out(resolved(transitivelyDependent.drv)) }`

Now suppose that we replace `contentAddressed` by `contentAddressed'`, which evaluates to a new derivation `contentAddressed'.drv` such that the output of `contentAddressed'.drv` is the same as the output of `contentAddressed.drv` (say we change a comment in a source file of `contentAddressed`).
We try to rebuild the new `transitivelyDependent`. What happens is the following:

1. We instantiate the Nix expression. This gives us three new derivations:
   `contentAddressed'.drv`, `dependent'.drv` and `transitivelyDependent'.drv`
2. We build `contentAddressed'.drv`.
   - We first compute `resolved(contentAddressed'.drv)`
   - We realise `resolved(contentAddressed'.drv)`. This gives us an output path `out(resolved(contentAddressed'.drv))`
   - We compute `ca(contentAddressed'.drv)` and notice that the path already exists (since it's the same as the one we built previously), so we discard the result.
   - We register in the db that `Realisation(contentAddressed.drv'!out) == { .path = ca(contentAddressed'.drv) }` ( also equals to `Realisation(contentAddressed.drv!out)`)
3. We build `dependent'.drv`
   - We first compute `resolved(dependent'.drv)`.
     This gives us a new derivation identical to `dependent'.drv`, except that `contentAddressed'.drv!out` is replaced by `Realisation(contentAddressed'.drv!out).path == ca(contentAddressed'.drv)`
   - We notice that `resolved(dependent'.drv) == resolved(dependent.drv)` (since `ca(contentAddressed'.drv) == ca(contentAddressed.drv)`), so we just return the already existing path
4. We build `transitivelyDependent'.drv`
   - We first compute `resolved(transitivelyDependent'.drv)`
   - Here again, we notice that `resolved(transitivelyDependent'.drv)` is the same as `resolved(transitivelyDependent.drv)`, so we don't build anything

## Remote caching

A consequence of this change is that a store path is now just a meaningless
blob of data if it doesn't have its associated `realisation` metadata −
besides, Nix can't know the output path of a content-addressed derivation
before building it anymore, so it can't ask the remote store for it.

As a consequence, the remote cache protocols is extended to not simply
work on store paths, but rather at the realisation level:

- The store interface now specifies a new method
  ```
  queryRealisation : DrvOutput -> Maybe Realisation
  ```
- The substitution loop in Nix fist calls this method to ask the remote for the
  realisation of the current derivation output.
  If this first call succeeds, then it fetches the corresponding output path
  like before. Then, it registers the realisation in the database.
- The binary caches now have a new toplevel folder `/realisations` storing
  these realisations

# Drawbacks

[drawbacks]: #drawbacks

- Obviously, this makes the Nix model more complicated than it currently is. In
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

## Caching of non-deterministic paths

[caching]: #caching

A big question is about mixing remote-caching and non-determinism.
As [Eelco's phd thesis][nixphd] states, caching CA paths raises a number of
questions when building that path is non-deterministic (because two different
stores can have two different outputs for the same path, which might lead to
some dependencies being duplicated in the closure of a dependency).

The current implementation has a naive approach that just forbids fetching a
path if the local system has a different realisation for the same drv output.
This approach is simple and correct, but it's possible that it might not be
good-enough in practice as it can result in a totally useless binary cache in
some pathological cases.

There exist some better solutions to this problem (including one presented in
Eelco's thesis), but there are much more complex, so it's probably not worth
investing in them until we're sure that they are needed.

## Garbage collection

Another major open issue is garbage collection of the realisations table. It's
not clear when entries should be deleted. The paths in the domain are "fake" so
we can't use them for expiration. The paths in the codomain could be used (i.e.
if a path is GC'ed, we delete the alias entries that map to it) but it's not
clear whether that's desirable since you may want to bring back the path via
substitution in the future.

## Ensuring that no temporary output path leaks in the result

One possible issue with the CA model is that the output paths get moved after
being built, which breaks self-references. Hash rewriting solves this in most
cases, but it is only a heuristic and there is no way to truly ensure that we
don't leak a self-reference (for example if a self-reference appears in a
zipped file − like is often the case for man pages or Java jars, the
hash-rewriting machinery won't detect it).  Having leaking self-references is
annoying since:

- These self-references change each time the inputs of the derivation change,
  making CA useless (because the output will _always_ change when the input
  change)
- More annoyingly, these references become dangling and can cause runtime
  failures

We however have a way to dectect these: If we have leaking self-references then
the output will change if we artificially change its output path. This could be
integrated in the `--check` option of `nix-store`.

# Future work

[future]: #future-work

This RFC tries as much as possible to provide a solid foundation for building
ca paths with Nix, leaving as much room as possible for future extensions.
In particular:

- Consolidate the caching model to make it more efficient in presence of
  non-deterministic derivations
- (hopefully, one day) make the CA model the default one in Nix
- Investigate the consequences in term of privileges requirements
- Build a trust model on top of the content-adressed model to share store paths

[rfc 0017]: https://github.com/NixOS/rfcs/pull/17
[nixphd]: https://nixos.org/~eelco/pubs/phd-thesis.pdf
