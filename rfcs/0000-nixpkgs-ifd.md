---
feature: nixpkgs-ifd
start-date: 2021-10-12
author: John Ericson (@Ericson2314)
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: @L-as @grahamc @sternenseemann
shepherd-leader: @sternenseemann
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Many of us want "import from derivation" \[hereafter, IFD\] be allowed in Nixpkgs.
IFD would be terrible for `hydra.nixos.org`, though,
The solution is to cut the Gordian knot: Allow IFD in Nixpkgs while still (effectively) prohibiting it in CI.

# Motivation
[motivation]: #motivation

Nixpkgs, along with every other distro, also faces a looming crisis: new open source software is increasingly not intended to be packaged by distros at all.
Many languages now support very large library ecosystems, with dependencies expressed in a language-specific package manager.
To this new generation of developers, the distro (or homebrew) is a crufty relic from an earlier age to bootstrap modernity, and then be forgotten about.

Right now, to deal with these packages, we either convert by hand, or commit lots of generated code into Nixpkgs.
But I don't think either of those options is healthy or sustainable.
The problem with the first is sheer effort; we'll never be able to keep up.
The problem with the second is bloating Nixpkgs but more importantly reproducability: If someone wants to update that generated code it is unclear how.
All these mean that potential users coming from this new model of development find Nix / Nixpkgs cumbersome and unsuited to their needs.

The solution *outside* of Nixpkgs is today is "import from derivation", i.e. building code in Nix to be consumed at eval time.
Many institutional users of Nix use this.
But while the practice is banned in Nixpkgs, those efforts are not very coordinated, and the `lang2nix` ecosystem has a hard time getting off the ground.

I am *not* arguing that IFD is the best possible solution.
But it's the one we've got to day, and long term alternatives, like RFC #92, face *significant* hurdles in being ergonomic and integrating with current idioms in Nixpkgs -- e.g. the `meta` on every derivation from `mkDerivation`.
In the spirit of learning to walk before learning to run, and beginning to acknowledge addresses these problems, we are best-serviced by getting IFD in Nixpkgs as a first-gen solution as soon as possible.
The only barrier then is addressing eval resource usage costs.

# Detailed design
[design]: #detailed-design

## Nixpkgs

1. Add a new `enableImportFromDerivation` config parameter to Nixpkgs.
   When it is `false`, anything using IFD must be disabled so that a regular evaluation like we do today succeeds.

2. Add a new `allImportedDerivations` top-level attribute.
   This *must* be buildable with `enableImportFromDerivation = false`.
   It *must* have in its run-time closure any derivation output that Nixpkgs with `enableImportFromDerivation = true` imports.
   \(CI will verify these conditions as described in the next subsection.\)

3. Any code vendored in Nixpkgs *must* correspond to code produced in an imported derivation, so the code can be mechanistically re-vendored.
   We should write tests that each pair of vendored and computed derivations are the same.

## Hydra policy

Instead of kicking off single evaluations of Nixpkgs, we will kick off double evaluations:

  1. Evaluate Nixpkgs normally.

  2. Build `allImportedDerivations`, and copy its closure to the evaluation machine.

  3. Evaluate Nixpkgs with `enableImportFromDerivation = true`, with the closure of `allImportedDerivations` added to the eval paths whitelist, and with IFD partially "allowed, but with `-j0`".
     What this means is no building can happen at eval time, but we can import the outputs of derivations that are already built and whitelisted.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

1. TODO, demonstrate changes to Nixpkgs, e.g. using the Haskell infrastructure, in a fork, and link?

2. Vendoring to avoid critical path regressions

   @FRidh brings up a good example, that of GHC and Sphinx.
   Today, both are in Nixpkgs, and GHC depends on Sphinx to render it's docs.
   With this change, we could perhaps instead package Sphinx via some hypothetical "pypi2nix" IFD.
   That would mean GHC also indirectly depends on pypi2nix.

   To avoid the fallout, we could replace the hand-written Sphinx with a vendored copy of the generate code.
   We would then test that the IFD and vendored Sphinx are the same.
   Sphinx, if I recall correctly, might has some non-python dependencies.
   Just as we do for Haskell packages today, handwritten overs overrides of the generated stuff would remain in Nixpkgs to make that go.
   In this way, Sphinx and GHC don't "regress", remaining usable from the first `enableImportFromDerivation = false` evaluation.

   Now, one might argue that GHC is not very useful except for building downstream packages.
   Also, with or without this PR, I have a very long-standing goal to build the compiler itself and "wired-in" libraries separately, which would allow using cabal2nix for much of GHC itself.
   *If* we do that, and also *if* we decide to stop vendoring the generated Hackage packages and only rely on IFD, GHC would become a second-eval-only, `enableImportFromDerivation = true`-only package.
   At that point, there might not be a reason to vendor Sphinx anymore, and so we would stop doing so and only rely on the IFD too.

   Again, note that the final paragraph of that story is purely hypothetical, just one possible future.
   This RFC does *not* propose making any specific concrete packages second-eval-only.

