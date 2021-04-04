---
feature: drv-build-drv
start-date: 2019-02-01
author: John Ericson (@Ericson2314)
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Allow derivations to build derivations, and extend our notion of derivation dependencies to include built and not just pre-existing derivations.
This provides an alternative to "import from derivation" and recursive Nix that avoids many of their drawbacks.

# Motivation
[motivation]: #motivation

Nix's design encourages a separation of build *planning* from build *execution*:
evaluation of the Nix language produces derivations, and then then those derivations are built.
This usually a great thing.
It's enforced the separation of the more complex Nix expression language from the simpler derivation language.
It's also encouraged Nixpkgs to take the "birds eye" view and successful grapple a ton of complexity that would have overwhelmed a more traditional package repository.

However, there are sometimes situations where planning and execution has to be intermixed.
Often this is in the converting of other build systems to Nix derivations, with `cabal2nix`, `crate2nix`, etc.
Other times this is with extracting dependency information from the source itself, like C++20 modules or, hopefully someday, Haskell modules.
While it's possible to do all this in one big expensive planning phase, it's much better to start with a courser dependency graph and then refine it.

The two tools we have today for this, "import from derivation" and (still unstable) recursive have serious drawbacks.
Import from derivation builds imported derivations one at a time due to the design of evaluator.
Even if that were fixed (and it should be!), it more fundamentally flawed because it requires the evaluation heap/interpreter process to still persist until all the imported derivations are built.
That makes it is a bad architecture for fine-grained, resumable work.

The other, recursive Nix, has similar issues.
With `nix-build` in `nix-build`, we again, we have an outer step that blocks awkwardly while the inner one continues.
And whereas at least evaluation state is a known-entity that could be persisted or garbage collected, the output process tree and other state is a truly inscrutable black box.
At the very least, all this breaks `--dry-run`.

There's also a social argument.
"`nix-build` in `nix-build`"is an extremely crude cudgel.
As I wrote above, it's very good that we push people towards separating planning and building.
"`nix-build` in `nix-build`" is just too mindlessly imperative, and I fear as Nix grows more popular it could be the vuvuzela of an External September.
It's very important that people only use dynamism as a last resort, and it's properly functional, and as powerful and flexible as possible.

Note that none of this applies to "`nix-instantiate` in `nix-build`".
The limited form of recursive Nix that just allows adding data to the store is fine with me, and I will use it in conjunction with this
Morally, it's just an implementation of derivation producing store path graphs that have dynamic shape, instead of multiple outputs static shape.
That's a great feature.

Derivation that build derivations is just that.
It's quote simple to imagine each step: once a derivation is built it's treated like any other.
And now that we have content-addressed derivation outputs (since the derivations themselves must be content address, built or otherwise) we've done all the hard parts!
Yet, this one small feature makes the derivation language fully higher order and capable of embedding e.g. the lambda calculus.
That's awesome, in both the positive and terrifying senses.

# Detailed design
[design]: #detailed-design

We can break this down nicely into steps

#. Derivation outputs can be valid derivations:

   #. Allow derivation outputs to be content addressed with the "text hashing" scheme.

   #. Lift the restriction barring derivations output paths from ending in `.drv` if they are so content-addressed

#. Extend the CLI to take advantage of such derivations:

   We hopefully will soon allow CLI "installable" args in the form
   ```
   single-installable ::= <path> ! <output-name>
   ```
   where the first path is a derivation, and the second is the output we want to build.

   We should generalize the grammar like so:
   ```
   single-installable ::= <single-installable> ! <output-name>
                       |  <path>

   multi-installable  ::= <single-installable>
                       |  <single-installable> ! *
   ```

   Now that we have `path` vs `path!*`, we also don't need `---derivation` as a disambiguator, and so that should be removed along with all the complexity that goes with it.
   (`toBuildables` in the the nix commands should always be pure functions and not consult the store.)

