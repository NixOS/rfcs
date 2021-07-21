---
feature: release-manager-nixos
start-date: 2017-07-18
author: Robin Gloster (@globin)
co-authors: Franz Pletz (@fpletz)
related-issues: --
category: process
---

# Summary
[summary]: #summary

NixOS currently has no process for electing release managers (RMs). We propose to
switch to a model with two RMs, where each RM SHOULD
serve for a consecutive term of two releases. A new RM is appointed
by the previous team for each new release.

# Motivation
[motivation]: #motivation

Currently release managing in NixOS has mostly been done by individuals who
volunteered and were then chosen by the last release manager. Over the last
few releases a process has been established and
[documented](https://nixos.org/nixos/manual/index.html#release-process).
As this makes it easier to cut a release this role should be passed on
regularly and not be held by a single individual over a longer time.

# Detailed design
[design]: #detailed-design

For each release there are two RMs. After each release the RM having
managed two releases steps down and the RM team of the last release
appoint a new RM.

This makes sure a RM team always consists of one RM who already has
managed one release and one RM being introduced to their role, making
it easier to pass on knowledge and experience.

A release manager's role is mostly facilitating:
 * manage the release process
 * start discussions about features and changes for a given release
 * create a roadmap
 * release in cooperation with Eelco Dolstra
 * decide which bug fixes, features etc. get backported after a release

The process outlined in this RFC has informally started by @globin taking
over the role from @domenkozar for NixOS 17.03 and having the latter as a
backup and contact at all times for questions and support. We propose to
continue this by appointing @fpletz for the second RM, who has been working
with @globin a lot to keep the additional overhead of communication to a
minimum at the beginning.

# Drawbacks
[drawbacks]: #drawbacks

There is more communicational overhead but by having a second RM
two individuals are checking the issues from a RM's point of view.
Additionally it ensures that there is always one
RM with the experience of having released NixOS once before.

# Alternatives
[alternatives]: #alternatives

We can consider continuing the process as is and not specifying it formally,
this will probably continue to work but does not ensure the role being passed
on regularly.

There are other possibilities how a RM can be elected, by vote (who by?), by
@edolstra, RFCs, etc. This would mean even more overhead and the need of
defining eligibility to vote or centring more decisions around @edolstra.

# Unresolved questions
[unresolved]: #unresolved-questions

Nothing we can currently think of.

# Future work
[future]: #future-work

 * Specifying the process for releasing NixOS itself.
