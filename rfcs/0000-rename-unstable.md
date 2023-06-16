---
feature: rename-unstable
start-date: 2023-06-16
author: @K900
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Users often interpret Nixpkgs "unstable" as "contains bugs", not the intended meaning of "can have breaking changes".
To avoid this confusion, we should rename the "unstable" branch to something that doesn't have those connotations.

# Motivation
[motivation]: #motivation

When introducing people to Nix and NixOS, the very first question that often arises is "why are we using unstable?".
This is because the word "unstable" has two somewhat overloaded meanings - end users usually think about _application stability_
(i.e., roughly, the "WTFs per hour"), whereas developers think about _API stability_. This results in a lot of confusion,
especially for new users who are often told to "don't worry, just run unstable", which is a pretty scary prospect given the
initial assumption of what "unstable" really refers to.

# Detailed design
[design]: #detailed-design

## Aside: on the naming of cats

This RFC intentionally does _not_ propose a new name to replace "unstable". The intent of this RFC is to not focus on the exact naming,
but establish consensus over the _idea_ of renaming, and, if consensus is achieved, identify the technical hurdles.

As such, following [in the footsteps of our ancestors](https://doc.rust-lang.org/std/ops/struct.Yeet.html), the placeholder new name
for the branch shall henceforth be `yeet`.

## Action plan

1. Set up new branches in the Nixpkgs repository and new channel endpoints at `channels.nixos.org`, containing the same code as `nixpkgs-unstable`
and `nixos-unstable`, but named `nixpkgs-yeet` and `nixos-yeet`.

2. Implement an early warning in nixpkgs sources, which detects when an `unstable` channel is used and recommends switching to `yeet`.

3. Maintain both channels in parallel for a long enough deprecation period (likely at least two releases, i.e. one year).

4. Eventually deprecate the `unstable` channels and stop updating them.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

## Nix changes

The Nix installer currently adds `nixpkgs-unstable` as the default `nixpkgs` channel. It should be switched to use `nixpkgs-yeet` instead.

## Infrastructure changes

We do not want to create new Hydra jobsets for the `yeet` branches, so no work is duplicated, and history is preserved.
However, we still want the channel to know its branch name, so the warning can be provided to the right subset of users.

To implement that, we will a new input to the tarball job identifying the channel name being built.
([tarball job source](https://github.com/NixOS/nixpkgs/blob/60ac106c34e00fdd2e0c81754675b206e54f1a54/nixos/lib/make-channel.nix#LL19C1-L19C1)).
The channel name will then be recorded in a file that can be checked at eval time.

We will then add a new output to the jobsets named `tarball-yeet`, which builds the tarball with the channel name set to `yeet`, and configure
[nixos-channel-scripts](https://github.com/NixOS/nixos-channel-scripts/) to mirror it to new `nixos-yeet` and `nixpkgs-yeet` paths.

Additionally, the Github Actions scripts will need to be updated to disallow PRs against the `nixos-yeet` and `nixpkgs-yeet` branches.

## Nixpkgs changes

The top-level nixpkgs expression should read the newly added channel name file and log a warning if the channel name is `unstable`.

For flakes we can rely on Nix-provided `self.sourceInfo` to produce a similar warning with little to no added complexity.

## Documentation changes

All documentation referring to `unstable` should be updated to refer to `yeet`, preferably with a link to a common paragraph explaining the change
and linking to this RFC. This is generally not an issue for in-tree nixpkgs documentation, but we will likely want to also update major external
documentation sources (e.g. the wiki and nix.dev), or at least notify their maintainers.

## Deprecation tombstone

After the deprecation period expires, the `nixpkgs-unstable` and `nixos-unstable` branches should have a commit added that notifies users of the EOL,
redirects them to an equivalent `yeet` branch and aborts evaluation. This will ensure that users that silently rely on updating their `unstable` channels
and ignore warnings will not be left behind.

# Drawbacks
[drawbacks]: #drawbacks

- Induces a large amount of ecosystem churn for potentially questionable gains.
- Creates some additional load on Hydra (building two tarballs instead of one) and nixos-channel-scripts (mirroring two channels instead of one).
- Potentially permanently invalidates older documentation.

# Alternatives
[alternatives]: #alternatives

- Do nothing.
- Communicate the intended meaning of "unstable" through documentation.

# Prior art
[prior-art]: #prior-art

Most other distributions with rolling release branches chose to not name them "unstable".

Compare:

- OpenSUSE - Tumbleweed
- Fedora - Rawhide
- CentOS - Stream
- Slackware - Current
- Alpine - Edge
- Debian - Testing
- OpenBSD - Snapshot

It's especially worth noting that none of those names carry direct negative connotations.

# Unresolved questions
[unresolved]: #unresolved-questions

There will likely be more things, both inside the Nixpkgs/NixOS projects and in the community, that will be affected by this.
The grace period should allow things to continue working, but the total eventual amount of churn is yet unknown. Part of the
purpose of this RFC is finding things that will require changing in advance.

# Future work
[future]: #future-work

A name decision will need to be made, likely as a separate RFC with involvement from the marketing team.