#. Extend the scheduler and derivation dependencies similarly:

   #. Extend data structures.

     The `DerivationGoal` keys are currently a derivation path and a set up output names, with an empty set denoting "all outputs".
     We should generalize the derivation path to be as powerful as our new `<single-installable>`.
     Thus, we'll have a vector of output names "between" the root drv path, and the final set of output names.

     The type of `inputDrvs` is conceptually `Set<SingleInstallable>`, but actually a map from drv paths to outputs.
     It should stay conceptually `Set<SingleInstallable>`, but perhaps to keep the map structure we will do some fancy recursive thing for its concrete implementation.

   #. Derivation goals working from a built derivation during the derivation loading step will instead spawn a subgoal for the derivation goal bilding the derivation.
      Inductively we eventually reach the base case of static derivation, and those are built just like today.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

I'll make Haskell and cabal2nix my running example.

`cabal2nix` today is used something like:
```nix
haskellPackages.callPackage "something" (runCommand {} "cabal2nix ${mySrc} > $out") {}
```
This is pretty good, except for the issues given in the motivation section.

With "`nix-build` in `nix-build`" it's would be something like:
```nix
runCommand "something" {} ''
  cabal2nix ${mySrc} > default.nix
  nix-build -E '(import ${pkgs.path} {}).haskellPackages.callPackage ./. {};'
''
```
This is terrible.
In addition to the problems given inn the motivation section, we redo the `cabal2nix` whenever *anything at all* changes in the Nixpkgs source.
That's a lot of unnecessary rebuilds.
```nix
runCommand "something-continued" {} ''
  nix-build -E '(import ${pkgs.path} {}).haskellPackages.callPackage \
    ${runCommand "something-continued" {} "cabal2nix ${mySrc} > $out"} \
    {};'
''
```
This solves that additional problem, but is quite a mouthful.
Do we really think people are going to write this without lineters nagging?
The ease of use is trap that will lead people to think this about Nix "simple things work bad, and things that work well are ugly".
And even after all that, the motivation section problems still remain.

The new way is
```nix
runCommand "something.drv" {} "cabal2drv ${mySrc} > $out"
```
if we want to bypass the Nix language entirely.

If we don't, there is:
```nix
runCommand "something-evaluated" {} ''
  nix-instantiate -E '(import ${pkgs.path} {}).haskellPackages.callPackage \
    ${runCommand "something" {} "cabal2nix ${mySrc} > $out"} \
    {};'
''
```
Yes, this is the same ugliness as before.
However, there's at least no temptation to write any more commands after the `nix-instantiate`, since we must finish the derivation to build what we've instantiated.
That will compel people to have fine grained derivations with a single `nix-instantiate` each.
Also, I hope we could in fact auto-generate this from import-from-derivations, which remains the nicest interface.


The benefits of recursive Nix have been described in many places.
One main reason is if we want Nix to function as a build system and package manager, we need upstream packages to use Nix too without duplicating their build systems in Nixpkgs.
For this case, people usually imagine derivations like
```nix
{ stdenv, pkgs, nix }:

stdenv.mkDerivation {
  name = "foo";
  version = "1.2.3";

  src = ...;

  nativeBuildInputs = [ nix ];
  NIX_PATH = "nixpkgs=${pkgs.path}";

  outputs = [ "out" "dev" ];

  doConfigure = false;
  doBuild = false;

  installPhase = ''
    for o in $outputs; do
      pkg=$(nix-build -E '((import <nixpkgs> {}).callPackage ./. {}).'"$o")
      cp -r $pkg ${!o}
    done
  '';
}
```
The other main reason is other build systems should be translated to Nix without vendoring tons of autogenerated code in Nixpkgs.
For this, case, the one difference is we need to generate some Nix first.
```nix
stdenv.mkDerivation {
  # ...
  installPhase = ''
    bazel2nix # new bit
    for o in $outputs; do
      pkg=$(nix-build -E '((import <nixpkgs> {}).callPackage ./. {}).'"$o")
      cp -r $pkg ${!o}
    done
  '';
}
```

