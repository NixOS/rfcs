---
feature: Simple content-adressed store paths
start-date: 2019-08-14
author: Théophane Hufschmitt
co-authors: (find a buddy later to help our with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
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

In all that follows, we pretend that each derivation has only one output.
This doesn't change the reasoning but makes things easier to state.

The gist of the design is that:

- Some derivations can be marked as content-adressed (ca), in which case their
  output will be moved to a path `ca` determined only by its content after the
  build
- When asked to build a derivation, Nix will instead compute a `dynamic`
  version of that derivation (where all the ca dependencies are replaced by
  their content addressed path), build this dynamic derivation and link back
  the original one to this build result.

## Example

Since the design is non trivial, better start with an example to give an
intuition of what's happening:

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

- We instantiate the Nix expression, this gives us three drv files:
  `contentAddressed.drv`, `dependent.drv` and `transitivelyDependent.drv`
- We build `contentAddressed.drv`.
  - We first compute `dynamic(contentAddressed.drv)` to replace its
    inputs by their real output path. Since there is none, we
    have here `dynamic(contentAddressed.drv) == contentAddressed.drv`
  - We realise `dynamic(contentAddressed.drv)`. This gives us an output path
    `out(dynamic(contentAddressed.drv))`
  - We move `out(dynamic(contentAddressed.drv))` to its content-adressed path
    `ca(contentAddressed.drv)` which derives from
    `sha256(out(dynamic(contentAddressed.drv)))`
- We build `dependent.drv`
  - We first compute `dynamic(dependent.drv)` to replace its
    inputs by their real output path.
    In that case, we replace `contentAddressed.drv!out` by
    `ca(contentAddressed.drv)`
  - We realise `dynamic(dependent.drv)`. This gives us an output path
    `out(dynamic(dependent.drv))`
- We build `transitivelyDependent.drv`
  - We first compute `dynamic(transitivelyDependent.drv)` to replace its
    inputs by their real output path.
    In that case, that means replacing `dependent.drv!out` by
    `out(dynamic(dependent.drv))`
  - We realise `dynamic(transitivelyDependent.drv)`. This gives us an output path
    `out(dynamic(transitivelyDependent.drv))`

Now suppose that we slightly change the definition of `contentAddressed` in such
a way that `contentAddressed.drv` will be modified, but its output will be the
same. We try to rebuild the new `transitivelyDependent`. What happens is the
following:

- We instantiate the Nix expression, this gives us three new drv files:
  `contentAddressed.drv`, `dependent.drv` and `transitivelyDependent.drv`
- We build `contentAddressed.drv`.
  - We first compute `dynamic(contentAddressed.drv)` to replace its
    inputs by their real output path. Since there is none, we
    have here `dynamic(contentAddressed.drv) == contentAddressed.drv`
  - We realise `dynamic(contentAddressed.drv)`. This gives us an output path
    `out(dynamic(contentAddressed.drv))`
  - We compute `ca(contentAddressed.drv)` and notice that the
    path already exists (since it's the same as the one we built previously),
    so we discard the result.
- We build `dependent.drv`
  - We first compute `dynamic(dependent.drv)` to replace its
    inputs by their real output path.
    In that case, we replace `contentAddressed.drv!out` by
    `ca(contentAddressed.drv)`
  - We notice that `dynamic(dependent.drv)` is the same as before (since
    `ca(contentAddressed.drv)` is the same as before), so we
    just return the already existing path
- We build `transitivelyDependent.drv`
  - We first compute `dynamic(transitivelyDependent.drv)` to replace its
    inputs by their real output path.
    In that case, that means replacing `dependent.drv!out` by
    `out(dynamic(dependent.drv))`
  - Here again, we notice that `dynamic(transitivelyDependent.drv)` is the same as before,
    so we don't build anything

## Nix-build process

### Aliases paths

To allow this, we add a new type of store path: aliases paths.
These paths don't actually exist in the store, just in the database and point to
another path (so they are morally symlinks, but inside the db rather than
on-disk)

### Building a ca derivation

ca derivations are derivations with the `__contentAddressed` argument set to
`true`.

The process for building a content-adressed derivation is the following:

- We build it like a normal derivation to get an output path `$out`.
- We compute a cryptographic hash `$chash` of `$out`[^modulo-hashing]
- We move `$out` to `/nix/store/$chash-$name`
- We create an alias path from `$out` to `/nix/store/$chash-$name`

[^modulo-hashing]:

  We can possibly normalize all the self-references before
  computing the hash and rewrite them when moving the path to handle paths with
  self-references, but this isn't strictly required for a first iteration

### Building a normal derivation

The process for building a normal derivation is the following:

- We look into the drv for all the inputs paths of the build
- For each input path, we look whether the path is an alias. If so we replace it
  by its target
- We compute the `dynamic` output of the derivation from the patched version
- We then try to substitute and build the new derivation
- We create an alias path from the `static` output to the `dynamic` one

## Wrapping it up

# Drawbacks

[drawbacks]: #drawbacks

- Obviously, this makes the Nix model more complicated than what it is now. In
  particular, the caching model needs some modifications (see [caching]);

- We specify that only a sub-category of derivations can safely be marked as
  `contentAddressed`, but there's no way to enforce these restricitions;

- This will probably be a breaking-change for some tooling since the output path
  that's stored in the `.drv` files doesn't correspond to the actual on-disk
  path the output will be stored in (because it might just be an alias for the
  other path)

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

In particular, the content (and the existence) of the physical path of the
static derivation isn't decided. A backwards-compatible choice would be to make
this a symlink to the dynamic path, but this is also very leaky and potentially
unsound.

## Garbage collection

Another major open issue is garbage collection of the aliases table. It's not
clear when entries should be deleted. The paths in the domain are "fake" so we
can't use them for expiration. The paths in the codomain could be used (i.e. if
a path is GC'ed, we delete the alias entries that map to it) but it's not clear
whether that's desirable since you may want to bring back the path via
substitution in the future.

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
