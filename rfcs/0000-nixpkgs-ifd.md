---
feature: nixpkgs-ifd
start-date: 2021-10-12
author: John Ericson (@Ericson2314)
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
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

Instead of kicking of single evaluations of Nixpkgs, we will kick of double evaluations:

  1. Evaluate Nixpkgs normally.

  2. Build `allImportedDerivations`, and copy its closure to the evaluation machine.

  3. Evaluate Nixpkgs with `enableImportFromDerivation = true`, with the closure of `allImportedDerivations` added to the eval paths whitelist, and with IFD partially "allowed, but with `-j0`".
     What this means is no building can happen at eval time, but we can import the outputs of derivations that are already built and whitelisted.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

TODO, demonstrate changes to Nixpkgs, e.g. using the Haskell infrastructure, in a fork, and link?

# Drawbacks
[drawbacks]: #drawbacks

1. > We've *doubled* the amount of evaluation we do, oh no!

   Sounds scary, I know.
   But I don't think that's bad, actually.
   What's so bad today is the time and memory usage of *each* evaluation.

   You can think of that as a bunch of ungainly massive rectangular tiles we are trying to fit on a floor, the floor being our machine resources to schedule.
   What would be really bad is *increasing the tile size*.
   This means we need a bigger floor or else laying tile is harder.
   What this is doing is *increasing the number of times*.
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
   The problems with IFD and the problems IFD is trying trying to address both don't let a lot of attention.
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

The only alternative that isn't massively harder is doing nothing.

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

The most important future work is technical, but being able to win upstream developer hearts and minds better than before, because ultimately distribution's live and die by upstream's decisions.
