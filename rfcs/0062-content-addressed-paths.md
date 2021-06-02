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

Add some basic but simple support for content-addressed store paths to Nix.

We plan here to give the possibility to mark certain store paths as
content-adressed (ca), while keeping the other input-adressed as they are
now (modulo some mandatory drv rewriting before the build, see below).

By making this opt-in, we can impose arbitrary limitations to the paths that
are allowed to be ca to avoid some tricky issues that can arise with
content-adressability.

In particular, we restrict ourselves to paths that only include textual
self-references (_e.g._ no self-reference hidden inside a zip file).

That way we don't have to worry about the fact that hash-rewriting is only an
approximation.

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

*In everything that follows, most algorithms and data-structures will be expressed as pseudo-python snippets*

When it comes to computing the output paths of a derivation, the current Nix
model, known as the “input-addressed” model (also sometimes referred to as the
“extensional” model) works (roughly) as follows:

1. A Nix language expression gets evaluated to a `derivation`
2. This `derivation` is a data-structure describing how to build a package. In particular it contains
  1. A set of derivation outputs which will be used as input for the build
  2. A set of store paths that will be used as input for the build
  3. The build recipe proper (a script to run, with a set of environment
     variables). This recipe can refer input paths or derivations by
     interpolating their store path.
  4. The output paths into which the derivation will be installed.
    These are computed from a hash of the other elements of the derivation.

The “input-addressed” designation comes from the way the output paths are
computed: They derive from the derivation data-structure, which is the input of
the build.

The idea behind the “content-addressed” model is that rather than deriving
these output paths from the inputs of the build, we derive them from the output
(the produced store path).

Nix already supports a special-case of content-addressed derivations with the
so-called “fixed-output” derivations.  These are derivations that are
content-addressed, but whose output hash has to be specified in advance, and
are used in particular to fetch data from the internet (as the constraint that
the hash has to be specified in advance means that we can relax the sandbox for
these derivations).

To fully support this content-addressed model, we need to extend the current
build process, as well as the caching and remote building systems so that they
are able to take into account the specificies of these new derivations.

Fully supporting content-addressed derivations requires some deep changes to the Nix model.
For the sake of readability, we’ll first present a simplistic model that support them in a very basic way, and then extend this model in several different ways to improve the support.

## Basic support

The input-addressed build process is roughly the following:

```python
def nix_build(expr : NixExpr) -> [StorePath] :
    resulting_derivation = eval(expr)
    build_derivation(
        resulting_derivation,
        resulting_derivation.all_outputs(),
    )
    return resulting_derivation.all_output_paths()

def build_derivation(derivation : Derivation, outputsToBuild: [str]) -> ():
    # Build all the inputs
    for (inputDrv, requiredOutputs) in derivation.inputDrvs:
        build_derivation(inputDrv, requiredOutputs)
    # Run the build script, now that all the inputs are here
    runBuildScript(derivation)
```

The main change required by the content-addressed model is that we can’t know
the output paths of a derivation before building it.

This means that the Nix evaluator doesn’t know the output paths of the
dependencies it manipulates (it *could* know them if they are already built, but
that would be a blatant purity hole), so these derivations can’t neither embed
their own output path, nor explicitely refer to their dependencies by their
output path.

### Output mappings

For each output `output` of a derivation `drv`, we define

- its **Output Id** `DrvOutput(drv, output)` as the tuple `(hashModulo(drv), output)`.
  This id uniquely identifies the output.
  We textually represent this as `hashModulo(drv)!output`.
- its **realisation** `Realisation(outputId)` containing the path `outputPath` at which this output is stored (either content-defined or input-defined depending on the type of derivation)

```python
class DrvOutput:
    derivationHash : Hash
    outputName : str

class Realisation:
    id : DrvOutput
    outputPath : StorePath
```

In a input-addressed-only world, the concrete path for a derivation output was a pure function of this output's id that could be computed at eval-time. However this won't be the case anymore once we allow CA derivations, so we now need a way to register this information in the store:

```python
def registerRealisation(store : Store, realisation : Realisation):
    ...
```

For the local store, this function will store the realisation information in the Nix database as a new table:

```sql
create table if not exists Realisation (
    drvHash integer not null,
    outputName text not null,
    outputPath integer not null,
)
```

### Resolved derivations

As it is already internally the case in Nix, we define a **basic derivation** as a derivation that doesn't depend on any derivation output (except its own). Said otherwise, a basic derivation is a derivation whose only inputs are either

