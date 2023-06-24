---
feature: git-hashing
start-date: (fill me in with today's date, YYYY-MM-DD)
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
(See the two Future Work sections for other steps left for later.)

## Git file hashing

- **Purpose**: Source distribution and archival

In addition to the various forms of content-addressing Nix supports today ("text", "fixed" with either "flat" or "nar" serialization of file system objects), Nix should support Git hashing.
This support entails two basic things:

 - Content addresses are used to compute store paths.
 - Content addresses are used to verify store object integrity.

Git hashing would not support references (since references in Nix's sense are not a Git concept), but that is not an issue for the intended use-case of exchanging source code.

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

# Future work --- Software Heritage
[future]: #future-work-swh

## Motivation

Software Heritage is a great way to get source code that is no longer found at its original location online.
It would be really great to use it as a substituter to fetch source code that fails to be fetched the default way.

## Detailed Designed

- **Depends on**: Nix-agnostic content-addressing "stores"

[`GET /api/1/raw/(swhid)/`](https://docs.softwareheritage.org/devel/swh-web/uri-scheme-api.html#get--api-1-raw-(swhid)-)
is a relatively new Software Heritage API endpoint to get a git object for the given SWHID.
We can used this to write a Software Heritage store, which will accomplish the task layed out in the previous motivation section.

# Future work --- IPFS
[future]: #future-work-ipfs

## Motivation

### Binary Distribution

IPFS is a potential solution leveraging content addressing for a P2P CDN.
It out-of-the-box match's Nix's data model extremely well.

### Source distribution and archival

IPFS also supports git hashing, and so we also provide a good way for people and institutions to "pin" the sources they need, especially if those sources include private ones Software Heritage won't have.
Finally, per [this IPFS plugin](https://blog.obsidian.systems/software-heritage-bridge/), we can have a 3 way integration between IPFS, Software Heritage, and Nix.
Data can be directly downloaded from Software Heritage via HTTPS, or indirectly via IPFS.

This would hopefully supercede the direct Software Heritage store outlined above.
This is because Software Heritage is primarily an archive, and we should be careful not to waste their limitted resources with copious egress bandwidth.
IPFS can act as a CDN to not put as much load on Software Heritage's servers.

### Not just IPFS

Many of the IPFS-specific logic could in fact live in a plugin if this is desired.
However, we still need to adjust core abstractions of Nix store layer (as described below) to interface with IPFS in the best possible way.
Those same adjustments would allow Nix to work better with *any* content-addressing system, so alternatives networks/projects to IPFS can also be just as easily experimented with.

As always with my work, the mantra (from Scheme) to follow is

> *x* should be designed not by piling feature on top of feature, but by removing the weaknesses and restrictions that make additional features appear necessary.

A ton of misc features have been added to Nix since 2.0, and we are very careful to not increase total ad-hoc complexity more than necessary.

## Detailed Design

Each item can be done separately provided its dependent items are also done.
These are the items we do *not* wish to commit to at this time, but leave for later.
(See [Detailed Design](#detailed-design) for other steps left for later.)

### Augmented `narinfo`

- **Purpose**: Binary distribution

*This is taken from [RFC PR 122](https://github.com/lucasew/rfcs/blob/binary-cache-ipfs/rfcs/0122-binary-cache-ipfs.md), which was abandoned by its author.*

The purpose of this is a "hybrid" store where the narinfo metadata is still served via HTTPS, but the data itself is served via IPFS.

Today, a narinfo looks like this:

```
StorePath: /nix/store/gdh8165b7rg4y53v64chjys7mbbw89f9-hello-2.10
URL: nar/0i6ardx43rdg24ab1nc3mq7f5ykyiamymh1v37gxdv5xh5cm0cmb.nar.xz
Compression: xz
FileHash: sha256:0i6ardx43rdg24ab1nc3mq7f5ykyiamymh1v37gxdv5xh5cm0cmb
FileSize: 40360
NarHash: sha256:1ddv0iqq47j0awyw7a8dmm8bz71c6ifrliq53kmmsfzjxf3rwvb8
NarSize: 197528
References: 7gx4kiv5m0i7d7qkixq2cwzbr10lvxwc-glibc-2.27 gdh8165b7rg4y53v64chjys7mbbw89f9-hello-2.10
Deriver: 5sj6fdfym58sdaf3r5p87v4l8sj2zlvn-hello-2.10.drv
Sig: cache.nixos.org-1:K0thQEG60rzAK8ZS9f1whb7eRlIshlMDJAm7xvX1oF284H+PTqlicv/wGW6BIj+wWWONHvUZ2MYc+KDArekjDA==
```

This RFC proposes new key-value pairs that in this example would be:

```
IpfsCid: Qmf8NfV2hnq44RoQw9vxmSpGYTwAovA8FUCxeCJCqmXeNN
IpfsEncoding: {"method":"wrapped-nar","chunking":{"leaf-format":"raw","strategy":"fixed-size"},"layout":"balanced","max-width":174}
```

Just as today, the `NarHash` and `NarSize` remain the *normative* way to lock down the store object the `narinfo` file describes.
Conversely, The `URL`, `FileHash` and `FileSize` by contrast are *informational*, describing not what the store object *is*, but *how to get it*.

The `IpfsCid` and `IpfsEncoding` are likewise informational, describing how to get the store object:

- `IpfsCid`: Native content address for IPFS.

- `IpfsEncoding`: Enough info to deterministically rebuild the IPFS representation from a non-IPFS copy of the store object.

   For now, `IpfsEncoding` will only support `unixfs-nar`, which works as follows:

   The NAR is itself wrapped in IPFS's [UnixFS](https://github.com/ipfs/specs/blob/main/UNIXFS.md).
   This other format can be extracted from the CID (which is conceptually a pair of encoding metadata and a hash).
   For now, only IPFS's "unixfs" is supported.
   `chunking`, `layout`, and `max-width` are tuning parameters for unixfs [described in the UnixFS spec](https://github.com/ipfs/specs/blob/main/UNIXFS.md#importing).

   "UNIXFS" is not used directly because it doesn't support the "executable bit" Nix does on files.
   NAR archive are not used directly because IPFS doesn't support arbitrarily large objects.

### IPFS Narinfo and "stateful" IPFS Store

- **Purpose**: Binary distribution
- **Depends on**: Augmented `narinfo`

Instead of a "hybrid" store, where the narinfo index is served with HTTP but the data itself is served with IPFS, we can do an all-IPFS store with the data itself and mutable index stored in IPFS.
The Narinfo instead of being encoded the legacy line-oriented text format can be IPFS's native DAG-CBOR IPLD codec, which is like JSON + content address links (but stored as CBOR).
This allows Narinfos to reference each other and be nicely structured so the index is legible from Nix-agnostic IPFS tools and recursive pinning comes for free.

Read-only is easier, since IPFS data is immutable but "writable" stores are supported by simple printing back a new CID for the new store root after some modifications, or modifying a mutable IPNS reference.
IPNS is historically slow, but the update is automatic.
Printing out a new CID for the index root allows the store administrator to update an out-of-bound mutable reference, but this cannot be automated because Nix doesn't know what the out-of-band method is.

### "stateless" IPFS store

- **Purpose**: Source distribution and archival
- **Depends on**: Nix-agnostic content-addressing "stores"

Use the above functionality to create a "stateless" IPFS store.
Opaque store path lookups always fail, but when the key is the new content address type, we can translate the key itself into a CID that we can look up.

Unlike the previous two flavours of IPFS store, this one is stateless in that there is no need for an index at all.
Only content-addressed data is looked up, and it doesn't need any nar-info metadata before the data is all there.

We need the previous step for querying without fetching any data.
In that case since there is no narinfo index we're looking up, we don't get any additional metadata back.
But the content address key a successful query used is enough to create a bare-bones `ValidPathInfo` with a `CA` field, which with the enough step is valid.

(A bare-bones `ValidPathInfo` might sound sub-par, but for plain old content-addressed data it is fine.
Most of the other metadata in `ValidPathInfo` is really just for input-addressed derivation outputs, and is thus obviated by CA derivation trust maps which contain the same data but more naturally.)

### Wrapped git objects with references

- **Purpose**: Binary distribution
- **Depends on**: Git file hashing

Merkelized formats like git file hashing are better than NAR because that allow for very natural deduplication and minimal transfers.
This is the same benefit we get today with Nix within a closure of multiple store objects, now also *within a single store object*.
But git has no notion of Nix-style references, so plain git hashing is only suitable for leaf store objects without references (like source code).

However, we can use IPLD to wrap git-hashed data with a reference set, and "has self reference" bit.
This easily creates a new content addressing scheme which handles all "shapes" of store objects.
This gives is a nice way to thus share arbitrary nix store data (provided it is content-addressed) over IPFS.

Like with "IPFS Narinfo", this format is also very easy to understand with nix-agnostic native IPFS tools.
This is because, once again, the reference graph is made native to IPFS not done indirectly with store path strings which must be looked up.

An interesting corollary to note:
Content addressing today is "shallow", in that references are arbitrary store paths.
With this form on content addressing, references are instead CIDs (native IPFS references) to other obligatorily content-addressed data.
This means the content addressing is "deep", such that any such content-addressed store object always has a content-addressed closure.
At the cost of interop with existing derivation outputs, this make such data easier to manage because there are fewer trust issues and degrees of freedom in general for something to go wrong.

### IPLD Derivations

- **Purpose**: Build plan distribution
- **Depends on**: Wrapped git objects with references,
                  IPFS as substitutor

Natively represent derivations in IPFS, again with the same benefits of leverage the native graph representations.

This is a culmination of all the features so far.
The derivations must be CA derivations (floating or fixed).
They must also produce wrapped git objects with references, though they can also depend on regular unwrapped git file hashed store objects.

The derivations and their outputs are thus all fully IPFS native, leveraging the IPFS graph and trust vs plain old data separation for the high standard of interoperability.
