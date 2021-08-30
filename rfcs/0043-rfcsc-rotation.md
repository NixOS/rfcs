---
identifier: rfcsc-rotation
start-date: 2019-04-24
author: Robin Gloster <mail@glob.in>, Simon Lackerbauer <mail@ciil.io>
related-issues: 36
category: process
---

# Summary
[summary]: #summary

Each RFC Steering Committee (RFCSC) unanimously elects the succeeding one at
their first meeting in December from an open list of nominees.

# Motivation
[motivation]: #motivation

The RFC Steering Committee has been established by [RFC
36](https://github.com/NixOS/rfcs/blob/master/rfcs/0036-rfc-process-team-amendment.md).
Future work for that RFC included a definition of how members to the Committee
are to be chosen or removed. This RFC provides mechanisms for beginning and
ending Steering Committee membership. The purpose of this is to ensure that the
committee:

 * continues to consist of well-informed and motivated members;
 * continues to represent the evolving community;
 * remains active and keeps the RFC process running.

# Detailed design
[design]: #detailed-design

The RFC Steering Committee shall always have five members. If membership drops
below five members (for example by resignation of a member as detailed below),
a new member shall be elected without delay after a nomination period of at
least two weeks (see below for nomination and selection process). If the number
of members of the RFCSC drops below 4 people, it cannot proceed with shepherd
team selections until new members have been selected.

## Ending membership
Membership in the Steering Committee can end by any of the following four
mechanisms:

1. At the end of an election period.
2. Resignation
3. Unanimous vote by all other members after having missed two or more regular
   meetings without giving an appropriate excuse.
4. Unanimous vote by all other members due to conduct unbecoming of a member.

A member can resign from the RFC Steering Committee at any time and for any
reason. A member planning to resign should inform the rest of the RFC
Steering Committee of their intention at their earliest convenience.

## Becoming a member
The members chosen through the original implementation as
specified in RFC 36 are regular members as specified in this RFC. They will
stay on as members until replaced by new members as outlined below.

If a seat has to be filled earlier than at the yearly vote, the new member will
only serve for the rest of the term.

Each year at the first meeting of the RFCSC in December (starting 2019,
approximately a year after establishment in RFC 36) they unanimously decide on
the succeeding committee members. If unanimous agreement cannot be reached, the
RFCSC votes on each nominee, ranking them by votes in favour of the candidate
and further holds run-off votes if there is a tie for the fifth & sixth spot.
Nominations are open to anyone, and one can either nominate themself or any
other person who accepts the nomination. Members of the previous RFCSC
explicitly can stand again, but should reflect on their free time and
commitment to their role. The nomination period starts at the beginning of
November, a minimum of four weeks before election, and is announced on all
relevant communication channels (as of April 2019, discourse.nixos.org,
IRC #nixos and #nixos-dev, and NixOS Weekly). The new RFCSC takes over in the
first week of January.

Additionally to RFC 36 a new restriction formally comes into effect. In order
to avoid conflict of interest there is an upper cap of appointing 2 members
working for a single employer.

# Drawbacks
[drawbacks]: #drawbacks

The RFCSC basically elects their own successors, but this minimises the
complexity of having to hold elections, including defining who is eligible to
vote and how to hold them.

# Alternatives
[alternatives]: #alternatives

 * Do nothing: then the current members of the RFC Steering Committee as
   defined in RFC 36 could stay on the Committee indefinitely or at least until
   that part of RFC 36 is overridden by a newly accepted RFC.
 * Rigorously defining a voting procedure (though possible, but probably too
   complex)

# Unresolved questions
[unresolved]: #unresolved-questions

As of now, none.

# Future work
[future]: #future-work

As this process is to be implemented over a fairly long time frame (a year for
each iteration), this framework might have to be revised at a later date,
incorporating any experience made over these years.
