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
Since PR are more involved, memories can be expected to be fresh a little longer. Hence: 90 days.

Cases, where these dynamics don't regularily aply (such as umbrell issues, etc.) 
should be provided with an escape hatch that maintainers can activate.

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

Please read carefully, this RFC does _not_ increase the **rate** of
notifications by itslef. It just anticpiates the time to first interaction
to a more practical level.

If this first interaction has triggered further action, then this further
action might trigger a notification. Such notification will alsways be
triggered by a human.

Consequetly any added notification over the rpe RFC state, is triggered by
human intervention.

That is, unless the issue or PR goes stale _again_. But going _stale_, which
means **impaired in vigor or effectiveness**, _again_ is by itself a valuable
information that is beeing broadcasted implicitly by their notification.

# Supporting Data
[data]: #supporting-data

As of now, there are roughly 1750 open issues marked as stale, and
roughly 450 stale issues were marked as closeed.

## Interpretation

We can interpret this ratio of only 20% as a stalebot's failure to 
effectively prompt action: The stalebot itself is stale, that is
**impaired in vigor or effectiveness**. (your threshold of judgemnt may differ).

To the author of this RFC, the most plausible reason is that by the time
the stalbot interacts, levels of attentions and interest has vanished so
might have memories or simpli life got into the way.

At any rate, it is reasonable to assume, that this declining levels of attention
iterest and memories put the very author into a position of beeing in a state
that is **imparied in vigor and effectiveness**. So, you might have guessed it:
the auther went stale. Dooms day! :wink:

A reduction in the time to first interaction is likely a probate mean to prevent
authors from going stale.

# Alternatives
[alternatives]: #alternatives

No alternatives have been considered.

# Unresolved questions
[unresolved]: #unresolved-questions

At the time of writing, no unresolved questions apear of relevance.

# Future work
[future]: #future-work

No future work is required.
