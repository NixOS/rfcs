---
feature: plan-dynamism
start-date: 2019-02-01
author: John Ericson (@Ericson2314)
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

We need build plan dynamism -- interleaved building and planning -- to cope with the ever-growing world of language-specific package managers.
Propose to allow derivations to build derivations, and depend on those built derivations, as the core primitive for this.
Additionally, introduce a new primop to leverage this in making "import from derivation" (IFD), still the gold standard for ease of use, more efficient and compatible with `hydra.nixos.org`'s queue runner.

# Motivation
[motivation]: #motivation

Nix's design encourages a separation of build *planning* from build *execution*:
evaluation of the Nix language produces derivations, and then then those derivations are built.
This usually a great thing.
It's enforced the separation of the more complex Nix expression language from the simpler derivation language.
It's also encouraged Nixpkgs to take the "birds eye" view and successful grapple a ton of complexity that would have overwhelmed a more traditional package repository.

Nixpkgs, along with every other distro, also faces a looming crisis: new open source software is increasingly not intended to be packaged by distros at all.
Many languages now support very large library ecosystems, with dependencies expressed in a language-specific package manager.
To this new generation of developers, the distro (or homebrew) is a crufty relic from an earlier age to bootstrap modernity, and then be forgotten about.

Right now, to deal with these packages, we either convert by hand, or commit lots of generated code into Nixpkgs.
But I don't think either of those options is healthy or sustainable.
The problem with the first is sheer effort; we'll never be able to keep up.
The problem with the second is bloating Nixpkgs but more importantly reproducability: If someone wants to update that generated code it is unclear how.
All these mean that potential users coming from this new model of development find Nix / Nixpkgs cumbersome and unsuited to their needs.

The core feature here, derivations that build derivations, is the best fundamental primitive for this problem.
It's very performant, being well-adapted for Nix's current scheduler.
Unlike recursive Nix, there's is no potential for half-built dependencies to sit around waiting for other builds, wasting resources.
Each build step (derivation) always runs start to finish blocking on nothing.
It's very efficient, because it doesn't obligate the use of the Nix expression language.
Finally, it's quite compatible with `--dry-run`.

However, "import from derivation" is still far and away the easiest method to use, and the one that existing tools to convert to Nix use.
\[Actually it's not just `import` which is notable, one can `builtins.readFile` a not-yet-buit path and it will also block today, and probably other such primops.
The exact primop doesn't matter --- all are noticeably more ergonomic than alternatives, and our proposal here is agnostic to the prim-op which would trigger the blocking.
I will continue to use "IFD" as an umbrella acronym despite its deficiencies because it is best known.\]
We should continue to support it, finding a way for `hydra.nixos.org` to allow it, so those tools with IFD can be used in Nixpkgs and become first-class members of the Nix ecosystem.
We have a fairly straightforward mechanism, only slightly more cumbersome than IFD today, to allow evaluation to be deferred after imported things are built.
This frees up the Hydra evaluator to finish before building, and also meshes well with any plan to build more than one eval-realized path at a time.
This should allow us to drop the `hydra.nixos.org` restriction.

With these steps, I think we will be able to successfully convert to Nix a bunch of developers that mainly work in one language, and didn't even think they were in need of a better distro.
In turn, I hope these upstream packages and ecosystems might even care about packaging and integration of the sort that we do.
This would create a virtuous cycle where Nix is easier to use by more people, and Nixpkgs is easier to maintain as upstream packages better match our values.

# Detailed design
[design]: #detailed-design

We can break this down nicely into steps.

## Dynamic derivations

*This is implemented in https://github.com/NixOS/nix/pull/4628.*

