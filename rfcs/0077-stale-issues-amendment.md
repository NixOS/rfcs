---
feature: stale-issues-amendment
start-date: 2020-10-13
author: blaggacao
co-authors: (to be found)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: https://github.com/NixOS/nixpkgs/pull/100460, https://github.com/NixOS/nixpkgs/pull/100462
---

# Summary
[summary]: #summary

RFC 51 implemented the stale bot with the following motivation:

> We have a large number of open issues that have accumulated over the years. Not all of them are still valid and need our attention.
> 
> By marking stale issues, we can more easily filter issues for ones that have at least one person interested in them.

Under this motivation, the inactivity period was chosen to be 180 days.

This RFC proposes an alternative interpretation of "stale":

_A stale issue (or PR) is an issue on which the discussion has went stale._

_Explicitly, it has no other semantic than this. It is a neutral 
aggregated indicator of facts. It reflects the fact that 
individuals did choose not to interact on a particular issue or PR
for an extended period of time._

_180 days is too long of such extended period of time. People do relate
"stale" with some shorter time frame. Therefore, a PR goes stale after
a 90 days period (vs previously 180 days) and an issue goes stale after
a 60 days period (vs previously 180 days)._

# Motivation
[motivation]: #motivation

Under the renewed definition of _stale_, people are betrayed. 

They are not told the truth, though the facts are long evident.

A majority of issues or PRs with no interaction for quite short period
of times already (maybe 3-6 weeks) has a lesser change of "success".

People with vested interest should see the _stale_ label and be prompted
to think: "Oh, I need this, too. Damn, it's stale. Let's have a look
and do something to help out."

An issue that hasn't been interacted with for 60 days or a PR for 90 days
and in the vast majority of cases deserves this hint out of fariness.

Honesty and transparency are by far more effective than any perceived
political correctness (judging by the discussions on RFC 51).

# Detailed design
[design]: #detailed-design

- Mark PRs as stale after 90 days
- Mark issues as stale after 60 days
- Keep the policy of never closing either PRs or Issues.
- Add `2.status: never-stale`, which maintainers can use on long running or umbrella issues.

_Note: non-maintainers are sufficiently unlikely to open truely long-runnig or umbrella 
issues without a maintainer stepping up to prevent them from getting marked as stale._

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

It should be noted under this section, that it only takes a comment
to un-stale an issue or PR.

It should be made clear, that stale does **not** mean either of
the following:

- bad
- unimportant
- invalid
- not useful

Or any similar deminishing interpretations. Stale just means an aggregate
indcator of individual's choices to not interact.

# Drawbacks
[drawbacks]: #drawbacks

With a renewed definition of the word _stale_ and removing an overly emotional
meaning by virtue of this very PR, there is no reason to adversely interpret
a bot spelling out the facts.

Regular subscriber might get notifications they do not find immediatly
actionable for them personally. However, the bot is inteded to help authors,
not (silent) subscribers. It is assumed that subscribers wisely choose
and actively manage how they spread their limmited attention. At any rate,
their interests should never outperform the interest of the auther (="owner").

At a closer look, increased notification is also a valuable _gain_ in information
for those subscribers. Imagine: A topic went stale, then there where people moving
things forward. Then it went stale _again_. If I'm subscribed to a topic of 
_interest_, a second stale promts me to consider taking action.

Some data: As of now, there are roughly 1750 open issues marked as stale, and
roughly 450 stale issues were marked as closed. Even older ones. By definition
of how the stale bot operates, this means the stale bot has failed in adequately
prompting action. The data suggests, it is _not_ actionable.

There are a variety of possible reasons for this, but if we assume that the bot
should have prompted the _author_ into "furthering the cause" (whatever that
might be in a particular context), judging by the 1750 unattended interventions,
it blatantly failed. Since any such furthering would have left traces the stalebot
would have picked up in any way.

One reason for this might be that by the time the stale bot intervenes, the
interest and memory has vanished to a point where even the friendly suggestions
of the stalebot are completely ignored. This strongly supports reducing the
inactivity period to _humanly bearable levels_ of an avearge person with an
average memory.

Another reason might be that the stalebot is not actionable, since too convoluted
and wordy. So nobody reads it. Hence: https://github.com/NixOS/nixpkgs/pull/100462

# Alternatives
[alternatives]: #alternatives

No alternatives have been considered.

# Unresolved questions
[unresolved]: #unresolved-questions

At the time of writing, no unresolved questions apear of relevance.

# Future work
[future]: #future-work

No future work is required.
