---
feature: nix-store-layer
start-date: 2022-09-06
author: John Ericson
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Allow building a Nix executable with just the store layer.
Do this to manage complexity, and promote a "Greater Nix" community.

# Motivation
[motivation]: #motivation

## Managing complexity

We have recently added a ton of functionality to Nix.
Most of this is in Flakes, which just has enormous surface area, but things like floating content-addressed derivations and other RFCs add complexity to the core store layer too.

If we view Nix as one monolithic whole, it will grow too complex and unwieldy, and we will be unable to manage it as the complexity bogs us down.
However, if we embrace layering we can "divide and conquer" the project, and manage that complexity.
This will ensure the continued sustainability of Nix.

We currently embrace layering somewhat as an implementation detail, but only as an implementation detail.
The division between `libnixstore`, `libfetchers`, `libexpr`, etc. is not yet exposed to users, or emphasized in documentation (though this is changing thanks to @fricklerhandwerk's efforts with new [architecture documentation](https://github.com/NixOS/nix/pull/7066)!).

We should instead fully embrace it:

- Expand documentation

  - More advanced documentation can explain layering for those that want a deeper understanding of Nix.

  - Even more basic documentation can still benefit from separate terminology before the layering is fully explained.
    See https://www.haskellforall.com/2022/08/stop-calling-everything-nix.html for a phenomenal take-down of how calling everything "Nix" today confuses users and leaves them unable to articulate what parts of the ecosystem are frustrating.

- Introduce separate executables to ensure lower layers can be build in isolation, i.e., without requiring higher layers.

   - Add integration tests for those executables that don't require the higher layers, either. This is to ensure the lower-layer executables work correctly in isolation. 

### Starting with the store layer

Ultimately, we should take this approach to all the layers.
The constrained scope here is to keep this RFC actionable.

Layering between e.g. Flakes and the Nix Language doesn't yet exist in the implementation in the form of a library separation.
Separating Flakes into its own library would require major new development work, and I don't want to "block" exposing the layering for the first time to users on such work when there is an easier way to try this idea how.
Flakes also has more development going on due being unstable, so it is nice to not get in its way.

Conversely, the store layer is already quite well separated.
Its conceptual independence from Nix's other layers is "proven" in the wild by projects like Guix.
The gap is also widest in terms of the layer of abstraction between, on one hand, nascent "infrastructure projects" like

- content-addressed derivations
- Secrets in the store
- Trustless remote building
- Daemon and Hydra protocol rationalization
- Windows Support
- Computed derivations (which are built by the other derivations)
- IPFS store

and projects aiming at improving user experience, such as

- Flakes
- TOML Flakes
- Hard-wired module system

Focusing on the lowest layer first, we get the most "bang for buck" in terms of managing extremely different sorts of work separately.

## Marketplace of Ideas

As Nix grows more popularity, it will be inevitable that different groups want to explore in different directions.
This is the *pluralism* of a larger community, and we should embrace it as a strength.
We do that by fostering a *marketplace of ideas*.

There are many possible ways in which to declare packages: the Nix language and Nixpkgs idioms, and Guix, for example, are just two examples of what is possible in principle.
There are also many possible ways set up build farms.
Our current model of a central dispatcher, many remote-builder agents, and a client–server where only one side initiates, is also just one point in a much larger design space of possible solutions.

The "derivation language" and store *interface* however, seems to me at least to be a very natural design.
There are a few tweaks and generalizations we can make, but I struggle to envision what wildly different alternatives one might want instead.

A small, stable interface that allows for design exploration above and below it is known as a [narrow waist](https://www.oilshell.org/cross-ref.html?tag=narrow-waist#narrow-waist).
It's not every day that a project happens upon a great narrow waist design.
I believe we've discovered a very good one with Nix, and that should be seen as a *key asset*, even if it is not how we recruit "regular users".

By making a store-only Nix, we put more emphasis on this key interface.
All functionality the store-only Nix offers factors through this interface.
The upper half of Nix likewise uses the lower half through this interface.
The daemon protocol represents this interface for IPC, and allows either half to be swapped for a different implementation.

To help explain the community-building benefits, it might help to go over some specific examples.

### Tvix and go-nix

[TVL announced](https://tvl.fyi/blog/rewriting-nix) that, frustrated in trying to refactor Nix into something more modular and flexible, they were aiming to make a new implementation from scratch.
More recently, [they lay out a basic approach](https://tvl.fyi/blog/tvix-status-september-22) of two projects:

- [Tvix](https://cs.tvl.fyi/depot/-/tree/tvix) is a new implementation of the Nix language evaluator,

- [go-nix](https://github.com/nix-community/go-nix) is a new implementation of the store layer.

First of all, the fact that they are planning on two completely separate implementation oriented around this same "narrow waist" is testament to the appeal of the design.

Second of all, note that they have separate, orthogonal experiments they wish to run on both sides of the store interface divide.
Above, they want to experiment with radically different evaluation strategies, especially to speed up Nixpkgs evaluation.
Below, they want to experiment with the standardized containerization technologies that already exist for new ways of sandboxing and distributing builds with less bespoke Nix-specific code.
They also want to apply the layering paradigm *within* go-nix, fostering even more modularity.

I think these are great goals, and for the sake of the ecosystem as a whole, it should be as easy as possible to run such new experiments.
In particular, a novel evaluator should be usable with the standard C++ Nix store layer, and a novel store layer should be reusable with the standard C++ Nix evaluator.

Yes, strictly speaking, we only need a stable daemon protocol to accommodate that goal, which we have.
But ensuring the C++ Nix components can be built separately for use in isolation further send the message that such experimentation is *good* and *welcomed*.
Messaging matters, and making our layered architecture "official" as this RFC proposes I think sends a better message.

### Guix

Guix is further removed from Nix than Tvix + go-nix, and thus hints more at the end breadth of the design space yet to be explored.

The store layer is the same, but the layers above, instead of being an alternative implementation of the Nix language, have a completely different design using Guile Scheme.
The choice of language is just the tip of the iceberg here.
More profoundly, they also have a more "library" than "interpreter" model where packages depend on Guix as a library, which talks to a small rump daemon.
Guile sits far lower in their stack than the Nix language interpreter does; it is as if we rewrote some of our C++ into Nix language code, and Nix language code could do enough side effects to make that possible.

The point of this discursion is to show that not only are radically different implementation of the same specification possible on either side of the store interface (what Tvix + go-nix aim for), but also radically different designs not at all trying to be compatible.

All that said, below the store layer there is no difference in vision.
Because our communities are so separate, it would be easy to come up with diverging versions of how derivations, store objects, etc. should work.
That we have not done so I think is testament to the broad applicability of the Nix store design to many diverse groups of people with diverse goals.

What I hope to do with Guix, then, is convene both projects to make their store store layers interoperate.
Complementing the idea of a "marketplace of ideas" is when there is a certain design (like the Nix store layer), that is so broadly popular as to be a sort of "natural monopoly", that we should foster the most expansive and general idea of it as an exercise in coalition building and outreach.

I do not expect Guix to be immediately sold on this plan, but as that larger project, I think it behooves us to take the first steps to build trust and coordination.
Making a stand-alone Nix store executable demonstrates we are serious about layering and serious about standardizing that layer, and not just trying to get Guix users to use Nix instead.

# Detailed design
[design]: #detailed-design

The goals motivated above a broken down into small steps that we can execute in isolation.
This keeps the cost of this work initially lower, and generally reduces risk.

## 1. The split itself

Allow building a store-only version of Nix.
This is a Nix executable that links `libstore` but not `libfetchers`, or `libexpr`.
Plenty of commands like `nix daemon`, `nix log`, and the `nix store` sub-commands don't care about evaluation, fetching, or Flakes at all.
[NixOS/nix#6182](https://github.com/NixOS/nix/issues/6182) implements this, splitting `libcmd` into two parts so the CLI code is reused.
We will finish it off with as many commands as are reasonable to include, and merge it.

Initially, we can test this store-only version of Nix with no changes to the test suite, by running full Nix with the store-only Nix's daemon.
Support for testing Nix against a separately-built daemon already exists and is in use today.

The store-only Nix and its tests should be built as part of CI, as "first class" as our existing CI jobs.
That means both in the channel-blocking Hydra evaluation, and for each pull request.
If we hit the limits of GitHub Actions in per-pull-request CI, we should consider using Hydra either instead or in addition to GitHub Actions, something that has already been discussed.

## 2. Manual

It should be possible to build a store-only manual without information on the other layers, too.
This would be the manual that is distributed with the store-only Nix.
Of course, store-only and full Nix can share sections, so we aren't duplicating work.

## 3. Website

The full and store-only version of Nix should both be presented for download on the website.
This should be just like how Plasma, Gnome, and headless installer images for NixOS are all offered.

## 4. Store-specific Tests

The current test suite uses Nix language for most tests of store-layer functionality.
We should write new tests that don't use the Nix language.
E.g. we might create a `read-derivation` complement of `show-derivation` that accepts a nicer JSON representation of a derivation as input.
This will allow the store-only Nix to be tested in isolation, but these tests can also be used with full Nix.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

## Maximal Nix unlike today

I cannot emphasize this enough, but the interface of maximal store+exprs+flakes Nix remains *exactly* like today.
In particular, lower level commands can be used with higher level "installables" (arguments), so e.g.
```
nix show-derivation flake#bar
```
will still work.

## Good tasks anyways!

Lots of the plan above I think is good work we should be doing anyways, regardless of whether we expose a store-only Nix.
If you believe this, then the "cost" of this RFC is a lot less.

### Tests

Splitting the test suite per natural layer of the implementation is good work because it combines the specificity of unit tests with the real-world-ness of integration tests.
"Entire kitchen sink" tests make it harder to narrow down root causes of failures.

### Manual

The documentation team is already working to clean up the manual, and this effort already involves emphasizing layering.
So whether we formally make a store-only Nix or not, I suspect the overhauled manual will natural have easy boundaries from which to "extract" the store-only manual.

## Security

The daemon is a privileged process.
Even if with upcoming changes it shouldn't need root, it does tasks like administrating OS sandboxes correctly which still are security-critical.
Having less code in the story-only Nix daemon, even if we think the removed code was "dead anyways" is always good.

# Drawbacks
[drawbacks]: #drawbacks

Creating new teams, trying to build ties with other communities sounds scary.

# Alternatives
[alternatives]: #alternatives

Do programming parts without the documentation and website parts.
But that feels to me like turning an ongoing shift in focus to a one-off change that is likely to bit-rot.

# Unresolved questions
[unresolved]: #unresolved-questions

What should the store-only Nix be called?

# Future work
[future]: #future-work

## Nix Store Team

Now that we have this division in the implementation, we also have the opportunity to leverage it for governance purposes.
An official, NixOS-foundation-authorized team could be set up to manage store layer design decisions (below the threshold of needing an RFC) that don't affect that the rest of Nix.
\[Some sort of decision that affect all layers is out of scope, must be deliberated with stakeholders from other layers too, probably should be RFC due to such large scope.\]

To be clear, this is *not* to say we should abandon the idea of Nix as a whole.
There can still be governance of Nix as a whole; this team, and similar hypothetical, say, Flakes, Nix language, or User Experience teams would ultimately need to report to.
The goal is not to overreact, but strike a balance between:

1. Making sure Nix as a whole continues to make sense
2. Make sure layers make sense in isolation, and not just in the context of the way they are currently used.

## Standardization across projects

If we establish informal interoperability across store-layer implementations with Guix, a next step would be establish some sort of living standard that both communities have equal say in.
(Of course, implementations are free to implement features in excess of what the standard requires!)

A new store team, per the above, could lead the process from our end, since the other parts of Nix are not shared with Guix and thus out of scope for this sort of cross-project standardization.

## Stabilization

There is a looming question on how to stabilize Nix's big backlog of unstable features (New CLI, Flakes).
There is a lot of bad-blood over Flakes, both the feature itself and the way it has been rolled out.
I think the stabilization process can be an opportunity to heal old wounds.

At a minimum, this can involve stabilizing the new CLI before Flakes.
But even that that is a lot of new feature surface area to review.
I think even better is stabilizing just the store-only new CLI first.

This is easily the least controversial part of our unstable feature backlog, and yet there is still plenty to discuss.
Questions like

- logging
- store paths on `stdout` at end of build?
- Should commands like `show-derivation` should use `--json` by default
- Flat vs hierarchical commands
- is `--derivation` a good flag? (I think not!)

are all in-scope.

Having a conversation just on this narrow first batch of stabilization both builds trust, and ensures these still-important issues they aren't lost in flame wars over more divisive topics.