# Drawbacks
[drawbacks]: #drawbacks

1. > We've *doubled* the amount of evaluation we do, oh no!

   Sounds scary, I know.
   But I don't think that's bad, actually.
   What's so bad today is the time and memory usage of *each* evaluation.

   You can think of that as a bunch of ungainly massive rectangular tiles we are trying to fit on a floor, the floor being our machine resources to schedule.
   What would be really bad is *increasing the tile size*.
   This means we need a bigger floor or else laying tile is harder.
   What this is doing is *increasing the number of tiles*.
   We can simple add a second floor to solve any problems that arise from that.

   This is simplification, sure, but I think the parable is correct to the "real" situation, too.

2. > Isn't IFD really slow?

   What is slow is that evaluator has no parallelism.
   That means is that every time we hit an *unbuilt* derivation, we block until it's finished building.
   Worse, even if it is easy to run, we're probably going to check some substituters, etc., so there are all sorts of slow IO round trips making the critical path worse.
   We could fix this, but there is no energy to do so right now.
   Making the evaluator parallel without making our memory issues worse is hard work.

   But, none of that matters for this proposal.
   `hydra.nixos.org` will only need to read built paths, and that shouldn't be meaningfully slower than regular `import`-ing.

3. > IFD, is too controversial, don't do it!

   I think this is a classic example of don't let the perfect be the enemy of the good.
   The problems with IFD and the problems IFD is trying to address both don't let a lot of attention.
   The fact of the matter is Nixpkgs is how this community coordinates with itself, and agrees on priorities.
   If it isn't being used in Nixpkgs, there is hard ceiling of how much attention it will get.

   The benefits of IFD don't get enough attention.
   A package in Nixpkgs is more than a derivation: there's the `meta` as I mentioned above.
   There's also being able to read the code and (somewhat) understand what's going in reference to other derivations.
   Finally, there's being able to `override`, `overrideAttrs`, etc. the derivation downstream.
   IFD alone allows computed packages that follow all these norms.

4. Say I want IFD that depends on other IFD?

   In other words, can one import a derivation that is itself evaluated from and import from a derivation?
   No, not without introducing another round of building and evaluating for Hydra.
   But I don't think we need arbitrarily-deep dynamism anyways: it is a tool that should be used with care anyways, because stasis \[staticism?\] is the goodly disciplinarian that makes Nixpkgs so great.

   That said, `cabal2nix` is written in Haskell, `crate2nix` is written in Rust, etc. etc.
   We can vendor enough code to build these tools and thus bootstrap the IFD we will do.
   Per the 3rd rule for Nixpkgs above, as long as we make the vendoring automatic and pure, this is fine, and improvement upon today.
   Also, even if we didn't have the "one round of dynamism" restriction, we would still have the bootstrapping issue.

# Alternatives
[alternatives]: #alternatives

1. Instead of evaluating Nixpkgs twice, just evaluate `allImportedDerivations` the first round.

   We could do this, and would reduce total eval time, yes.
   But, I think it would come at the cost of inciting great controversy.
   This means users of the `enableImportFromDerivation = false` subset of Nixpkgs would still have to *wait*, for all the IFD to complete first.
   And remember, with mass rebuilds, that could be quite some time.
   Increasing the critical path length of *everything* we do with Nixpkgs would cause real pain in some quarters, and I don't want that to pay that as the cost of IFD.

   With the plan as written, users of packages depending on IFD do have to wait slightly longer as the first eval is longer (and we wait for it before beginning to build `allImportedDerivations`).
   But I think that is fair; we would be the "new constituency", the bottom of the pecking order, and so we should be patient so that other's workflows are not disturbed.

   Longer term we could revisit this, or we could e.g. double down on automatic vendoring, committing all generated code to a second "roll-up" repo.
   Many options between those two extremes; I rather not worry to much about it now and just take the conservative polite route proposed here to begin.

2. As always, do nothing, and keep the status quo.

# Unresolved questions
[unresolved]: #unresolved-questions

Should we call it "import from Derivation", or should we give it a different name?
`builtins.readFile <drv>` is really the same thing for our purposes, so I am sympathetic to renaming.

# Future work
[future]: #future-work

In a grand future we might do things completely differently.
But I have no idea how stuff is going to shake out.
In particular, if we don't do something like this, I don't think we will ever get to that future.
So even if this technically "barking up the wrong tree", I think it is a necessary first step to get things going.

I will say, though, with these steps, I think we will be able to successfully convert to Nix a bunch of developers that mainly work in one language, and didn't even think they were in need of a better distro.
In turn, I hope these upstream packages and ecosystems might even care about packaging and integration of the sort that we do.
This would create a virtuous cycle where Nix is easier to use by more people, and Nixpkgs is easier to maintain as upstream packages better match our values.

The most important future work is not technical, but being able to win upstream developer hearts and minds better than before, because ultimately distribution's live and die by upstream's decisions.
