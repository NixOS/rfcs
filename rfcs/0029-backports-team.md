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
updates were simply not cherry-picked. While there are [general
guidelines][grahamc_backport] written up, no canonical process is documented.

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

Backports process
-----------------

Expected to be backported to current-stable are the following:
<sup>[1][grahamc_backport]</sup>

 * Patch-level and minor-level updates.
 * Security patches from downstream projects (other distributions) when
   no patch-level or minor-level update is made available.
 * Any update when the current stable version is completely broken.
 * Extremely security-sensitive software, in particular web browsers,
   mail user-agents and the kernel, can and should be updated to the version
   expected by upstream to be secure.

### Examples

An example of broken software needing a major update to be backported is
Spotify, which regularly breaks with old versions.

Don't backport if the patch is just for Darwin, they use nixpkgs-unstable not a
stable branch.

> `FIXME` Is this true?? I see nixpkgs-18.03-darwin in the channels list.

Backports team
--------------

The idea behind the team is more to rally people behind a common mindset and
banner than forcibly organizing and assigning roles to people. There is also
the advantage of creating an explicit communication channel reducing the risks
of overlaps in the backport efforts. Since the members of the team are working
towards the same goal, better coordination with tooling and documentation can
hopefully happen.

Being on the backports team is not expected to be too much of an investment,
as long as there are multiple members on the team. Members will not be expected
to do anything particular, only to sometimes help out in the duties. At first,
no rotated duties are expected to be given.

While reading the following sections, keep in mind that there is expectation
that there will be tooling developer along the way to automate and expedite
part of the process of backporting.

### Duties

The duties of the backport team members are as follow

 * Identify pull requests and commits subject to backport.
 * Prepare contained change sets with backports.

Identifying pull requests subject to backport is expected to be done through
figuring out, from the set of recently closed pull requests, which ones are
to be backported. Nothing more, preparing the change sets is a separate task.

Identifying the commits subject to backport is a similar task, but may not be
done depending on the difficulty. It is expected that changes and fixes needing
to be backported will be applied through PRs.

Preparing the change sets will generally consist of taking the commit(s) and
using `git cherry-pick -x` on the current-stable branch. Then, creating a PR
with a generally standardized layout.

As for "*who merges?*", this is something that may be handed by any NixOS
member having the commit bit, in the backports team or not. It is not expected
to be in the duties of the backports team until there is a critical mass of
members, especially members having commit access. It is hoped that the
standardized work from the backports team will make merging their pull requests
an easy task.


Backports tooling
-----------------

While having a team working together is great, collaborating still is an issue
without both conventions and tooling. Initially the author's (@samueldr) duty,
figuring out both a workflow and tools to help the team collaborate efficiently
is required. 

The processes and tooling is expected to:

 * Distribute the effort as much as possible while reducing overlap.
 * Minimize the size of individual efforts.
 * Reduce the amount of busywork.
 * Standardize to expedite shipping and reviewing backports.

### Collaboration

> (This is a high-level non-bikesheddable overview of the functionalities)

Through a networked-service, with high probability of it being a web-based
service, team members will be able to file merged PRs as either on-topic of
off-topic for the backports team. The system is expected to fetch the newly
merged PRs from github and provide them for the "figuring out" task previously
described. The PRs would be presented from oldest to newest.

Once filed, the collaboration system will allow members to assign themselves
to do the backports. It is expected that team members will go from oldest to
newest, but not enforced. Working on implementing a backport would first have
the team member "take" the task, allowing parallel work to not conflict.

A task will be worked on by making use of a command line tooling, allowing
most tediousness to be automated away.

### Making the backport

As previously said, the team member will use a command line tooling.

The team member will be presented with the commands in the interface, allowing
less thoughts to be given to the task.

When using the tooling, pretty much all tasks will be as automated as possible.

 * Fetching
 * (Checking out current-stable)
 * Creating the branch
 * Cherry-picking
     * If it fails to auto-apply, this is where work starts; applying.
     * After applying, resuming automation will be possible.
 * Build of affected attributes (*may be limited somewhat*)

One part that is **not** automated is testing. It is expected that the team
member will at least try to launch affected software `result/bin/*`. Only a
general glance would be required.

For patches affecting libraries, affected attributes will be listed, allowing
some general testing to be done.

Once some general testing has been done and conclusive, the team member will
use the tooling to automate pushing and creating the PR.

 * Push to team member's repository.
 * Create the PR targeting current-stable.
     * The text will be auto-filled with data according to the build.
     * Some machine-usable data may be provided for the tooling.
 * Automatically mark the task as done and add with the newly opened PR number to it.

The standardized PRs created by the tooling are expected to be easier to be
approve by members of NixOS. The reduced number of manual steps is expected
to make it easy for non-maintainers, even only enthusiasts to take part in
the effort.


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
 * Keeping patch-releases up-to-date when a major is out at upstream.
 * How to work with non-PR commits with fixes or updates needing backport.
 * Conflict with non-team members' own backports.


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
[grahamc_backport]: https://gist.github.com/grahamc/c60578c6e6928043d29a427361634df6#what-to-backport
