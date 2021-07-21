---
feature: musl-libc
start-date: 2018-02-19
author: Will Dietz (@dtzWill)
co-authors: Shea Levy (@shlevy)
related-issues: 34645, 6221, ...
category: feature
---



# Summary
[summary]: #summary

When targeting Linux platforms, Nixpkgs builds software against
the defacto standard of Linux libc implementations:
[glibc](https://www.gnu.org/software/libc/).

This RFC proposes adding **experimental** support in Nixpkgs for the use
of an alternative libc implementation, [musl](https://www.musl-libc.org/),
for the reasons outlined below.
Adding this support is similar to introducing support for an architecture,
and realistically will be limited in compatibility and features
compared to non-musl siblings such as `x86_64-unknown-linux-gnu`.

Initial support is already available in nixpkgs master, capable
of building up through important packages such as nixUnstable itself
and LLVM.  This is not to be taken as an endorsement: discussing
and ultimately deciding whether support for musl should be part of nixpkgs
is the subject of this RFC.  That said, this initial support is
a reasonable foundation for evaluating technical details discussed below,
and a convenient way for interested parties to explore the work so far.

To help ensure we're all on the same page, unless otherwise specified
assume references to musl support implementation are in reference
to this commit (latest master at time of writing):

[bd7d5b365799a145717d31122ebfd24b51fea117](https://github.com/NixOS/nixpkgs/commit/bd7d5b365799a145717d31122ebfd24b51fea117)

# Motivation
[motivation]: #motivation

## Why Musl?
There are many reasons to prefer the use of musl.

musl is advertised as being:
* lightweight
* fast
* simple
* free
* correctness: standards-conforming
* correctness: safety

Additionally it is very popular when statically linking software,
creating binaries capable of executing most anywhere.

In fact it is for this reason that Nixpkgs itself builds
the bootstrap busybox using musl.

A somewhat outdated overview comparing musl against other
implementations is available [here](http://www.etalabs.net/compare_libcs.html).
Note this comparison is maintained by the (primary) author of musl,
(as indicated at the top of the page).

I'm unable to find good numbers but musl is "arguably" the second
most popular libc implementation on Linux, and is used
by a number of important projects you may be familiar with
large userbases, including:
* Alpine Linux - [#70 on Distrowatch](https://distrowatch.com/table.php?distribution=alpine) but very popular amongst docker users for producing slim container images.
* [OpenWRT/LEDE](https://openwrt.org/) - #1 open-source Linux router firmware project; foundation of most other projects targetting routers.
More projects and details of how they use musl can be found here:

https://wiki.musl-libc.org/projects-using-musl.html

## Why Nixpkgs?

The importance of musl is not the primary point of contention in this RFC,
instead perhaps the main question is whether such support belongs in Nixpkgs or not.

The main arguments for inclusion are:
* **convenience of use**
* **foundation for exciting future work**: musl is widely used by high-level languages
  as the libc implementation used to produce statically linked programs:
  these are easy to deploy, launch quickly, and only include the code required.
  (NOTE: currently musl support prefers dynamic linking and shared libraries
   as is the strong preference in Nixpkgs)
* Software sometimes must be patched to compile or run with musl; in @dtzWill's experience,
  these changes are largely fixes improving compliance and correctness resulting in
  higher-quality programs.  Recent versions of glibc have started taking stronger stances
  on enforcing compliance (look at patch fallout folllowing any glibc upgrade in last year or so)
  resulting in overlapping work from both sides.
  (NOTE: use of glibc extensions or reliance on non-standard behavior is still common and unlikely to go away soon)

And to a large extent:
"Why not?" -- similar to including support for architectures such as Aarch64 or RISC-V,
  and just like support for those architectures it's relatively clear that pushing them
  into private forks would be detrimental to the nixpkgs project as well as all users
  interested in using Nixpkgs on those platforms/architectures.

musl is clearly useful for a variety of important use cases,
however including support has a few costs (see Drawbacks, below):
do folks believe the costs are too high?


## Additional Resources

* [musl FAQ](https://www.musl-libc.org/faq.html)
* [projects using musl](https://wiki.musl-libc.org/projects-using-musl.html)
* [Slides from a talk discussing various libcs, 2014](http://events17.linuxfoundation.org/sites/events/files/slides/libc-talk.pdf)

## Related Isssues

* [big musl PR](https://github.com/NixOS/nixpkgs/pull/34645)
* [issues matching "musl", newest first](https://github.com/NixOS/nixpkgs/search?o=desc&q=musl&s=created&type=Issues&utf8=%E2%9C%93)
* [2015 libc discussion](https://github.com/NixOS/nixpkgs/issues/6221#issuecomment-116754223)

# Detailed design
[design]: #detailed-design

## Goals
### Laying the Foundation

Implement the following in nixpkgs:

* [x] musl-based bootstrap
* [x] stdenv for native musl building
* [x] cross-musl stdenv

These are already implemented and are currently tested
to build and provide basic functionality as part
of release-cross.nix.

These features would be very difficult to implement
or maintain externally, and near impossible as an overlay.

## Package Compatibility

For a variety of reasons many packages do not work out-of-the-box
in musl-based environments.

### "Normalization"

Vast majority of the problems here are "minor" and are the
sort of problem we regularly encounter and address when
bumping to a new glibc version, new gcc version, or using
a clang-based stdenv (such as on Darwin).

I'm calling these fixes "normalization".
These are changes like "adding a missing include" or
"don't assume compiler is invoked 'gcc'".

These changes usually can be safely applied on all platforms
(although sometimes they are not for rebuild reasons)
and are easy to check for correctness or at least "couldn't-possibly-hurt".

### Big Incompatibilities

Some packages are very much not portable and require significant
and invasive changes to work with environments they don't expect.

In the context of this RFC's proposed musl support,
there are a number of packages that are known to be in this category:

* systemd
* ...

This RFC proposes ignoring those for the immediate future,
to be revisited later, and focuses on systemd.

#### Systemd

Currently many packages depend on systemd.
This dependency is indirect for all but a handful of packages,
with a few key pieces of software integrating with systemd.

As far as I know this dependency is generally optional,
and so we could easily avoid its use when using musl.

This makes it possible to build a great number of packages
(thousands) but more complicated software "ecosystems"
and "desktop environments" will not work without something
to tie them together with the various roles played by systemd.

Addressing this in any way is not in the scope of this RFC.

Similarly, NixOS itself (especially services) require systemd
and we do not propose altering this.

An early version of the "musl PR" patched systemd so that it
would build successfully, using patches from OpenEmbedded.org.

The result was never tested or reviewed in terms of providing
basic functionality or general suitability for Nixpkgs/NixOs.

(OE folks do great work, but they may expect rather different
things from systemd or workaround introduced shortcomings elsewhere
in various capacities)

## Scope

Primarily non-GUI packages for now, due to systemd blocker.

In the future these will be supported.

This RFC is primarily concerned with the groundwork for using musl at all.

## Testing and Maintenance

"Ideally" the answer would be an infinite number of builders would constantly
build all the things on all the platforms.

Unfortunately this is unrealistic due to capacity constraints and other reasons.

### Responsibility

"musl team" is reponsible, initially consisting of

* @dtzWill
* @shlevy
* @domenkozar
* @rasendubi

A team handle will be created to track this
and to ping the team on musl-related discussion or issues.

### Infrastructure

Build at least stdenv with more being added in the future.

Jobs may be given lower priority/shares.

# Drawbacks
[drawbacks]: #drawbacks

Why should we *not* do this?

Potential maintenance burden, particularly regarding collections of patches,
seems to be the primary concern.

## Additional Costs

* Maintenance
* Infrastructure (build pressure, storage, ...)

## Fractured Community

> Another issue: adding musl support fractures the Nixpkgs user/development community: some people will run musl-based packages and some will run glibc-based packages. As a result all of Nixpkgs/NixOS will end up being less tested. it doubles the test matrix on Linux, after all.

## Previous Discussion of drawbacks and concerns

This RFC was prompted by concerns about the drawbacks:
["I'm really not in favour of adding support to Nixpkgs"](https://github.com/NixOS/nixpkgs/pull/34645#issuecomment-366789321).
This comment echoes very similar concerns expressed [back in 2015](https://github.com/NixOS/nixpkgs/issues/6221#issuecomment-116754223).

# Alternatives
[alternatives]: #alternatives

* Maintain in a separate fork
  * [SLNOS project is willing to adopt](https://github.com/NixOS/nixpkgs/pull/34645#issuecomment-366845015)
* Maintained as an overlay
* No musl libc support.
  * Not really an "alternative" :).

# Unresolved questions
[unresolved]: #unresolved-questions

What parts of the design are still TBD or unknowns?

## Support

We need to work on defining:

* What "Support" entails
* Responsibility
* Blame?

For now we leave it as an informal understanding
which we can improve on in the future.

## Impact

### Infrastructure

* Hydra
* ofborg

### Complexity

* evaluation complexity
  * cost of behind-the-scenes "magic" required
* keeping expressions avoidable
  * cyclomatic complexity

## How to Remove?

Is there a good way to move forward
without becoming impossibly intertwined?
Such that a future party could
* reduce nixpkgs to what it "would be" without musl support
* Do so confidently without worrying about subtle
  breakages?

Maintaining entirely as an overlay (or fork?)
is an obviously effective solution in this regard.
Clear separation and enforced use of carefully crafted
interfaces/abstractions may also help with this.

To some extent the importance of this depends
on how likely the community expects to find itself
"regretting" or wanting to be "rid" of musl support.

However the design and use of good abstractions
is valuable in all cases :).

# Future work
[future]: #future-work

### Fetch, Unpack, Patch

(TODO: Split to new RFC?)
It may be possible to leverage proper use of "phases" so that
we can provide reasonable coverage of the unpack and patch
phases for all "supported" configurations.

As an example, this would make it possible for our x86_64 builders and users to
get feedback ensuring that changes didn't break hashes or patch application
elsewhere without requiring builders of each configuration.

The benefit of this would be in avoiding most of the burden of building everything
while making it easy to catch the most common sort of problems
so they can be addressed ("oops I didn't update the hash for darwin")
or flagged for investigation.

I believe there's a branch or PR trying this somewhere.
Regardless, out of scope for this RFC.
