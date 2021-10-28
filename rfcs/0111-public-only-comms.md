---
feature: public, focused communication
start-date: 2021/10/27
author: nrdxp
shepherd-team: TBD
shepherd-leader: TBD
---

# Summary
[summary]: #summary

The NixOS community, up to this point, has _de facto_ operated in an open and
transparent fasion. Whether it be in discussions on Matrix, Discourse, GitHub,
in person at NixCon, or financial decision making via Open Collective,
the community has demonstrated by its actions that it values openness and
auditability in communication and decision making. We should therefore codify
this ideal as a guaranteed community standard.

# Motivation
[motivation]: #motivation

It has recently come to the author's attention that a private, invite only,
chatroom has been created on the official NixOS Matrix Space. This seems to be
a hard break from the above mentioned ideal of openness and transparency and
has, therefore, triggered this RFC. There is no argument against the existence
of any such room in principle, only that it not be officially sanctioned by the
project unless any such channel be willing to act in an open and auditable
fashion.

Ignoring the personal implications for the moment, which will be addressed in
the following section, this is seen as necesary for any reasonably large
institution which wishes to be seen, by an obseving public, to be operating in
a transparent and _provably_ trustworthy fashion. This is especially true for a
large open source project such as NixOS. Any promises of transparency in action
are dead on arrival if official communications are to be seen, in any manner,
to be deliberately sealed.

Importantly, this is not a value judgement on particular individuals in the
community, nor does it require that each individual share the value of openness
as primary in their personal affairs. Only that they formally recognize this as
an official value of the NixOS Organization itself.

Equally importantly, this is more than just a simple statement of value. It is
a request to align our _actions_ with our _values_ to avoid further ambiguity
and conflict.

# Detailed design
[design]: #detailed-design

In an effort to promote transparency, we make it official policy that anything
hosted under `nixos.org` be made and kept public. Should this RFC be accepted,
the transition should be organized and enacted within a reasonable time frame,
no later than two months from the date of acceptance.

In addition, any currently existing topics which are not strictly related to
Nix in either technical or operational terms, should also be moved within the
same time frame. Most likely to an unofficial or semi-official Nix Community
Matrix Space. This is so that the scope of official communications can be kept
to a reasonable baseline for moderators and operators.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

The very intention of this RFC, in letter, and in spirit is to improve the
transparent communication between disparate members of the community, which has
already come to a head elsewhere in both public and private, to the point that
certain members of the community have expressed a need to self segregate! This
is clearly _not_ sustainable long term, and NixOS _should_ take a hard and
clear stance suggesting that while we, in no way, codemn the act of private
communications and coordinations, our _official_ stance is one of collaboration
and openness.

This sends the signal that, if any serious contribution or opinion is to be
laid bear, it should be done publicly, even if the details or the organization
of which is to occur privately. Whether it seems apparent up front or not to
any particular individual, the continued and officially endorsed segration of
large subsections of the NixOS community is detrimental to its cohesion and
continuity. This will only exacerbate as the divergence grows.

Additionally, the importance and primacy of openness was weighed carefully by
the author against the potential for further conflict. It was deemed that
further conflict was, in the current state of affairs, inevitable and therefore
only incidental should it arise during the course of this RFC. Unless and until
decisions are made about the heirarcy of values in the NixOS Organization, such
conflict will be inevitable.

And to be sure, a certain amount of conflict is _always_ present, and sometimes
even healthy. The target of focus here, then, is the type by which core values
are pitted against one another. This tends to lead to very personalized and
unproductive conversations, which has already, demonstrably led to a large
group of individuals feeling both unwelcome, and worse, unsafe in the official
communication streams.

So it was hoped that if conflict did arise, it could be resolved respectfully
and honestly in the RFC discussion thread and follow up meetings. It is for
precisely this reason that your author did not hide his initial motivation for
drafting, despite the obvious and somewhat _easy_ conception that it was merely
an attack on a particular group of individuals. The good faith that has been
extended is therefore expected in return.

The design has been updated accordingly. Admittedly, and intentionally, this is
not an attempt to address _all_ of these problems in one fell swoop, but
instead to set a solid foundation for future policy RFCs.

As a brief addendum, and specifically because some of the suggestions that have
been made about ulterior motives for this RFC, let it be known that the author
of this RFC has offered to take, and has now taken the very same actions for
his own project's room that he is asking others to take for the sake of the
community, i.e. removed it from `nixos.org`.

# Drawbacks
[drawbacks]: #drawbacks

Given that opening a private channel on another host is trivial, there do not
seem to be any major drawbacks technically.

# Alternatives
[alternatives]: #alternatives

* Allow private channels under certain well defined circumstances
* Allow private channels with no restrictions

# Unresolved questions
[unresolved]: #unresolved-questions

* Do we endorse privacy on our hosted channels at higher levels than transparency?
* What are the implications for the community if private channels _are_ allowed?

# Future work
[future]: #future-work

Ensure any newly created communication channels are made public from their
inception, and ensure they are on topic for some specific aspect of Nix
development or adminstration.

As further work, future policy driven RFCs should be drafted to decide things
such as secondary values held in the community. Official process for moderation,
official process for moderating the _moderator_, among other things.
