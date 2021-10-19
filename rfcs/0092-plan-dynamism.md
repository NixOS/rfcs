---
feature: plan-dynamism
start-date: 2019-02-01
author: John Ericson (@Ericson2314)
co-authors: Las Safin (@L-as)
shepherd-team: @tomberek, @ldesgoui, @gytis-ivaskevicius, @L-as
shepherd-leader: @tomberek
related-issues: https://github.com/NixOS/nix/pull/4628 https://github.com/NixOS/nix/pull/5364 https://github.com/NixOS/nix/pull/4543 https://github.com/NixOS/nix/pull/3959
---

# Summary
[summary]: #summary

We need build plan dynamism -- interleaved building and planning -- to cope with the ever-growing world of language-specific package managers.
Propose to allow derivations to build derivations, and depend on those built derivations, as the core primitive for this.
Additionally, introduce a new primop to leverage this in making "import from derivation" (IFD), still the gold standard for ease of use, more efficient and compatible with `hydra.nixos.org`'s queue runner.

# Motivation
[motivation]: #motivation

> Instead of Recursive Nix builds, the alternative is to have one gigantic build graph.
> For instance, if we are building a component that needs a C compiler, the Nix expression for that component simply imports the Nix expression that builds the compiler.
> The problem with this approach is scalability: the resulting build graphs would become huge.
> The graph for a simple component such as GNU Hello would include the build graphs for dozens of large components, such as Glibc, GCC, etc.
> The resulting graph could easily have hundreds of thousands of nodes, far exceeding the graphs typically occurring in deployment (e.g., the one in Figure 1.5).
> However, apart from its efficiency, this is possibly the most desirable solution because of its conceptual simplicity.
> Thus it is interesting to develop efficient ways of dealing with very large build graphs

-- [*The Purely Functional Software Deployment Model*](https://edolstra.github.io/pubs/phd-thesis.pdf), Eelco Dolstra's dissertation, page 240.

Nix's design encourages a separation of build *planning* from build *execution*:
evaluation of the Nix language produces derivations, and then then those derivations are built.
This usually a great thing.
It's enforced the separation of the more complex Nix expression language from the simpler derivation language.
It's also encouraged Nixpkgs to take the "birds eye" view and successful grapple a ton of complexity that would have overwhelmed a more traditional package repository.

The core feature here, derivations that build derivations, is a nice sneaky fundamental primitive for the problem Eelco point's out.

It's very performant, being well-adapted for Nix's current scheduler.
Unlike Recursive Nix, there's is no potential for half-built dependencies to sit around waiting for other builds, wasting resources.
Each build step (derivation) always runs start to finish blocking on nothing.
It's very efficient, because it doesn't obligate the use of the Nix expression language.

It's also quite compatible with `--dry-run`.
Because derivations don't get new dependencies *mid build*, we have no need to mess with individual steps to explore the plan.
There still becomes multiple sorts of `--dry-run` policies, but all of them just have to do with building or not buidling derivations which *themselves* are unchanged.

To make that more, clear, if you *do* want one big ("hundreds of thousands of nodes"-big), static graph, you can still have it!
Build all the derivations that compute derivations, but not nothing else.
Then the results of those can be substituted (think partial eval, also remember we already do this sort of thing for CA derivations), and one has just that.

If one *doesn't* want that however, do a normal build, and graph in "goals" form in Nixpkgs can stay small.
Graphs evaluate into large graphs, but goals are GC'd as they are built.
This keeps the "working set" small, at least in the archetypal use-case where the computed subgraphs are disjoint, coming from the `Makefile`s of individual packages.

Finally there is a sense in which this extension is very natural.
The opening sentence of every revised scheme report is:

> Programming languages should be designed not by piling feature on top of feature,
> but by removing the weaknesses and restrictions that make additional features appear necessary.

We already have a dynamic scheduler that doesn't need to know all the goals up front.
We also already rewrite derivations based on previous builds for CA-derivations.
All the underlying mechanisms are thus there, and the patch implementing this in a sense wrote itself.

Now, there is a good argument that maybe the Nix derivation language today has other implementation strategies where this *wouldn't* be so natural and easy.
This is like saying "we can add this axiom for free in our current model, but not in all possible models of our current axioms".
Well, if such a concrete other strategy ever arises, it is very easy to statically prohibit the new features this RFC proposes.
Until then, down with the artificial restrictions!

# Detailed design
[design]: #detailed-design

We can break this down nicely into steps.

*This is implemented in https://github.com/NixOS/nix/pull/4628.*

1. Derivation outputs can be valid derivations.
   \[If one tries to output a drv file today, they will find Nix doesn't accept the output as such because these small paper cuts.
   This list item and its children should be thought of as "lifting artificial restrictions".\]

   1. Allow derivation outputs to be content-addressed in the same manner as drv files.
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
    The scheduler will substitute derivations to simplify dependencies as computed derivations are built, just like how floating content-addressed derivations are realized.

  - Missing derivations get their own full fledged goals so they can be built, not just fetched from substituters.

4. Add a new `outputOf` primop:

   `builtins.outputOf drv outputName` produces a placeholder string with the appropriate string context to access the output of that name produced by that derivation.
   The placeholder string is quite analogous to that used for floating content-addressed derivation outputs.
   \[With just floating content-addressed derivations but no computed derivations, derivations are always known statically but their outputs aren't.
   With this RFC, since drv files themselves can be floating CA derivation outputs, we also might not know the derivations statically, so we need "deep" placeholders to account for arbitrary layers of dynamism.
   This also corresponds to the use of arbitrary many `!` in the CLI.\]

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

 - Do nothing, and continue to have no good answer for large builds like Linux and Chromium.

 - Embrace Recursive Nix in its current form.

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
