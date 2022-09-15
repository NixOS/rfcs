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

If we view Nix as one monolithic whole, it will grow too complex and unwieldy, and we will be unable to manage it as we the complexity bogs us down.
However, if we embrace layering we can "divide and conquer" the project, and manage that complexity.
This will ensure the continued sustainability of Nix.

We currently embrace layering somewhat as an implementation detail, but only as an implementation detail.
The division between `libnixstore`, `libfetchers`, `libexpr`, etc. is not yet exposed to users, emphasized in documentation (though this is changing thanks to @Fricklerhandwerk's efforts with new [architecture documentation](https://github.com/NixOS/nix/pull/6888)!).

We should instead fully embrace it:

- Docs

  - More advanced documentation can explain layering for those that want a deeper understanding of Nix.

  - Even more basic documentation can still benefit from separate terminology before the layering is fully explained.
    See https://www.haskellforall.com/2022/08/stop-calling-everything-nix.html for a phenomenal take-down of how calling everything "Nix" today confuses users and leaves them unable to articulate what parts of the ecosystem are frustrating then.

- Separate executable ensure lower layers build in isolation, new integration tests those executable without aid of high-layer info.

- New NixOS-Foundation-authorized teams foster and advocate for layers in isolation

### Starting with the store layer

Ultimately, I would like to take this approach to all the layers.
But I want to constrain the scope of this RFC to keep it tight an actionable.

Layering between e.g. Flakes and the Nix Language doesn't yet exist in the implementation in the form of a library separation.
I don't want to be "blocked" on major new development work, and anything involving Flakes is also far more controversial, and best avoided at first.

Conversely, the store layer is already quite well separated.
The orthogonality between it and other layers "proven" in the wild by projects like Guix (more on that latter part in the next section).
The gap is also widest in terms of the layer of abstraction between, on one hand, nascent "infrastructure projects" like

- CA derivations
- Secrets in the store
- Trustless remote building
- Daemon and Hydra protocol rationalization
- Windows Support
- Computed derivations (which are built by the other derivations)
- IPFS store

etc. and "UX projects" like

- Flakes
- TOML Flakes
- Hard-wired module system

So focusing on the lowest layer first, we get the most "bang for buck" in terms of managing extremely different sorts of work separately.

### A disclaimer

To be clear, none of this is to say we should abandon the idea of Nix as a whole.
There can still be governance of Nix as a whole, that teams and people focused on "infra" or "flakes" would ultimately need to report to.
The goal is not to overreact, but strike a balance between:

1. Making sure Nix as a whole continues to make sense
2. Make sure layers make sense in isolation not just in the context of the way they are currently used.

## Marketplace of Ideas

As Nix grows more popularity, it will be inevitable that different groups want to explore in different directions.
This is the *pluralism* of a larger community, and we should embrace it as a strength.
We do that be fostering a *marketplace of ideas*.

There are many possible ways in which to write down packages, The Nix language and Nixpkgs idioms, and Guix, for example, are just two points in a much larger space.
There are also many possible ways set up build farms.
Our current central dispatcher, many remote-builder agents model, point-to-point protocol model is also just point in a much larger design space.

The "derivation language" and store *interface* however, seems to me at least to be a very natural design.
There are a few tweaks and generalizations we can make, but I struggle to envision what wildly different alternatives one might want instead.

An stable, small interface that fosters lots of design exploration above and below is known from networking as a *narrow waist*.
The oil shell blog as a [great post](https://www.oilshell.org/blog/2022/02/diagrams.html) with more details on the concept.
It's not every day that a project happens upon a great narrow waist design, but I believe we've discovered a very good one with Nix, and that should be seen as a *key asset*, even if it is not how we recruit "regular users".

By making a store-only Nix, we put more emphasis on this key interface.
All functionality the store-only Nix offers factors through this interface.
The upper half of Nix likewise uses the lower half through this interface.
The daemon protocol represents this interface for IPC, and allows either half to be swapped for a different implementation.

To help explain the community-building benefits, it might help to go over some specific examples.

### Tvix and go-nix

In https://tvl.fyi/blog/rewriting-nix, TVL announced that, frustrated in trying to refactor Nix into something more modular and flexible, they were aiming to make a new implementation from scratch.

Since then, what has emerged is that [*Tvix*](https://cs.tvl.fyi/depot/-/tree/tvix) is a new implementation of the Nix language evaluator,
and [*go-nix*](https://github.com/nix-community/go-nix) is a new implementation of the store layer.

First of all, the fact that they are planning on two completely separate implementation oriented around this same "narrow waist" is testament to the appeal of the design.

Second of all, note that per their blog post, they have separate, orthogonal experiments they wish to run on both sides of the store interface divide.
Above, they want to experiment with radically different evaluation strategies, especially to speed up Nixpkgs evaluation.
Below, they want to experiment with the standardized containerization technologies that exist for new ways of sandboxing and distributing builds with less bespoke Nix-specific code.

I think these are both great goals, and for the sake of the ecosystem as a whole, it should be as easy as possible to run such new experiments.
In particular, a novel evaluator should be usable with the standard C++ Nix store layer, and a novel store layer should be reusable with the standard C++ Nix evaluator.

Yes, strictly speaking, we only need a stable daemon protocol to accommodate that goal, which we have.
But ensuring the C++ Nix components can be built separately for use in isolation further send the message that such experimentation is *good* and *welcomed*.
Messaging matters, and making our layered architecture "official" as this RFC proposes I think sends a better message.

### Guix

Guix is more diverged from Nix than Tvix + go-nix, and thus hints more at the end breadth of the design space yet to be explored.

The store layer is the same, but the layers above, instead of being a implementing of the Nix language, is a completely different design with Guile Scheme.
The choice of language is just the tip of the iceberg here.
More profoundly, they also have a more "library" than "interpreter" model where packages depend on Guix as a library, which talks to a small rump daemon.
Guile sits far lower in their stack than the Nix language interpreter does; it is as if we rewrote some of our C++ into nix language code, and nix language code could do enough side effects to make that possible.

The point of this discursion is to show that not only are radically different implementation of the same spec possible on either side of the store interface (what Tvix + go-nix aim for), but radically different designs not going for comparability also.

Guix currently uses a stripped-down fork of C++ for its core daemon.
Clearly, it would be nicer than that if, as this RFC proposes, we supporting building just such a stripped-down daemon with*out* any forking needed.
Then we could all collaborate on one bit C++ that didn't drag in features Guix didn't want, no forking needed.

Still, the long term goal of Guix is to rewrite that remaining C++ into Guile Scheme too?
At that point, does that mean the benefits of this RFC for Guix are gone too?

I don't think so.
It makes total sense that Guix wants an implementation they fully control, in the language they prefer, and I have no interest in dissuading them from that goal!
But it would be still nice to have full interop so Nix can work with the Guix daemon, and Guix with the Nix daemon.

This is especially important in "institutional settings", such as high performance computing (HPC) build farms for science, software development shops, and everything in between.
HPC and academic use in particular is something Nix and Guix are both interested in.

Firstly, this RFC has benefits for bureaucratic expediency.
There is usually a lot of red tape needed to get a new technology deployed thought a build farm.
If Guix and Nix users have to separately ask for their build farm store layer backend to be rolled out, that is twice the headache for IT, with half the stakeholders asking for each deploymenet.
If, on the other hand, Guix and Nix users separately agree on one store layer backend to be rolled out they both can use, that is twice has many people asking for a single deployment --- a much stronger ask on IT.

Secondly, and perhaps more abstractly, I think this project allows both projects to better utilize their own design and resources.

Nix and Guix have completely independent visions above the store layer --- it is for here that Guix was created.
This is where both projects are choosing to innovate post "fork" (Guix from day 1 with Guile, us more recently with Flakes).
This is where the projects compete at the level of *ideas*.
Below the store interface, conversely, I think everyone wants the same things.
I have yet to hear of any store-layer idea that is "Guix-y but not Nix-y", or "Nix-y but not Guix-y".
Here the projects are not competing on *what* is being implemented, but *how well* it is being implemented.

In such a situation, interoperability is a free win.
Since there is no underlying philosophical difference at this layer, there is straightjacket imposed from trying to be interoperable.
And while it's good and fine to compete on implementation, including rewriting the renaming C++, it's nice to be able abandon that competition at any more moment and join forces on a shared implementation, freeing up resources for other things.
To be very clear, this doesn't mean I am advocating that Guix "give up" on its independence from Nix --- maybe go-nix will end up being the dominant implementation and we all just use that!
I do not what the future holds, but I want to make sure we keep our options open, and each project is allowed to boost the other as much as possible without sacrificing design flexibility.

Ultimately, while the single-machine single-user Nix experience is quite good, the shared build-farm multi-user experience with Nix and Guix is quite a bit *worse* than it could be.
I want to see major improvements in that area, and I want to see all projects benefits, and I really don't care whole ends up delivering those features first so long as the rest of us can benefit.

I do not expect Guix to be immediately sold on this plan, but as that larger project, I think it behooves us to take the first steps to build trust and coordination.

# Detailed design
[design]: #detailed-design

## The split itself

Allow building a store-only version of Nix.
This is a Nix executable that links `libstore` but not `libfetchers`, or `libexpr`.
Plenty of commands like `nix daemon`, `nix log`, and the `nix store` sub-commands don't care about evaluation, fetching, or flakes at all.
https://github.com/NixOS/nix/issues/6182 is a draft PR implementing this, splitting `libcmd` into two parts so the CLI code reused.
We will finish it off with as many commands as are reasonable to include, and merge it.

## Additional in-code obligations

### Tests

The current test suite uses Nix language for most tests of store-layer functionality.
But it also allows using a separate daemon with most tests.

1. To start, we should test the full Nix against the minimal Nix's daemon, in addition to our regular tests.

2. Longer term, we should write new tests that don't use the Nix language.
   E.g. we might create a `read-derivation` complement of `show-derivation` that accepts a nicer JSON representation of a derivation as input.
   This will allow the store-only Nix to be tested in isolation.

### CI

The store-only Nix and its tests should be built as part of CI, as "first class" as our existing CI jobs.
That means both in the channel-blocking Hydra eval, and per PR.
If we hit the limits of Github Actions in per-PR CI, we should consider using Hydra instead / in addition as has already been discussed.

### Manual

It should be possible to build a store-only manual without information on the other layers too.
This would be the manual that is distributed with the store-only Nix.
Of course, store-only and full  can share sections, so we aren't duplicating work.

## Out-of-tree obligations

### A store team

An official NixOS-foundation-authorized teams should be set up to manage store layer design decisions (below the threshold of needing an RFC) that don't effect that the rest of Nix.
\[Some sort of decision that affect all layers is out of scope, must be deliberated with stakeholders from other layers too, probably should be RFC due to such large scope.\]

This team should establish communication with counter parties in Guix leadership.

### Website

The fully and store-only version of Nix should both be presented for download on the website.
This should be just like how Plasma, Gnome, and headless installer images for NixOS are all offered.

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
"entire kitchen sink" tests make it harder to narrow down root causes of failures.

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

Do technical parts without governance or documentation parts.
But that feels to me like turning an ongoing shift in focus to a one-off change that is likely to bit-rot.

# Unresolved questions
[unresolved]: #unresolved-questions

What should the store-only Nix be called?

# Future work
[future]: #future-work

## Standardization across projects

If we establish informal interop across store-layer implementations with Guix, a next step would be establish some sort of living standard that both communities have equal say in.
(Of course, implementations are free to implement features in excess of what the standard requires!)
The new store team can lead the process from our end.

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
