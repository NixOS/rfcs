---
feature: git-hashing
start-date: 2022-08-27
author: John Ericsion (@Ericson2314) on behalf of [Obsidian Systems](https://obsidian.systems)
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: edolstra, kevincox, gador, @amjoseph-nixpkgs
shepherd-leader: amjoseph-nixpkgs
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Integrate Git hashing with Nix.

Nix should support content-addressed store objects using git blob + tree hashing, and Nix-unaware remote stores that serve git objects.

This follows the work done and described in https://github.com/obsidiansystems/ipfs-nix-guide/ .

# Motivation
[motivation]: #motivation

## Binary distribution

Currently distributing Nix binaries takes a lot of bandwidth and storage.
This is a barrier to being a Nix user in areas of slower internet --- which includes the vast majority of the world's population at this time.
This is also a barrier to users running their own caches.

Content-addressing opens up a *huge* design space of solutions to get around such problems.

The first steps proposed below do *not* tackle this problem directly, but it lays the ground-work for future experiments in this direction.

## Source distribution and archival

Source code used by Nix expressions frequently goes off-line. It would be beneficial if there was some resistance to this form of bitrot.
The Software Heritage archive stores much of the source code that Nix expressions use. They would be a natural partner in this effort.

Unfortunately, as https://www.tweag.io/blog/2020-06-18-software-heritage/ describes at the end, a major challenge is the way Nix content-addresses software.
First of all, Nix hashes sources in bespoke ways that no other project will adopt.
Second of all, hashing tarballs instead of the underlying files leads non-normative details (compression, odd perms, etc.).

We should natively support git file hashing, which Git repos and Software Heritage both support.
This will completely obliterate these issues.

Overall, we are building out a uniform way to work with source code, regardless of its origins or the exact tools involved.

## Build adoption through seamless interop

This last argument is more strategic than technical.

A lot of people in this community would like to see Nix be used more widely, but as much as we all wish otherwise, the fact remains that there is some tension between making nix *better* and making it *more accessible*.

Nix is very foreign from the "bad conventional" way things are done, and making Nix better can sometimes involve making it even more foreign.
We don't want to steepen the learning curve or make it "seem more weird".

On the other hand, making Nix more accessible by making it more like tools users are already use-to can obscure or chip-away at Nix's benefits.
We don't want to "pander" in ways that will make Nix faddish but ultimately undermine it's popularity over the long haul (see Docker the company's woes).

One way to get around this tension to me is rather than pushing Nix towards the rest of the world, pushing the rest of the world towards us.
Like-minded projects emphasizing content-addressing are our *natural* partners, and we should work with them to promote Nix-*agnostic* standards that further our values and mission.

# Detailed design
[design]: #detailed-design

Each item can be done separately provided its dependent items are also done.
These are the items we wish to commit to at this time.
(The goals mentioned future work are, in a separate document, also broken down into a dependency graph of smaller steps.)

## Git file hashing

- **Purpose**: Source distribution and archival

In addition to the various forms of content-addressing Nix supports today ("text", "fixed" with either "flat" or "nar" serialization of file system objects), Nix should support Git hashing.
This support entails two basic things:

 - Content addresses are used to compute store paths.
 - Content addresses are used to verify store object integrity.

Git hashing would not (in this first proposed version) support references, since references in Nix's sense are not part of Git's data model.
This is OK for now; encoding references is not needed for the intended initial use-case of exchanging source code.

## Git file hashing for `buitins.fetch*`

- **Purpose**: Source distribution and archival
- **Depends on**: Git file hashing,

The builtin fetchers can also be made to work with git file hashing just as they support the other types.
In addition, Git repo fetching can leverage this better to than the other formats since the data in git repos is already content-addressed in this way.

## Nix-agnostic content-addressing "stores"

- **Purpose**: All distribution

We want to be able to substitute from an arbitrary store (in the general, non-Nix sense) of content-addressed objects.
For the purpose of this RFC, that means querying objects by git hash, and being able to trust the results because we can verify them against the git hash.

In the implementation, we could accomplish this in a variety of ways.

- On on extreme, we could have a `ContentAddressedSubstitutor` abstract interface completely separate from Nix's `Store` interface.

- On the other extreme, we can generalize `Store` itself to allow taking content addresses or store paths as references.

Exactly how this shakes out is to be determined post-RFC, but it would be nice to use Nix-agnostic persistent methods with `--store` and `--substituters`.

If we do go the route of modifying the `Store` class, note that these things will need to happen:

 - Many store interface methods that today take store paths will need to also accept names & content address pairs.

   For stores that are purpose-built for Nix, like the ones we support today, all addressing can be done with store paths, so the current interface is fine.
   But for Nix-agnostic stores, store paths are rather useless as a key type because Nix-agnostic tools don't know about them.
   Those store can, however, understand content addresses.
   And from such a name + content address, we can always produce a store path again, so there is no loss of functionality with existing stores.

- Relax `ValidPathInfo` to merely require that *either* the pair of `NarHash` and `NarSize` or just `CA` alone be defined.

  As described in the first step, currently `NarHash` and `NarSize` are the *normative* fields which are used to verify a store object.
  But if the store object is content-addressed, we don't need these, because the content address (`CA` field) will also suffice, all by itself.
  
  Existing Nix stores types are still required to contain a `NarHash` and `NarSize`, which is good for backwards compat and don't come with a cost.
  Only new nix-agnostic store types would take advantage of these new, relaxed rules.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

We encourage anyone interested to check our tutorial in https://github.com/obsidiansystems/ipfs-nix-guide/ which demonstrates the above functionality.
Note at the time of writing this guide uses our original 2020 fork of Nix.

# Drawbacks
[drawbacks]: #drawbacks

## Complexity

The main cost is more complexity to the store layer.
For a few reasons we think this is not so bad.

Most importantly is the division of the work into a dependency graph of steps.
This allows us to slowly try out things like IPFS that leverage Git hashing, and not commit to more change than we want to up front.

Even if we do end up adopting everything though, we think for the following two reasons the complexity can still be kept manageable:

1. Per the abstract vs concrete model of the nix store in https://github.com/NixOS/nix/pull/6877 , everything we are doing is simply flushing out alternative interpretations of the abstract model.
   This is the sense in which we are "removing the weaknesses and restrictions that make additional features appear necessary" per the Scheme mantra cited above:
   Instead of extending the model with new features, we are relaxing concrete model assumptions (e.g. references are always opaque store paths) while keeping the abstract model the same.

2. We also support plans to decouple the layers of Nix further, and update our educational and marketing material to reflect it.
   With Flakes and other post-2.0 features, the upper layers of Nix have gained an enormous amount of flexibility and sophistication.
   RFCs like this show that the so-far more sleepy lower layers also have plenty of potential to gain sophistication too.

   Embracing layering on technical, educational, communications, and managerial levels can scale our capacity to manage complexity and sophistication without the project growing out of control.
   It will "divide and conquer" the project so the interfaces between each layer are still rigorously enforced preventing a combinatorial explosion in complexity.
   That frees up "complexity budget" for project like this.

   We plan on more formally proposing this next.

## Git and Nix's file system data models do not entirely coincide

Nix puts the permission info of a file (executable bit for now) with that file, whereas Git puts it with the name and hash in the directory.
The practical effect of this discrepancy is that a root file (as opposed to directory) in Nix has permission info, but does not in Git.

If we are trying to convert existing Nix data into Git, this is a problem.
Assuming we treat "no permission bits" as meaning "non-executable", we will have a partial conversion that will fail on executable files without a parent directory.
Tricks like always wrapping everything in a directory get around this, but then we have to be careful the directory is exactly as expected when "unwrapping" in the other direction.

For now, we only focus on ingesting data *from* Git *to* Nix, and this side-steps the issue.
That conversation is total (though not surjective), and so there is no problem for now.

# Alternatives
[alternatives]: #alternatives

The dependency graph of steps can be sliced to save some for future work.
For now they are all written together, but during the RFC meetings we will decide which steps (if any) to ratify now, and which steps to save for later.

# Unresolved questions
[unresolved]: #unresolved-questions

None at this time.

# Future work
[future]: #future-work

- Integrate with outside content-addressing storage/transmission like

  - The Software Heritage archive

  - IPFS
