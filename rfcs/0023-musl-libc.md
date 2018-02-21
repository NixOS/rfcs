---
feature: musl-libc
start-date: 2018-02-19
author: Will Dietz (@dtzWill)
co-authors: Shea Levy (@shlevy)
related-issues: 34645, 6221, ...
---



# Summary
[summary]: #summary

When targeting Linux platforms, Nixpkgs builds software against
the defacto standard of Linux libc implementations:
[glibc](https://www.gnu.org/software/libc/).

This RFC proposes supporting the use of an alternative libc implementation,
[musl](https://www.musl-libc.org/), for the reasons outlined below.
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
There are many reasons to prefer the use of musl,
a somewhat outdated overview comparing musl against other
implementations is available [here](http://www.etalabs.net/compare_libcs.html).
Note this comparison is maintained by the (primary) author of musl,
(as indicated at the top of the page).

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
* convenience of use
* foundation for exciting future work: musl is widely used by high-level languages
  as the libc implementation used to produce statically linked programs:
  these are easy to deploy, launch quickly, and only include the code required.
  (NOTE: currently musl support prefers dynamic linking and shared libraries
   as is the strong preference in Nixpkgs)
* Software sometimes must be patched to compile or run with musl; in @dtzWill's experience,
  these changes are largely fixes improving compliance and correctness resulting in
  higher-quality programs.  Recent versions of glibc have started taking stronger stances
  on enforcing compliance (look at patch fallout folllowing any glibc upgrade in last year or so)
  resulting in overlapping work from both sides.

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

I believe the linked implementation from current nixpkgs master is perhaps
the best embodiment of "Detailed Design"?

Linky: [bd7d5b365799a145717d31122ebfd24b51fea117](https://github.com/NixOS/nixpkgs/commit/bd7d5b365799a145717d31122ebfd24b51fea117)

# Drawbacks
[drawbacks]: #drawbacks

Why should we *not* do this?

Potential maintenance burden, particularly regarding collections of patches,
seems to be the primary concern.

This RFC was prompted by concerns about the drawbacks:
["I'm really not in favour of adding support to Nixpkgs"](https://github.com/NixOS/nixpkgs/pull/34645#issuecomment-366789321).
This comment echoes very similar concerns expressed [back in 2015](https://github.com/NixOS/nixpkgs/issues/6221#issuecomment-116754223).

## Rebuttal

I believe the burden is not nearly as high as believed, for a few reasons:

* musl is a "real" libc in terms of features, with improved safety in resource-constrained environments.
* glibc has increasingly enforced compliance, resulting in many packages being updated quickly or being patched by many other distributions as well.
* Nixpkgs has grown, making this much easier: "libc" abstraction is needed to properly support platforms such as Darwin and particularly the work
  providing support for cross-compilation greatly simplifies the changes needed to support musl.
  (the "big musl PR" is largely fixing cross-compilation further)

# Alternatives
[alternatives]: #alternatives

* No musl libc support.
* Maintained in a separate fork

# Unresolved questions
[unresolved]: #unresolved-questions

What parts of the design are still TBD or unknowns?

# Future work
[future]: #future-work

What future work, if any, would be implied or impacted by this feature
without being directly part of the work?
