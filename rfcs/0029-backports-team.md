---
feature: backports_team
start-date: 2018-07-28
author: samueldr
co-authors: ...
related-issues: ...
---

Summary
=======
[summary]: #summary

This intends to formalize the backports process and formalize the formation of
a team managing backports.


Motivation
==========
[motivation]: #motivation

The way it is currently handled makes it so too often fixes for lesser-used
software are not backported to the *current-stable* revision of NixOS.
Furthermore, even some more-often used software sometimes lag behind since the
updates were simply not cherry-picked.

Backports is not only a security feature, but also a user-experience feature.
Upstream software is getting updated; it would be best if current-stable does
not get the reputation of being stale.

By formalizing the process, it is expected to create a good hygiene that will
keep NixOS current-stable fresher, instead of presenting stale software to the
end-users.

Finally, by appointing a team, even if fluid, it is expected that the
responsibilities given to the users will _nudge them_ toward doing the work
required of maintaining the backports. The work of integrating backports should
be the release manager's, as per [RFC 0015][rfc0015]. Through [dubious
stats][stats_release], it seems that for the 18.03 release their work has
been minimal, and instead filled-in by ad-hoc work by other members.


Detailed design
===============
[design]: #detailed-design

> *Currently being worked on from misc. notes.*

<!--

TODO!

Main points:

## Team

 * Building a team with multiple people
 * Prevent burnouts by distributing across people

## Process / Tooling

 * Make the effort distributed
 * Make the process bite-sized
 * Brain activity not required for most parts
 * Standardize to expedite backports

-->


Drawbacks
=========
[drawbacks]: #drawbacks

Formalizing a process always reeks of red tape. This may turn off some
volunteers away from doing backports.

It may well happen that once the team formed, nothing changes and the backports
are not maintained any more than they are.

Writing and maintaining tooling may slow down or halt progress toward actually
maintaining backports.


Alternatives
============
[alternatives]: #alternatives

Continuing as-it-is, with ad-hoc updates, sometimes missed. This has proved not
to be the most successful way to manage backports.

It could also be possible to only implement parts of the RFC. Either the team
or the tooling. Both are of equal value and generally independent. They would,
though, work best if working together.


Unresolved questions
====================
[unresolved]: #unresolved-questions

 * Actual team organization (if any).
 * Specifying processes for all software updates and fixes.


Future work
===========
[future]: #future-work

 * Specifying collaboration with automated updates (@r-ryantm)


Definitions
===========
[definitions]: #definitions

### Backport

Taking fixes and features from a newer version and applying them to an older
maintained version to provide the equivalent fix or feature.<sup>
[1][1]
[2][2]
[3][3]
</sup>

### Current-stable

A version-agnostic way to specify the current stable branch of NixOS.


[1]: https://en.wikipedia.org/wiki/Backporting
[2]: https://en.wiktionary.org/wiki/backport
[3]: https://access.redhat.com/security/updates/backporting
[rfc0015]: https://github.com/NixOS/rfcs/blob/master/rfcs/0015-release-manager.md
[stats_release]: https://gist.github.com/samueldr/7ec402f71d3bb2ac2e059f33d29d95bb
