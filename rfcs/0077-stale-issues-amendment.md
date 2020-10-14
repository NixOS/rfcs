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

_"Stale" in this context means (https://www.merriam-webster.com/dictionary/stale):_

> impaired in vigor or effectiveness

_Explicitly, it has no other semantic than this. It is a neutral 
aggregated indicator of facts. It reflects the fact that 
individuals did choose not to interact on a particular issue or PR
for an extended period of time._

_180 days is too long of such extended period of time. In a majority
of cases, an issue or PR enter into a state where they are
**impaired in vigor or effectiveness** far earlier._

_While it is difficult to judge on the exact date when they enter this
state seems safe to assume that for PR 90 days and issues 60 days does
assess the majority of cases correctly while keeping false positives 
at bearably low levels, which everyone can live with._

# Motivation
[motivation]: #motivation

Under the correct (as per Merriam Webster) definition of _stale_, people are betrayed. 

They are not told the truth, though the facts are long evident.

A majority of issues or PRs with no interaction for quite short period
of times already (maybe 3-6 weeks) has a lesser change of "success".

However we also want to avoid _false positives_, that is issues or PRs
marked as **impareid in vigor or effectivenss**, even though they are not.

This is a question of threshold and summary judgment. 60 days (2 months) for issues 
and 90 (3 months) for PRs is probably a good enough improvmeent over the current 180 days.

With shorter periods, people are also mor likely to still remember the relevant details, 
so it gets easier for them to react in actionable ways to the bot's friendly reminder.

Cases, where these dynamics, don't regularily aply (such as umbrell issues, etc.), 
should be provided with an escape hatchi which maintainers can activate.

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