1. Derivation outputs can be valid derivations.
   \[If one tries to output a drv file today, they will find Nix doesn't accept the output as such because these small paper cuts.
   This list item and its children should be thought of as "lifting artificial restrictions".\]

   1. Allow derivation outputs to be content addressed in the same manner as drv files.
      (The little-exposed name for this is "text" content addressing).

   2. Lift the (perhaps not yet documented) restriction barring derivations output paths from ending in `.drv`, but only for derivation outputs that are so content-addressed.
      \[There are probably other ways to make store paths that end in `.drv` that aren't valid derivations, so we could make the simpler change of lifting this restriction entirely without breaking invariants. But I'm fine keeping it for the wrong sorts of derivations as a useful guard rail.\]

2. Extend the CLI to take advantage of such derivations:

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

   Plain paths just mean that path itself is the goal, while `!` indexing indicates one more outputs of the derivation to the left of the `!` is the goal.

   > For example,
   > ```
   > nix build /nix/store/…foo.drv
   > ```
   > would just obtain `/nix/store/…foo.drv` and not build it, while
   > ```
   > nix build /nix/store/…foo.drv!*
   > ```
   > would obtain (by building or substituting) all its outputs.
   > ```
   > nix build /nix/store/…foo.drv!out!out
   > ```
   > would obtain the `out` output of whatever derivation `/nix/store/…foo.drv!out` produces.

   Now that we have `path` vs `path!*`, we also don't need `--derivation` as a disambiguator, and so that should be removed along with all the complexity that goes with it.
   (`toDerivedPathsWithHints` in the the nix commands should always be pure functions and not consult the store.)

3. Extend the scheduler and derivation dependencies similarly:

  - Derivations can depend on the outputs of derivations that are themselves derivation outputs.
    The scheduler will substitute derivations to simplify dependencies as computed derivations are built, just like how floating content addressed derivations are realized.

  - Missing derivations get their own full fledged goals so they can be built, not just fetched from substituters.

4. Add a new `outputOf` primop:

   `builtins.outputOf drv outputName` produces a placeholder string with the appropriate string context to access the output of that name produced by that derivation.
   The placeholder string is quite analogous to that used for floating content addressed derivation outputs.
   \[With just floating content-addressed derivations but no computed derivations, derivations are always known statically but their outputs aren't.
   With this RFC, since derivations themselves can floating CA derivation outputs, we also might not know them statically, so we need "deep" placeholders to account for arbitrary layers of dynamism.
   This also corresponds to the use of arbitrary many `!` in the CLI.\]

## Deferred import from derivation.

Create a new primop `assumeDerivation` that takes a single expression.
It's semantics are as follows:

 - If the underlying expression evaluates (shallowly) without needing to build derivations (for `import`, `readFile`, etc.), and is a derivation, simply return that.
   ```
   e ⇓ e'
   e' is derivation
   ------
   builtins.assumeDerivation e ⇓ e'
   ```

- If the underlying expression cannot evaluate (shallowly) without building one or more paths, defer evaluation into a derivation-producing-derivation, and take it's output with `builtins.outputOf`:
  ```
  e gets stuck on builds
  defer = derivation {
    inputDrvs = builds;
    buildCommand = "nix-instantiate ${reified e} > $out"
  }
  ------
  builtins.assumeDerivation e ⇓ builtins.outputOf defer "out"
  ```

This allows downstream non-dynamic derivations to be evaluated without getting stuck on their dynamic upstream ones.
They just depend on the derivation computed by the deferred eval derivations, and those substitutions are performed by the scheduler.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

Here is everything put together with a Haskell and `cabal2nix` example.

Given the following code, and assuming `bar` will depend on `foo`
```nix
mkScope (self: {
  foo = builtins.assumeDerivation (self.callCabal2nix "foo" ./foo);
  bar = builtins.assumeDerivation (self.callCabal2nix "bar" ./bar);
})
```
After some evaluation, we get something like the following derivations with dependencies:
```
(cabal2nix foo)!out ----> deFoo = deferred eval (fooNix: self.callPackage fooNix)
(cabal2nix bar)!out ----> deBar = deferred eval (barNix: self.callPackage barNix)
```
and evaluated nix
```nix
mkScope (self: {
  foo = builtins.outputOf /nix/store/deFoo.drv "out";
  bar = builtins.outputOf /nix/store/deBar.drv "out";
})
```