- Placeholders for its own outputs (from the `placeholder` builtin)
- Existing store paths

For a derivation `drv` whose input derivations have all been realised, we define its **associated resolved derivation** `resolved(drv)` as `drv` in which
we replace every input derivation `inDrv` of `drv` by `Realisation(inDrv).path`.

`resolved` is (intentionally) not injective: If `drv` and `drv'` only differ because one depends on `dep` and the other on `dep'`, but `dep` and `dep'` are content-addressed and have the same output hash, then `resolved(drv)` and `resolved(drv')` will be equal.

### content-addressed build process

We now need to update the build process as:

```python
def build_derivation(derivation : Derivation, outputsToBuild: [str]) -> Map[DrvOutput, Realisation]:
    inputRealisations : Map[DrvOutput, Realisation] = {}
    # Build all the inputs, and store the newly built realisations
    for (inputDrv, requiredOutputs) in derivation.inputDrvs:
        inputRealisations += build_derivation(inputDrv, requiredOutputs)

    # We now need to “resolve” our realisation to replace all the symbolic
    # references to its inputs by their actual store path
    derivationToBuild : BasicDerivation = resolved(inputDrv, inputRealisations)

    # At that point, we might realise that the resolved derivation is actually
    # something that we have already built. In that case we just return
    # the existing result.
    if (isBuilt(derivationToBuild)):
        return queryOutputs(derivationToBuild, outputsToBuild)

    # The build script needs to know where to install stuff (so that for
    # example `make install` can work properly).
    # We obviously don’t know the final path yet, but we can assign some
    # temporary output paths to the derivation that will be used during the
    # build.
    assignScratchOutputPaths(derivationToBuild)

    # Run the build script on the new resolved derivation
    runBuildScript(derivationToBuild)

    # Move the newly built outputs to their final (content-addressed) paths,
    # and return the corresponding realisations.
    return moveToCAPaths(derivationToBuild.outputs)
```

## Extensions

### Self-references

A store path `/nix/store/abc-foo` is said to be **self-referential** if the
content of the path mentions the path `/nix/store/abc-foo` itself (and this
mention of the store path is called a **self-reference**).

A lot of store paths happen to be self-referential (for example a path that contains both an dynamic library and an executable using that library will likely have the `rpath` of the exectuable mention the absolute path to the library).

It happens that these are problematic with content-addressed derivations, because
1. A self-reference means that the output path depends on the temporary path that has been used during the build (potentially breaking reproducibility as there’s no guaranty for this path to be stable),
2. More annoyingly, a self-reference means that the path can’t be moved freely (otherwise the self-reference would become dangling).

However, under the assumption that self-references only appear textually in the output (*i.e* running strings on a file that contains self-references will print all the self-references out), we can:

- Build the derivation on a temporary directory (`/nix/store/someArbitraryHash-foo`, the path provided by the function `assignScratchOutputPaths` above)
- Replace all the occurences of `someArbitraryHash` by a fixed magic value
- Compute the hash of the resulting path to determine the final path
- Replace the occurences of the magic value by the final path hash
- Move the result to the final path.

This is obviously a hack, however it seems to work very well in practice, due to the fact that:
- The string that we search for is a cryptographic hash that’s unlikely to occur by accident in the output path,
- Very few programs store self-references in a non-purely textual way