"Ret-cont" recursive Nix, short for "return-continuation" recursive Nix, is a different take on recursive Nix.
The normal variant in the examples above might be termed "direct-style" recursive Nix.
Consider what happens with the recursive "nix-build" in those examples:
the outer build blocks while the inner one builds, and then the other one continues.
Just as we can CPS-transform programs, reifying the context of a function call as another function (which is passed as an argument), so we can imagine splitting the derivation in two at this blocking point.
This gives the "continuation" part of the name.
But whereas the CPS transformation makes the continuation an argument, the Nix *derivation* language is first order.
Instead, we can produce a derivation which has the callee as a dependency, and continuation drv downstream depending on it.
Since the outer derivation evaluates (builds) the inner derivation rather than calling anything, I deem that it returns the derivation.
This gives the "return" part of the name.
Both differences together, the first example becomes something like:
```nix
{ stdenv, pkgs, nix }:

stdenv.mkDerivation {
  name = "foo";
  version = "1.2.3";

  src = ...;

  nativeBuildInputs = [ nix ];
  NIX_PATH = "nixpkgs=${pkgs.path}";

  __recursive = true;

  outputs = [ "drv" ];

  doConfigure = false;
  doBuild = false;

  installPhase = ''
    mv $(nix-instantiate -E '((import <nixpkgs> {}).callPackage ./. {})') $drv
  '';
}
```
Note how in this case we don't need to do any "post-processing" of the produced derivation.
When the outer derivation can just "become" the inner derivation, explicitly copying the derivation outputs like before becomes unnecessary.

So why prefer this variation of the standard design?
I've always been concerned with the ease of which someone can just "nix-build ...; nix-build ...; nix-build ..." within a derivation with recursive Nix.
This creates a linear chain of dependencies, which isn't terribly performant: shorter critical paths are crucial for parallelism and incrementality and this fails with both.
Building derivations is less convenient, but makes linear chains and the proper dependency graph *equally* less convenient, removing the perverse incentive.
And in general, dynamism in the dependency graph, which is the essence of what recursive Nix provides, is only a feature of last resort, so making it more difficult across the board isn't concerning.

Additionally, see https://github.com/edolstra/nix/commit/1a27aa7d64ffe6fc36cfca4d82bdf51c4d8cf717 for Eelco's draft implementation of recursive Nix, and the Darwin sandboxing restrictions that make it a Linux-only feature.
Sandboxing and Darwin are crucial to Nix today, and we shouldn't sacrifice either of them.
With "ret-cont" recursive Nix, actual builds are never nested, so we don't need any fancy constraints on the derivation "runtime" (i.e. the code that actually performs and isolates builds).
Furthermore, we can skip needing to talk to the daemon by just producing a local store:
```nix
stdenv.mkDerivation {
  # ...
  outputs = [ "drv" "store" ];
  installPhase = ''
    mv $(nix-instantiate --store $store -E '((import <nixpkgs> {}).callPackage ./. {})') $drv
  '';
}
```
This further simplifies the implementation.
Derivations remain built exactly as today, with only logic *between* building steps that is entirely platform-agnostic changing.

