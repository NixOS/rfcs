---
feature: stabilize-incrementally
start-date: 2022-09-15
author: John Ericson
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: @thufschmitt @tomberek @infinisil
shepherd-leader: @tomberek
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Stabilize the new command line interface and Flakes in an incremental fashion, leveraging [RFC 134](https://github.com/NixOS/rfcs/pull/134).
This plan is designed to still efficiently end the current "limbo" era of these unstable yet widely-used features, yet also soothe the longstanding tensions in the Nix community over how we got here.

# Motivation
[motivation]: #motivation

For the past few years, we've accumulated a massive backlog of unstable features in the form of the new command-line interface and flakes.
There is now a growing desire to stabilize those features, but as of yet no plan on exactly how to do so.
The tension between that desire and a lack of a clear plan has loomed over our heads for a while; this RFC aims to dispel it by providing a concrete plan, an plan that hopefully will mitigate the lingering controversies and tensions around Flakes.

## The situation so far

There are a few facts that must be introduced to give context to this situation.
We can't change these short of a time machine, so we must find a way to live with them instead.

### Flakes are very popular

As measured in the community polls, Nix has a lot of new users, dwarfing the number of long-time users.
Flakes is very popular among these new users.
Ergo, Flakes is very popular among the Nix community as a whole.

Like it or not, these users have been using Flakes as if it was stable, and we cannot make huge drastic changes that would break their code in hard-to-fix ways.

Many Groups and individuals interested in the continued growth the Nix community see Flakes are popular, an also wish it to be stabilized to attract further still more users, since Flakes are already proven to be popular among users.

### Difficulties in the roll-out

It is undeniable that the roll-out of these new features has been controversial.
Graham Christensen's blog post [flakes-are-an-obviously-good-thing](https://grahamc.com/blog/flakes-are-an-obviously-good-thing) lays out the procedure issues along the way quite well.

Some people were upset the Flakes RFC was abandoned but the feature merged.
Other people were fine with experimental features being merged without RFC, but were upset because Flakes never really *felt* experimental.
Experimental features would be modified a lot subject to community design use, and, most importantly, *discouraged* from being used in production.

### Flakes are criticized for encroaching on other features

There are many criticism about Flakes.
But one of them especially relevant to stabilizing is a perception that Flakes have encroached on other new features, in the sense that it ought to be possible to use them without Flakes but isn't in practice.
For example, there is no reason in theory pure eval requires Flakes, but without the ability to populate an initial whitelist of store paths that are safe to import it in practice does.

This is especially noticeable for new CLI features that *previously did*, in fact, work without Flakes.
For example, in earlier versions of Nix `nix search` worked without Flakes.

## A plan all sides can be happy with

Stabilizing the new CLI and Flakes will end the saga of the past few years.
It is a last good chance to soothe some of these tensions and put us on a good foot moving forward.
The new NixOS Foundation gives the RFC authors hope Nix is serious about addressing these sorts of governance issues, and thus would be a good way to further demonstrate we are turning a new leaf.

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

## Conclusion

By starting with this relatively easy material to stabilize, we can prove we can all come together as a community to agree on a design after all.
This should build trust between opposing individuals and factions, giving us a foundation upon which to tackle the more challenging material in subsequent steps.

Since these features became very popular while they are still unstable, there is now both an urgency to stabilize them, and little ability to modify them.
This is the opposite of how experimental features are supposed to leisurely incubate with both plenty of flexibility to change them, and little rush to stabilize them until they feel ready.
But, there is little we can do about this at this point, an this RFC recognizes that fact and does *not* try to resist it.

But, we have crossed that Rubicon and there is no turning back; this RFC *doesn't* attempt to change Flakes or the command line.

# Detailed design
[design]: #detailed-design

Step 1 is technical work, with a self-imposed deadline so we can be sure it doesn't delay stabilization too long.
The remaining steps are stabilization steps.
For each of them, a separate RFC or other discussion medium will describe the new interfaces to be stabilized, and solicit feedback.

## Step 0: Audit, refine, and stabilize the store-only installable-free CLI

There are certain commands like `nix store gc`, `nix store ping` that do not take any positional arguments.
As @roberth elsewhere pointed out, because these commands have so few degrees of freedom, they are some of the easiest to stabilize --- there is simply less to pour over and possibly bikeshed.

We can start stabilizing them right away, either in a batch, or one by one.

## Step 1: Split out a store-only Nix, with deadline

This is the same as step one from [RFC 134](https://github.com/NixOS/rfcs/pull/134), upon which this RFC depends.

A deadline is imposed to get that complete, so agreement on this stabilization plan is guaranteed not to add more than a small bounded delay as opposed to stabilizing everything immediately.

## Step 2: Audit, refine, and stabilize the store-only Nix CLI

If the deadline for step 1 is met, then we stabilize *just* the command-line interface of the store-only Nix command.

This is a small portion of the total amount of interface we have to stabilize, and that will hopefully yield a narrow and more focused discussion.
Yet it will still offer some interesting topics to discus, such as:

- logging
- store paths on `stdout` at end of build?
- Should commands like `show-derivation` use `--json` by default?
- Flat vs hierarchical commands
- is `--derivation` a good flag?

## Step 3: Attempt likewise splitting a nix lang without flakes Nix CLI

For the same reason that a store-only Nix is useful for validating the store-only CLI, and ensuring it works with many *possible* higher layers, it is also useful to build a Store + Nix lang -only Nix without Flakes.
Whether it or not it is possible to actually do this is left to the Nix Team to decide, but it should be at least considered/attempted.

## Step 4: Audit, refine, and stabilize the rest of the CLI, without Flakes

If the deadline for step 1 is *not* met, we jump directly to this step, skipping step 2.

This is the rest off the new CLI, without flakes.
Unlike the store-only Nix command which has yet to be implemented, this is easy to visualize today by enabling the `nix-command` feature without the `flakes` feature.
This is a chance to discuss topics like:

- Is `--file` good, or should we be able to specify something like `file#attribute` to mix files and attributes? (Without using Flakes.)
- Should all outputs be selected if one writes `foo.dev`?
- How can `nix repl` have a more normal CLI?

## Step 5: Audit, refine, and stabilize Flakes itself

Finally, with the other less controversial interfaces stabilized, we can tackle the Flakes itself, the one remainder.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

Having laid out the plan, let us now return to how the current situation is characterized and see if the various facts that the factions orient themselves are respected.

## Flakes are very popular

And they will be stabilized, with minimal delay.

Firstly, there is no feature work proposed in the interim --- the splitting of Nix is just partitioning existing functionality, with some behind-the-scenes refactors needed to make that possible.
The deadline placed on that work also assuages those concerned about the current "limbo" that stabilization will be gotten to no matter what, even if the splitting fails, after a set amount of time.

## Difficulties in the roll-out

Process concerns are addressed by having a clear process, with clear outcomes, before any stabilization is begun.
That is the purpose of this RFC!

## Flakes are criticized for eating other Nix features

We do *not* propose adding delay to once-again separate those features from Flakes, as that would introduce more feature work which would delay stabilization and be unacceptable to the pro-Flakes faction.

That said, an ancillary incremental process of incremental stabilization is to bolster a *sense* of layering in Nix's user interface that has been, according to this camp, lost.
Ensuring that these two subsets of the new CLI --- without Flakes, and without Nix language support --- do in fact make sense in isolation will provide a "scaffolding" upon which interested parties can later introduce generalized features like search and pure eval without Flakes.

The hope is that such scaffolding will assuage this faction their concerns are heard without holding things up.

# Drawbacks
[drawbacks]: #drawbacks

The main downside is a small delay from the splitting Nix process, and then delay between the stabilization steps.

The first delay has a guaranteed upper bound, thanks to its self-imposed deadline.
That maximum delay should be dwarfed by duration of time we've spent "in limbo" without a clear plan to move forward.
We therefore think that is a small and reasonable price to pay for the benefit of community harmony.

The second delays don't represent time "ideal" from a stabilization perspective.
As long as we are making progress stabilizing features and having healthy discussions, we don't see any problem.

**Step 0** is also designed to take the pressure off these possible sources of delay, giving us *something* to work on that is not blocked on RFC 134 or anything else.

# Alternatives
[alternatives]: #alternatives

We could, of course, just "rip off the band-aid" and stabilize everything at once.
The argument for that would be that enough time has passed and the concerns of (less numerous) long-time users are not important.
But we think the plan here has little downsides; we can instead make everyone happy with only a small delay.
If that is true, why not do that instead!

# Unresolved questions
[unresolved]: #unresolved-questions

How long should the deadline for creating the store-only Nix be?

# Future work
[future]: #future-work

Generalization features to work without Flakes, like pure eval and search, might be desired by the Flake-skeptic faction, but is purposely left as future work in order to not delay stabilization.

We could have a no-Flakes Nix just as we have a no-eval Nix, given every step of stabilization an minimal Nix executable with just the stabilized commands implemented.
This is also left as future work to avoid controversy and minimize delay.
