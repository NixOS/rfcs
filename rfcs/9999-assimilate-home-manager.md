- feature: All Your Home Manager Are Belong to Us
- start-date: (fill me in with today's date, YYYY-MM-DD)-
- author: Anderson Torres
- co-authors: (find a buddy later to help out with the RFC)
- shepherd-team: (names, to be nominated and accepted by RFC steering committee)
- shepherd-leader: (name to be appointed by RFC steering committee)
- related-issues: (will contain links to implementation PRs)

# Summary
[summary]: #summary

Assimilate home-manager project into Nixpkgs monorepo.

# Terminology
[terminology]: #terminology

Henceforth,

- Home Manager will be called _HM_;
- The typical unprivileged user of a system will be called _basic user_;
- The typical privileged user of a system will be called _superuser_;

# Motivation
[motivation]: #motivation

Nix the language has at least three large-size consumers, namely:

- [Nixpkgs](https://github.com/NixOS/nixpkgs), the biggest packageset in
  existence;
- [NixOS](https://nixos.org/), the reference work on declarative configuration
  and deployment of a Linux distribution; and
- [Home Manager](https://nix-community.github.io/home-manager/), another
  reference work on declarative user-specific configuration management and
  deployment.

Since at least 2014, NixOS was assimilated into Nixpkgs monorepo, now living
inside `nixos` directory.

This RFC proposes a similar assimilation of Home Manager into Nixpkgs.

##  Benefits

In principle, Nix already leverages Nixpkgs for basic users. However, the raw
usage of Nixpkgs is not too ergonomic, especially when compared to the more
structured model of NixOS.

HM provides a similar centralized, modular, declarative package management
experience to basic users, without the need of granting them superuser
privileges.

Given that NixOS - a system that leverages Nixpkgs for superusers - is already
bundled inside Nixpkgs tree, a fortiori HM - a system that leverages Nixpkgs for
basic users - should be included as the default, Nixpkgs-blessed system for
basic users.

Further, this assimilation will benefit two interesting sets of people:

01. Users of Nixpkgs and/or NixOS that are reluctant in using HM, since it is
    neither official nor well-integrated into Nixpkgs workflow.

01. Users of NixOS that already use HM in tandem, as a convenient way of
    separating basic users' business from system administration tasks.

Another great advantage of assimilating HM to Nixpkgs is a tighter integration
between both projects:

01. Merging HM into Nixpkgs eliminates a barrier between both projects,
    conveying more flexibility in code sharing, deduplication and refactoring in
    general.

01. Refactors, reformulations, deprecations and removals of packages and other
    related functionalities are commonplace around Nixpkgs. Since HM is
    dependent on Nixpkgs, it needs to monitor and synchronize such activities.

    The eventual assimilation proposed here drops those issues dramatically.

01. The merge of communities brings a new point of view about package maintenace
    in general.

    NixOS is the main point of structured conglomeration of packages; because of
    this, Nixpkgs is arguably more inclined to favor a superuser view of system
    administration.

    Bringing HM to Nixpkgs provides a new point of view, more akin to the basic
    user.

01. Making HM an official, blessed tool conveys more credibility to both
    Nixpkgs and HM.

# Detailed design
[design]: #detailed-design

There are many possible approaches for this assimilation. Here I will propose a sketch:


01. Prepare HM to migration

    Currently Nixpkgs monorepo requires certain rules to accept code.

01. Prepare Nixpkgs to migration too

    There is some expectation of preparing Nixpkgs to deal with the big input of
    new code. A merge train will be useful here and in subsequent steps.

01. Merge HM repository so that its files are kept in `home-manager` directory

01. Polish the rough edges

01. Profit!

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

Ideally, after the assimilation, a basic user will experience few to no changes
in their workflow. The channels of distribution of both Nixpkgs and HM will be
merged, promoting a cleanup on setups that otherwise would need synchronization.

On the other hand, from this assimilation forward the typical package maintainer
will interact with potentially two sets of too similar module systems. This
brings a momentum to deduplicate code and build abstractions, however this is
not in the scope of this RFC.

# Drawbacks
[drawbacks]: #drawbacks

The main drawback of this assimilation stem from the resulting complexity.

## Standardization

There are some discrepancies between the practices of both communities. How they
should be accomodated?

## Synchronize the communities

There are almost 660 contributors in HM to this date. How they should be
allocated?

Ideally they should keep the same roles.

## CI

Currently HM uses its own setup for continuous integration. Ideally the Nixpkgs
setup should be updated to include HM's specific needs.

# Alternatives
[alternatives]: #alternatives

The alternatives are

- The trivial "do nothing"

  It just exacerbates the status quo, bringing nothing in the long term.

- Bless another home management tool

  HM is battle-tested and well renowned. There is no other tool remotely
  comparable to it.

- Build a home management tool from scratch

  This alternative dismisses the know-how accumulated by HM. An acceptable
  middle ground would be to create some "library extension" to accomodate future
  HM-like modules and use that extension to migrate HM modules.

# Prior art
[prior-art]: #prior-art

As an example of prior art, there is our Scheme-based cousin, Guix Software
Distribution. Since at least 2022 AD they bring a similar tool, conveniently
called Guix Home.

The nicest thing about this tool is that it is tightly integrated with Guix, to
the point of `home` being a mere subcommand of `guix`.

# Unresolved questions
[unresolved]: #unresolved-questions

How the future package inclusions should be carried out?

# Future work
[future]: #future-work

- Update an extend the CI
- Set expectations on portability among present and future platforms Nixpkgs
  supports
  - Especially outside NixOS
  - Especially outside Linux
- Factor HM and NixOS's shared code into some service abstraction structure

# References
[references]: #references

- [Keeping One's Home
  Tidy](https://guix.gnu.org/en/blog/2022/keeping-ones-home-tidy/), by Ludovic
  Courtès
- [Guix Home
  Configuration](https://guix.gnu.org/manual/devel/en/html_node/Home-Configuration.html)