If we then build `bar` we will get something steps like:

1. ```
   deBar!out
   ```
2. Expand `deBar` in to see dep
   ```
   ((cabal2nix bar)!out ----> (deferred eval (fooNix: self.callPackage barNix {}))!out
   ```
3. Build cabal2nix and inline path for simplicity (or if cabal2nix job is floating CA derivation)
   ```
   (deferred eval self.callPackage built-barNix)!out
   ```
4. Build deferred eval job and substitute
   ```
   deFoo!out ----> bar.drv!out
   ```
5. Expand `deFoo` in to see dep
   ```
   ((cabal2nix foo)!out ----> (deferred eval (fooNix: self.callPackage fooNix {}))!out ----> bar.drv!out
   ```
6. Build cabal2nix and inline path for simplicity (or if cabal2nix job is floating CA derivation)
   ```
   (deferred eval self.callPackage built-fooNix)!out ----> bar.drv!out
   ```
7. Build deferred eval job and substitute
   ```
   foo.drv!out ----> bar.drv!out
   ```
8. Build foo and realize bar
   ```
   bar.drv[foo-path/foo!out]!out
   ```
9. Build bar
   ```
   bar-path
   ```

The above is no doubt hard to read -- I am sorry about that --- but here are a few things to note:

 - The scheduler "substitutes on demand" giving us a lazy evaluation of sorts.
   This means that in the extreme case where we to make to, e.g., make a derivation for every C compiler invocation, we can avoid storing a very large completely static graph all at once.
   
 - At the same time, the derivations can be built in many different orders, so one can intentionally build all the `cabal2nix` derivations first and try to accumulate up the biggest static graph with `--dry-run`.
   This approximates what would happen in the "infinitely parallel" case when the scheduler will try to dole out work to do as fast as it can.

# Drawbacks
[drawbacks]: #drawbacks

The main drawback is that these stub expressions are *only* "pure" derivations --- placeholder strings (with the proper string context) and not attrsets with all the niceties we are used to getting from `mkDerivation`.
This is true even when the deferred evaluation in fact *does* use `mkDerivation` and would provide those niceties.
For other sort of values, we have no choice but wait; that would require a fully incremental / deferral evaluation which is a completely separate feature not an extension of this.
Concretely, our design means we cannot defer the `pname` `meta` etc. fields: either make do with the bare string `builtins.outputOf` provides, or *statically* add a fake `name` and `meta` etc. that must be manually synced with the deferred eval derivation if it is to match.

# Alternatives
[alternatives]: #alternatives

 - Do nothing, and continue to have no good answer for language-specific package managers.
 
 - Instead of deferring only certain portions of the evaluation with `builtins.asssumeDerivation`, simply restart the entire eval.
   Quite simple, and no existing IFD code today needs to change.
   
 - Abandon IFD and just let users use the underlying dynamic derivation feature.
   This was my first idea, but I became worried that this was too hard to use for simple experiments.

# Unresolved questions
[unresolved]: #unresolved-questions

The exact way the outputs refer to the replacement derivations / their outputs is subject to bikeshedding.

# Future work
[future]: #future-work

1. Actually use this stuff in Nixpkgs with modification to the existing "lang2nix" tools.
   This is the lowest hanging fruit and most import thing.

2. Try to breach the build system package manager divide.
   Just as there are foreign packages graphs to convert to Nix, there are Ninja and Make graphs we can also convert to Nix.
   This might really help with big builds like Chromium and LLVM.
   
3. Try to convince upstream tools to use Nix like CMake, Meson, etc. use Ninja.
   Rather than converting Ninja plans, we might convince those tools to have purpose-built Nix backends.
   Language-specific package mangers that don't use Ninja today might also be modified to "let Nix do that actual building".