In addition, it is possible to detect the cases where this hash-rewriting isn’t total (see [the corresponding future work](#ensuring-that-no-temporary-output-path-leaks-in-the-result)).

### Mixing CA and non-CA derivations

The model so far assumes that the whole world switches to content-addressed derivations.
It’s however possible to freely mix content- and input-addressed derivations in the same Nix store, and even in the same closure:

The algorithm for building content-addressed derivations extends the algorithm for building input-addressed derivations in two ways:
1. Before running the build script, it resolves the derivation
2. When running the build script, it uses some temporary outputs, and moves them to their final location afterwards.

Only the second part assumes that the derivation is content-addressed, and we can use two-different code-paths for the build-step:

```python
def build_derivation(derivation : Derivation, outputsToBuild: [str]) -> Map[DrvOutput, Realisation]:
    # Build the dependencies and resolve the derivation like before
    derivationToBuild = ...

    if (derivationToBuild.isContentAddressed()):
        assignScratchOutputPaths(derivationToBuild)
        runBuildScript(derivationToBuild)
        return moveToCAPaths(derivationToBuild.outputs)
    else:
        runBuildScript(derivationToBuild)
        # If the derivation isn’t content-addressed, then it already knows its
        # own output paths
        return derivationToBuild.outputs
```

For backwards-compatibility, we must change the algorithm a bit further: Resolving an input-addressed derivation changes its input derivation and input path sets (it replaces every input derivation by the corresponding store paths).
This means that it also has to change the output paths (as these depend on the inputs of the derivation).

That’s something that we don’t want for the derivations that are already valid today, so we must bypass the resolving step for these derivations (which is okay as these derivations don’t need to be resolved).

```python
def build_derivation(derivation : Derivation, outputsToBuild: [str]) -> Map[DrvOutput, Realisation]:
    inputRealisations : Map[DrvOutput, Realisation] = {}
    # Build all the inputs, and store the newly built realisations
    for (inputDrv, requiredOutputs) in derivation.inputDrvs:
        inputRealisations += build_derivation(inputDrv, requiredOutputs)

    derivationToBuild =
        derivation if derivation.isStrictlyInputAddressed()
        else resolved(derivation, inputRealisations)

    if (derivationToBuild.isContentAddressed()):
        assignScratchOutputPaths(derivationToBuild)
        runBuildScript(derivationToBuild)
        return moveToCAPaths(derivationToBuild.outputs)
    else:
        runBuildScript(derivationToBuild)
        # If the derivation isn’t content-addressed, then it already knows its
        # own output paths
        return derivationToBuild.outputs
```

### Remote caching

#### Basic principles

A consequence of this change is that a store path is now just a meaningless
blob of data if it doesn't have its associated `realisation` metadata −
besides, Nix can't know the output path of a content-addressed derivation
before building it anymore, so it can't ask the remote store for it.

As a consequence, the remote cache protocols is extended to not simply
work on store paths, but rather at the realisation level:

- The store interface now specifies a new method
  ```python
  def queryRealisation(output : DrvOutput) -> Maybe Realisation
  ```

  If the store knows about the given derivation output, it will return the associated realisation, otherwise it will return `None`.
- The substitution loop in Nix fist calls this method to ask the remote for the
  realisation of the current derivation output.
  If this first call succeeds, then it fetches the corresponding output path
  like before. Then, it registers the realisation in the database:

  ```python
  def substitute_realisation(substituter : Store, wantedOutput : DrvOutput) -> Maybe Realisation:
      maybeRealisation = substituter.queryRealisation(wantedOutput)
      if maybeRealisation is None:
          return None
      substitute_path(substituter, maybeRealisation.outputPath)
      return maybeRealisation
  ```

On the binary cache side, they now have a new toplevel folder `/realisation` to store these realisations.
This folder contains a set of files of the form `{drvOutput}.doi`, each of them containing a Json serialisation of the realisation corresponding to the given `drvOutput`.

#### The “two-glibc” issue

As stated in [Eelco’s thesis][nixphd], remote caching of content-addressed derivations can be problematic in conjonction with non-determinism:

A typical scenario where this can happen is:

- Alice has `glibc` and `libfoo` built on her local store (with `libfoo` depending on `glibc`)
- She wants to build `firefox`, which depends on `libfoo` and `libbar`
- It happens that Bob-the-binary-cache contains `libbar`. `libbar` depends on `glibc`, but because the build of `glibc` isn’t deterministic, Bob actually has a different `glibc` (living in a different store path) than Alice.
- Alice fetches `libbar` from Bob. She also fetches Bob’s `glibc` as it’s a dependency of `libbar`
- Now alice uses `libfoo` and `libbar` to build `firefox`. But that means that `firefox` has both Alice’s `glibc` and Bob’s `glibc` in his closure (despite having only one specified in the derivation). After five hours of building, she starts `firefox` and it crashes with a cryptic “duplicated symbol” error. Now Alice is angry because Nix didn’t deliver on its promise of reproducibility and reliability.

The easiest way out of here is to make sure that Alice can’t have two different outputs for the same `glibc` dependency locally. So in the present case, she can’t use the `libfoo` that Bob offers as it wouldn’t be compatible.

The first step to that end, is to enforce the fact that a store can’t have more than one realisation for each derivation output. So it’s illegal to register the realisation for Alice’s `glibc` and Bob’s `glibc` at the same time.
We must also extend the notion of Realisation to keep track of their dependencies: In the example above, when the substitution mechanism will try to substitute a realisation for `libfoo` from Bob it, it will query Bob for the realisation, see that its output path is `/nix/store/abc-libfoo` and substitute this path (with its dependencies, so including `/nix/store/123-glibc`). But it will never try to register a realisation for Glibc.

To fix this, we must extend a bit the notion of realisation, to keep track of its dependencies: On Bob’s store, `libfoo` is realised as `/nix/store/abc-libfoo`, but this realisation depends on the fact that `glibc` is realised as `/nix/store/123-glibc`.

- Realisations now contain a `dependencies` field, which is a map from `DrvOutput` to `StorePath`:

    ```python
    class Realisation:
        id : DrvOutput
        outputPath : StorePath
        dependencies : Map[DrvOutput, StorePath]
    ```
- We add the constraint that realisations should form a closure in a store, meaning that if a store has the realisation for `foo!out` with a dependency on `bar!out->/nix/store/bar`, then the store must also have a realisation for `bar!out` whose output path is `/nix/store/bar`
- The realisation loop now keep tracks of these realisations to enforce this closure invariant:
  ```python
  # Returns true (and warns) iff we already have a realisation for the given
  # derivation output, and that realisation has a different output path
  # than the expected one.
  def is_incompatible(drvOutput, expectedStorePath):
      maybeLocalRealisation = localStore.queryRealisation(drvOutput)
      if (maybeLocalRealisation and maybeLocalRealisation.outputPath != expectedStorePath):
          warn(f"The substituter {substituter} has an incompatible realisation for {dependentDrvOutput}")
          return True
      return False


  def substitute_realisation(substituter : Store, wantedOutput : DrvOutput) -> Maybe Realisation:
      maybeRealisation = substituter.queryRealisation(wantedOutput)
      if maybeRealisation is None:
          return None

      # Try substituting the derivations we depend on
      for (dependentDrvOutput, expectedStorePath) in maybeRealisation.dependencies:
          if is_incompatible(dependentDrvOutput, expectedStorePath)
              return None
          else:
              substitute_realisation(substituter, wantedOutput)

      # Finally substitute the store path itself
      substitute_path(substituter, maybeRealisation.outputPath)
      return maybeRealisation
  ```

### Signatures

Input-addressed paths need to be signed because there’s no way to verify their content (short of rebuilding them and praying that the build is deterministic of course): If `/nix/store/123-foo` is input-addressed, then there’s no direct relation between the hash `123` and the content of the store path.

Content-addressed paths on the other hand don’t need a signature: If `/nix/store/123-foo` is content-addressed, then `123` is supposed to be a hash of the content of the path, and that can be easily checked.
However, content-addressed realisations must be signed as there’s no simple deterministic relation between a derivation and its output paths. To that end, we extend the `Realisation` type to also include a set of signatures.

```python
class Realisation:
    ...

    signatures : Set[str]

    def sign(key : PrivateKey):
        ...
    def verify_signature(key : PublicKey):
        ...
```

We also update `registerRealisation` for the local store to check these signatures before actually registering anything in the database.

# Drawbacks

[drawbacks]: #drawbacks

- Obviously, this makes the Nix model more complicated than it currently is. In
  particular, the caching model needs some modifications (see [caching]);

- We specify that only a sub-category of derivations can safely be marked as
  `contentAddressed`, but there's no way to enforce these restricitions;

- This will probably be a breaking-change for some tooling since the output path
  that's available at eval-time and stored in the `.drv` files doesn't
  correspond to an actual on-disk path.

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

# Future work

[future]: #future-work

This RFC tries as much as possible to provide a solid foundation for building
ca paths with Nix, leaving as much room as possible for future extensions.
In particular:

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

## Make content-addressed derivations compatible with other Nix features

As presented here, content-addressed derivations are incompatible with a few Nix features (in particular import from derivation and recursive Nix).

## Enabling a truly multi-user trust-model

One of the theoretical advantages of the content-addressed model is that it separates the trust (materialised by the realisations) and the storage (the store paths), meaning that several users can share the same Nix store, but have each a different trust relation to it.

This means that each user could be a “trusted-user” for its own view of the store, without affecting the others.

[rfc 0017]: https://github.com/NixOS/rfcs/pull/17
[nixphd]: https://nixos.org/~eelco/pubs/phd-thesis.pdf
