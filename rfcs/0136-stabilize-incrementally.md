---
feature: stabilize-incrementally
start-date: 2022-09-15
author: John Ericson
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: "@thufschmitt @tomberek @infinisil"
shepherd-leader: "@tomberek"
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Ever since the closing of [RFC 49](https://github.com/NixOS/rfcs/pull/49), we've had the new CLI and Flakes marked as experimental, with no clear plan forward.

With the goal of ending this current limbo and soothe longstanding tensions in the Nix community, this RFC does two things:

1. Establish general principles about Nix's architecture and evolution in order to ensure we do not get in this situation again.

   Notably we are allowed to make breaking changes to experimental features, which includes both the new CLI and Flakes, until they are stable.

2. Establish an incremental plan adhering to the principles deciding on the order and priority in which to stabilize these features:

   - First, the non-Flakes CLI will be stabilized, in phases corresponding to Nix's architecture.

   - Afterwards, Flakes itself and its CLI components can be stabilized. The final design of Flakes will also require another RFC.

# Problem statement
[problem-statement]: #problem-statement

For the past few years, we've accumulated a massive backlog of unstable features in the form of the new command-line interface and flakes.
There is now a growing desire to stabilize those features, but as of yet no plan on exactly how to do so.
The tension between that desire and a lack of a clear plan has loomed over our heads for a while; this RFC aims to dispel it by providing a concrete plan, a plan that hopefully will mitigate the lingering controversies and tensions around Flakes.

## The situation so far

There are a few facts that must be introduced to give context to this situation.
We can't change these short of a time machine, so we must find a way to live with them instead.

### Flakes are very popular

As measured in the community polls, Nix has a lot of new users, dwarfing the number of long-time users.
Flakes is very popular among these new users.
Ergo, Flakes is very popular among the Nix community as a whole.

Many groups and individuals interested in the continued growth of the Nix community see that Flakes are popular, and wish for them to be stabilized to attract still more users.
The thinking is that if unstable Flakes are already proven to be popular, stable Flakes will be even moreso.

### Difficulties in the roll-out

It is undeniable that the roll-out of these new features has been controversial.
Graham Christensen's blog post [flakes-are-an-obviously-good-thing](https://grahamc.com/blog/flakes-are-an-obviously-good-thing) lays out the procedure issues along the way quite well.

Some people were upset the Flakes RFC was abandoned but the feature merged.
Other people were fine with experimental features being merged without RFC, but were upset because Flakes never really *felt* experimental.
Experimental features are expected to be subject to community feedback, modified a lot based upon that feedback, and, most importantly, *discouraged* from being used in production.

### Flakes are criticized for encroaching on other features

There are many criticisms about Flakes.
But one of them especially relevant to stabilizing is a perception that Flakes have encroached on other new features, in the sense that it ought to be possible to use those other features without Flakes but isn't in practice.
For example, there is no reason in theory that pure evaluation of Nix expressions requires Flakes.
But without the ability to populate some sort of initial list of store paths that are safe to import, pure evaluation does in practice require Flakes.

This is especially noticeable for new CLI features that *previously did*, in fact, work without Flakes.
For example, in earlier versions of Nix, `nix search` worked without Flakes.

# High-level design

## A plan all sides can be happy with

Stabilizing the new CLI and Flakes will end the saga of the past few years.
It is a last good chance to soothe some of these tensions and put us on a good foot moving forward.
The new NixOS Foundation gives the RFC authors hope that the Nix community is serious about addressing these sorts of governance issues, and accepting this RFC would be a good way to further demonstrate we are turning a new leaf.

The plan below attempts to make all sides happy, despite their seemingly irreconcilable differences.
The basic thrust is to proceed with stabilization in small steps.
Two benefits are envisioned:

### Benefit 1: Keep discussions on track.

Threads on Flakes in the past, such as that for the [original RFC](https://github.com/NixOS/rfcs/pull/49), have been impossible to follow because the sheer magnitude of different topics being discussed.
Small stabilization steps are meant to yield *focused, bounded* discussions that actually read well.
This also ensures any issues that do arise are actually brought to attention, and not lost within a deluge of other topics.

### Benefit 2: Build trust by starting with the least controversial material.

Flakes are obviously the most controversial, and so they are saved for last.
The CLI is more broadly popular, but still is a lot of material to discuss.
The store-only subcommands are Nix's "plumbing" as opposed to "porcelain" commands, and thus have the simplest (if not most user-friendly) purposes.
This "dusty corner" of the new CLI is rather calm with a very constrained design space, and far less acrimony.

## A plan so we don't get in this situation again

We could just make up a plan for the CLI and Flakes --- everything discussed so far.
But that begs the question, where is that plan coming from?
Is it ad-hoc reasoning just for this case, or following from some larger principles?

We want to get out of the current situation, but we also want to make sure that we don't get in this situation again.
So this RFC also tries to come up with a set of larger principles that are meant to "show where the current plan is coming from", and and also set up ways of working so that these issues shouldn't arrive again.

The more narrow of these principles is about how experimental features are developed and stabilized.
This hopefully is fairly uncontroversial and dovetails with the [experimental feature lifecycle documentation](https://nixos.org/manual/nix/stable/contributing/experimental-features.html) that was recently added to Nix.

The broader of these principles is about Nix's architecture and a renewed commitment to layering.
It is the opinion of the author and shepherds that lying behind some process woes is architectural uncertainty.
--- Flakes being relatively big and addressing many things at once made it a somewhat unavoidable magnet for controversy, even had the process we now propose been perfectly followed.

Together this gives us a good "defense in depth":
we enshrine a process which should keep tensions down, and we seek to avoid features/behaviors which would tempt us by their scope to veer from that process the first place.

## Conclusion

By starting with the relatively easy target of stabilizing the CLI incrementally, we can prove we can all come together as a community to agree on a design after all.
This should build trust between opposing individuals and factions, giving us a foundation upon which to tackle the more challenging material in subsequent steps.

We recognize that Flakes is widely used and will take precautions to ensure users are reasonably informed of any breaking changes that might occur from the stabilization.

# Detailed design
[design]: #detailed-design

The detailed design of this RFC consists of these parts:

- Establishing Principles
    - Layering principles
    - Stabilization process

- Plan bringing Nix into compliance with the principles, and specifying the order in which the outstanding unstable CLI and Flakes features will be tackled.

## Layering principles

These basic layering principles will be added to the [Nix architecture documentation](https://nixos.org/manual/nix/stable/architecture/architecture.html):

### For Nix as as a whole

- **Public Interfaces**

  Layers are not just an implementation detail, instead they are publically exposed to the user via stable interfaces
  All exposed interfaces in Nix, both for computers or humans, must be matched to layers

### For each layer

- **Clarity of purpose**

  Layers should not be too "thick".
  Layers should "do one thing, and do it well".

- **Compositionality**

  Layers should stand alone:

  - They should work as the top layer
  - They should also work *not* as the top layer, and with multiple possible layers above them
  - They should expose a clear interface, which is what makes the previous point possible.

- **Gravity**

  Features should be in the lowest layer it makes sense to have them.

## The general stabilization process --- audit, refine, and *then* stabilze

See the [current documentation on experimental features and their lifecyle](https://nixos.org/manual/nix/stable/contributing/experimental-features.html).

Stabilization of any feature, not just the CLI or Flakes, is not a matter of just flipping a switch on an implementation that has accrued for a period of time.
Because the moment before stabilization is our last chance to make major changes, it is crucial that we look over what is being stabilized.

To stabilize a piece of functionality (experimental -> stable in flowchart in linked documentation) we must do these things:

1. **Audit the functionality**

   Make note of the current state.
   Do this publicly so the Nix community at large has a chance to weigh in.

   Checklist during audit:

   - **Documentation**

     Ideally the feature is already well-documented and the audit brings up nothing new.
     But if it isn't, it must be by the end of the audit.

   - **Whole feature flag, not part of a feature flag**

     It should be possible to enable just the experimental feature that is ready for stabilization *in isolation*, without also enabling other unstable functionality that is not ready for stabilization.
     We are not allowed to propose to stabilize part of an experimenal feature and do so immediately.
     We have to first break out the candidate functionality to be stabilized so it is just guarded by one feature flag.

   - **Self-Containment**

     With the previous checklist item ensuring that the feature *exists* in isolation, we then have to make sure it *make sense* in isolation.
     The feature to be stabilized should "stand alone", meaning that it should make sense and work both with and without further unstable features not yet undergoing the stabilization process.

   - **RFC Compliance**

     If we have an RFC, the release candidate experimental feature should match the RFC.

2. **Hold "Final Comment Period" for refinements of the functionality**

   It is reasonable to notice things that were not noticed before the audit.
   Features can either be changed, or they can be carefully carved out as ineligible for stabilization at this time, and left to be dealt with in a later round of this process.

   Note that for large, complex, and controversial features, an RFC is also required (per usual) to advance to the next step.
   The auditing and FCP for the feature in this case take place under the auspices of the RFC process.

3. **Actually stabilize**

   Only this last step is "stabilization proper".
   This should be nothing more than removing a feature flag that has made it though the previous steps.

## CLI in waves, then Flakes

As discussed in the motivation, we want to stabilize the less controversial Flake-agnostic new CLI before Flakes.
In addition, the CLI can itself be split up for more fine-grained rounds of stabilization.
According to the layering principles, the CLI in fact *must* be split in order to abide by the **publicity** principle.

The rounds thus look like this:

1. CLI
   1. "installable"-free Store-only CLI
   2. Rest of the Store-only CLI (includes "derived path" installables)
   3. Rest of the flake-agnostic CLI

2. Flakes
   - Define the different layers of Nix?
   - Make Nix conform to these layers?

## Combined plan

Step 1 is technical work.
The remaining steps are stabilization steps.
For each of them, separate RFCs or other discussion media will describe the new interfaces to be stabilized, and solicit feedback.

### Step 0: Audit, refine, and stabilize the store-only installable-free CLI

There are certain commands like `nix store gc`, `nix store ping` that do not take any positional arguments.
As @roberth elsewhere pointed out, because these commands have so few degrees of freedom, they are some of the easiest to stabilize --- there is simply less to pour over and possibly bike-shed.

### Step 1: Split out a store-only Nix

This is detailed design from (accepted) [RFC 134].

The point of this step is not to re-open the already accepted decision to make the split, but to say it SHOULD be completed at this point.
In other words, step 0 is free to begin immediately, but steps 2 and beyond are blocked on finishing this.

The implementation of the split is already mostly complete, and preparatory improvements have already been merged, but if unforeseen issues arise finishing it, we can reconsider the dependency on this step from step 2.

### Step 2: Audit, refine, and stabilize the store-only Nix CLI

Stabilize *just* the command-line interface of the store-only Nix command.

This is a small portion of the total amount of interface we have to stabilize, and that will hopefully yield a narrow and more focused discussion.
Yet it will still offer some interesting topics to discus, such as:

- Logging
- Store paths on `stdout` at end of build?
- Should commands like `show-derivation` use `--json` by default?
- Flat vs hierarchical commands
- is `--derivation` a good flag? ([Nix issue #7261](https://github.com/NixOS/nix/issues/7261))

### Step 3: Attempt likewise splitting a store-and-language-only Nix

For the same reason that a store-only Nix is useful for validating the store-only CLI, and ensuring it works with many *possible* higher layers, it is also useful to build a store-and-language-only Nix, without Flakes.
Whether or not it is possible to actually do this is left to the Nix Team to decide, but it should be at least considered.

### Step 4: Audit, refine, and stabilize the store-and-language-only Nix CLI

This is the rest of the new CLI, without Flakes.
Unlike the store-only Nix command which has yet to be implemented, this is easy to visualize today by enabling the `nix-command` feature without the `flakes` feature.
This is a chance to discuss topics like:

- Is `--file` good, or should we be able to specify something like `file#attribute` to mix files and attributes? (Without using Flakes.)
- ~~Should all outputs be selected if one writes `foo.dev`?~~ Since fixed.
- How can `nix repl` have a more normal CLI?

Following the **gravity** principle, we will eventually want to pure eval and eval caching to be possible and easy to use without flakes; they should become part of this layer.
The stabilized CLI must "make room" for these features becoming part of this layer.

### Step 5: Audit, refine, and stabilize Flakes itself

Finally, with the other less controversial interfaces stabilized, we can tackle the Flakes itself, the one remainder.
This will require future RFCs.

As stated in the previous step, following the **gravity**, pure eval and eval caching should be possible and easy to use without flakes.
Ideally, by the time we get to this step, that is accomplished.
If it isn't, we should at least make sure that it will be possible to do so later.
It is OK to stabilize features that violate the layering principles, *only* so long as their stability does not impede fixing those violations later.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

Having laid out the plan, let us now return to how the current situation is characterized and see if the various facts that the factions orient themselves are respected.

## Layering principles

Ramifications to the user experience from layering being public:

  - The user has the option (it need not be mandatory!) to be aware of the layering and use it to learn Nix

  - Both perspectives are equally valid, and neither is prioritized over the other

  - While not going so far as to *insist* users are aware of layering and care about it, the layered archicture of Nix should be exposed to anyone that cares, and it shouldn't suddenly dissapear (as a mere implementation detail might).

Some examples of ways the principles are upheld:

- It is possible to use the Nix store without the Nix language
  - (**publicity**, **compositionality**)
  - Need `nix add-derivation` or similar to make this true!

- It possible to use other languages with the store
  - (**compositionality**)
  - Guix able to use Nix daemon is a possible way to demonstrate this is true.
- It is possible to use the Nix language without Flakes
  - (**compositionality**)
  - True already
- It is possible to use pure eval without flakes
  - (**gravity**, because "pure eval" is a feature not a layer)
  - 95% true, but some "last mile" functionality is needed to make this "ergonomic enough for people to believe it"

Also, because public aspects of Nix are subject to a (nebulous) stability promise, exposing layering publically necessarily means stabilizing aspects of that layering too.
The precise details are not formally worked about, but one example would be:

 - We shouldn't collapse layers that were distinct such that people that are using the former lower layer in isolation are suddenly forced to "pay" for something they aren't using (the former upper layer).

In the future, we might build atop this principles for a deeper notion of modularity: one should be able to replace the implementation of the layer with a different one, while using the same implementations of any layers above and below.
This is desirable but not currently required. E.g.:

   - There do exist multiple stores, that should continue to work (and work better than it does today)
   - We don't care about being able to swap out the evaluator in C++ Nix, however we *do* care that the language is defined well enough that other implementation of the Nix language is possible.

## Flakes are very popular

And they will be stabilized, with minimal delay.

Firstly, there is no feature work proposed in the interim --- the splitting of Nix is just partitioning existing functionality, with some behind-the-scenes refactors needed to make that possible.
The earlier steps have been carefully designed to be either easier or already started ("de-risked") to do our best to convince those that are concerned about the current "limbo" that stabilization will be gotten to no matter what, even if the splitting fails.

## Difficulties in the roll-out

Process concerns are addressed by having a clear process, with clear outcomes, before any stabilization is begun.
That is the purpose of this RFC!

## Flakes are criticized for eating other Nix features

We do *not* propose adding delay to once-again separate those features from Flakes, as that would introduce more feature work which would delay stabilization and be unacceptable to the pro-Flakes faction.

That said, an ancillary incremental beneift of incremental stabilization is to bolster a *sense* of layering in Nix's user interface that has been, according to some people, lost.
Ensuring that these two subsets of the new CLI --- without Flakes, and without Nix language support --- do in fact make sense in isolation will provide a "scaffolding" upon which interested parties can later introduce generalized features like search and pure eval without Flakes.

The hope is that such scaffolding will assuage this faction their concerns are heard without holding things up.

# Drawbacks
[drawbacks]: #drawbacks

The main downside is a delay from the process of splitting Nix up, and then a delay between the stabilization steps.

The fact that [RFC 134] is already mostly implemented, and in code review, is hopefully reason enough to believe it shouldn't take much longer.
That maximum delay waiting for that to complete should be dwarfed by duration of time we've spent "in limbo" without a clear plan to move forward.
We therefore think that is a small and reasonable price to pay for the benefit of community harmony.

An addition, in the detailed design there is an escape hatch saying that blocking on the implementation of [RFC 134] can be reconsidered if things do indeed take longer than foreseen.

The delay of "auditing and refining" shouldn't represent time "idle" from a stabilization perspective.
As long as we are making progress stabilizing features and having healthy discussions, we don't see any problem.

**Step 0** is also designed to take the pressure off these possible sources of delay, giving us *something* to work on that is not blocked on [RFC 134] or anything else.

# Alternatives
[alternatives]: #alternatives

We could, of course, just "rip off the band-aid" and stabilize everything at once.
The argument for that would be that enough time has passed and the concerns of (less numerous) long-time users are not important.
But we think the plan here has little downsides; we can instead make everyone happy with only some delay.
If that is true, why not do that instead!

# Unresolved questions
[unresolved]: #unresolved-questions

None at this time.

# Future work
[future]: #future-work

Generalizing features (like pure eval and search) to work without Flakes might be desired by the Flake-skeptic faction, but is purposely left as future work in order to not delay stabilization.

General feature stability lifecycle: https://discourse.nixos.org/t/potential-rfc-idea-stability/27055

[RFC 134]: ./0134-nix-store-layer.md