As a running example, I'll use @matthewbauer's [Reproducible résumé].
(Do steal the method; don't steal Matt; he works with me!)
Here's the original `default.nix`, which uses IFD:

```nix
{nixpkgs ? <nixpkgs>}: with import nixpkgs {};
let

README = stdenv.mkDerivation {
  name = "README";
  unpackPhase = "true";
  buildInputs = [ emacs ];
  installPhase = ''
    mkdir -p $out
    cd $out
    cp -r ${./fonts} fonts
    cp ${./README.org} README.org
    emacs --batch -l ob-tangle --eval "(org-babel-tangle-file \"README.org\")"
    cp resume.nix default.nix
  '';
};

in import README {inherit nixpkgs;}
```

The shortest way to make it instead use "Ret-cont" recursive Nix is this:

```nix
{nixpkgs ? <nixpkgs>}: with import nixpkgs {};

stdenv.mkDerivation {
  name = "README";
  unpackPhase = "true";
  outputs = [ "drv" "store" ];
  __recursive = true;
  buildInputs = [ emacs nix ];
  installPhase = ''
    mkdir -p $out
    cd $out
    cp -r ${./fonts} fonts
    cp ${./README.org} README.org
    emacs --batch -l ob-tangle --eval "(org-babel-tangle-file \"README.org\")"
    mv $(nix-instantiate --store $store resume.nix --arg nixpkgs 'import ${nixpkgs.path}') > $drv
  '';
}
```

But note how this means we re-run emacs every time anything in Nixpkgs changes, no good!
Here's a better version which is more incremental:

```nix
{nixpkgs ? <nixpkgs>}: with import nixpkgs {};
let

# Just like original
README = stdenv.mkDerivation {
  name = "README";
  unpackPhase = "true";
  buildInputs = [ emacs ];
  installPhase = ''
    mkdir -p $out
    cd $out
    cp -r ${./fonts} fonts
    cp ${./README.org} README.org
    emacs --batch -l ob-tangle --eval "(org-babel-tangle-file \"README.org\")"
    cp resume.nix default.nix
  '';
};

in stdenv.mkDerivation {
  name = "readme-outer";
  unpackPhase = "true";
  buildInputs = [ nix ];
  outputs = [ "drv" "store" ];
  __recursive = true;
  installPhase = ''
    mv $(nix-instantiate --store $store ${README} --arg nixpkgs 'import ${nixpkgs.path}') > $drv
  '';
}
```

Now only `readme-outer` is rebuilt when Nixpkgs and Nix changes.
This may still seem wasteful, but remember we still need to reevaluate whenever those changes.
Now some of that evaluation work is pushed into the derivations themselves.

This is actually a crucial observation:
A limit to scaling Nix today is that while our builds are very incremental, evaluation isn't.
But if we can "push" some of the work of evaluation "deeper" into the derivaiton graph itself, we can be incremental with respect to both.
This means we are incremental at all levels.

# Drawbacks
[drawbacks]: #drawbacks

 - The opinionated nature may put off those who think Nix is too hard to learn already, and think simple recursive "nix-build" is good for newcomers.

 - If we ever want full recursive Nix, this doesn't really build in that direction.
   It sidesteps the bulk of the difficulty which is in making the nested sandboxing and daemon communication secure.
   To me though, this is a feature not a bug; I don't want to go in that direction just yet.

# Alternatives
[alternatives]: #alternatives

 - Don't allow fixed-output builds.
   All data can be stuck inside the drv file, so this can be cut without limiting expressive power.
   But this is much less efficient, and more cumbersome for whatever produces the data.

 - Use a socket to talk to the host daemon.
   https://github.com/edolstra/nix/commit/1a27aa7d64ffe6fc36cfca4d82bdf51c4d8cf717, a draft implementation of full recursive Nix, has done this and we can take the details from that.
   This might sightly more efficient by reducing moving files, but is conceptual overkill given this design.
   No direct access to the host daemon rules out a bunch of security concerns, and simplifies the interface for non-Nix tools producing derivations.
   The latter I very much hope will happen, just as Ninja is currently used with CMake, Meson, etc., today.

 - Full recursive Nix (builds within builds)

 - Import from derivation.
   This has been traditionally considered an alternative to this, but I will soon propose an implementation of that relying on this; I no longer consider the two in conflict.

 - `builtins.exec` runs an arbitrary command at eval time as the user triggering evaluation.
   This is highly impure; nothing at all tries to make the environment deterministic.
   It is useful for writing fetchers that need the impurities to access the internet and secrets, while also managing their own caching.
   But for everything else, I view it strictly worse than IFD.

 - Keeping the status quo and use vendoring.
   But then Nix will never scale to bridging the package manager and build system divide.

# Unresolved questions
[unresolved]: #unresolved-questions

The exact way the outputs refer to the replacement derivations / their outputs is subject to bikeshedding.

# Future work
[future]: #future-work

1. As the example shows, we can push the work of evaluation into builds.
   This unlocks lots of future work in Nixpkgs:

   - Leveraging language-specific tools to generate plans Nix builds, rather than reimplementing much of those tools.
     We do this with IFD today, but both due to Hydra's architecture, and concerns about eval times regardless of Hydra, we don't allow this in Nixpkgs.
     This is a huge loss as we either do things entirely manually (python) Or vender tons of code (Haskell).
     We will save valuable human time, and start to bridge the distribution / ops vs developer cultural divide by making it easier to work on your own packages.

   - Simply fetching and importing packages which use Nix for their build system, like Nix itself and hydra, rather than vendoring that build system in.
     This is an easier special case of the above, where the upstream developer knows and loves Nix, and their package has a Nix-based build system.
     Flakes are supposed to help with this, as is `builtins.fetchTarball` skirting the IFD prohibition.
     But, it's better if the hydra evaluator can avoid blocking on the download and/or evaluating the Nix expressions therein.
     "Ret-cont" recursive Nix would allow this by just putting the "outer" derivation in Nixpkgs.

   As an example of the former, Ninja (is getting)[Ninja Dyndeps] a very similar notion they call `dyndep`s in their upcoming release.
   This is needed for C++ and Fortran modules.
   If CMake and other tools use it as expected, we would need "Ret-cont" to automatically translate their build plans for fine-grained builds of large projects like LLVM or Chromium.
   Shake, soon Ninja, and eventually [LLBuild], are the only general purpose build systems I know that do or aim to do dynamic dependencies, but none of them sandbox.
   If we become the only way to both correctly and incrementally build modern C++, that will be a huge opportunity for further growth.

2. Better still, we can try to automatically transform evaluation without writing manually "outer" derivations.
   With `--pure` mode, Eelco has also talked about opening the door to caching evaluation.
   "Ret-cont" recursive Nix is wonderful foundation for that.

   I hope to at least later proposal automatically converting IFD into "Ret-cont":

   IFD is also slow because the evaluator isn't concurrent and so imported derivations get built one at a time.
   We can fix this somewhat by modifying the evaluator so that evaluation continues where the *value* of the previously-imported derivation isn't needed.
   But, we still will inevitably get stuck somewhere shallower in the expression when the value being built is needed.

   With "Ret-cont", we can cleverly avoid needing that value in certain common situations.
   Quite often, IFD is creating a derivation, so we will have something like:

   ```nix
   "blah blah blah ${/*some expression ... is stuck because deep inside: */ (import /* ... */) /* ... */} blah blah blah"
   ```

   Without knowing what the value of that expression is, we may reasonably assume it's coercible to a string.
   If it isn't, well, evaluation will fail anyways.
   We can then make a "scratch" derivation, however, that reifies the evaluation of the stuck term, we can splice the scratch derivation's hash instead:

   ```nix
   "bash balh blash /nix/store/123asdf4sdf1g2dfgh34fg8h7fg69876-i-like-to-procrastinate-and-hope-for-the-best blah blah blah"
   ```

   Now, evaluation truly isn't stuck at all, and we are as free to continue as if there was no IFD at all!
   The only failure mode would be if the import was a string but *wasn't* a derivation.
   But, I imagine we can annotate things such that Nix knows when to speculate like this.
   (c.f. Compiler hot and cold pragmas.)
   The author of the Code almost always knows what *type* of thing they are splicing, so I would think we could so annotate quite faithfully.
   I emphasize "type" because if we ever get a type system, this becomes much easier:
   Specifying types for imported expressions (along with other explicit signature to guide inference) is wholly sufficient to derive the type of all such splices.

  Another future project would be some speculative strictness to allow one round of evaluation to return *both* a partial build plan and stuck imported derivations.
  Currently the plan must still be evaluated entirely before any building of "actually needed" derivations, i.e. those which *aren't* imported, begins.

3. More broadly, we can get rid of a special notion of "evaluation" entirely.
   We can think of evaluation today as basically a special case single layer of dynamism, where the outer work (evaluation) is impure.
   If all `--pure` and IFD evaluation is done inside Nix builds, then the Nix daemon need not even know about the nix language at all.
   We can have completely separate tools running inside sandboxes that deal with the Nix expression langauge.

[Reproducible résumé]: https://github.com/matthewbauer/resume

[Ninja Dyndeps]: https://github.com/ninja-build/ninja/pull/1521

[LLBuild]: https://github.com/apple/swift-llbuild
