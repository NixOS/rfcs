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

Since reconfiguring would trigger an immediate burst in notifications, the shift
needs to be done gradually over a period of time, for example reduce by 5 days every
two weeks.

This graduation period also allows us to collect data on any manifest adverse effects.

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
triggered by a human. Consequetly any added notification over the the RFC
state, is triggered by human intervention.

That is, unless the issue or PR goes stale _again_. But going stale _again_,
which means **impaired in vigor or effectiveness _again_**, is by itself a
valuable information that is beeing broadcasted by the notification.

# Supporting Data
[data]: #supporting-data

As of now, the stale-bot has commented on roughly 2.2k open issues and
roughly 500 closed issues (`is:issue commenter:app/stale`).

Thereof, 1.7k are still `2.status: stale` and 400 are `2.status: stale`
and closed.

This gives us the following data:
- 1.7k interactions did not trigger any action (effectively stale)
- 400 interactions triggered an immediate close (stale label not removed)
- 100 interactions are unkown, but the issue is closed now
- 500 interactions did trigger any action so that the issue is not
  `2. status: stale` ay more

Since very old issues are likely to skew the data and the analysis,
we limit the picture to issues created after 01.01.2019. Then, we get:

The stalebot has commented on 1.1k open and 200 closed issues
(`is:issue commenter:app/stale created:>2019-01-01`).

Thereof 750 are open and labelled stale and 150 are closed and labelled stale.
(`is:issue commenter:app/stale created:>2019-01-01 label:"2.status: stale"`)

That means out of 1.3k interactions on relatively recent issues, 750 did 
not trigger _any_ reaction. The sucess rate of stale-bot triggering action
is thereby at 42% (37% all times).

There is a portion of the 750 (1.7k) futile interactions, where spectators
might have silently agreed the stale-bots assessment. So the following
interpretation is not 100% accurate.

## Interpretation

We can interpret this ratio of 42% (37%) as a stalebot's moderate success.
But it also can be interpreted as a relative failure, especially given
the many instructions and tips the stale-bot puts at the hands
of participants in its comments. In 58% (63%) of cases, the stalebot itself 
is stale, that is **impaired in vigor or effectiveness**.

To the author of this RFC, one aspect crutial aspect in open source low
commitment environments is that by the time the stalebot interacts, levels
of attention and interest have vanished. So might have memories or simply
the life got in the way.

At any rate, it is reasonable to assume, that this declining levels of attention,
iterest and memories put the very author into a position of beeing 
**imparied in vigor and effectiveness**. So, you might have guessed it:
_the author went stale. Damn it!_ :wink:

Author being stale, can be assumed for around 58% (63%) of total stalebot
interactions or roughly 38% of total issues (1.7k out of 4.4k).

A reduction in the time to first interaction is likely a probate mean to
prevent authors from going stale.

If we consider for a moment that 38% percent of issues have no care-taker
and no real chance of getting promotion, this suggests, we need to increase
our efforts to make our database more actionable and accurate. (closed does
not mean deleted! _stale_ does not mean invalid!).

# Drawbacks
[drawbacks]: #drawbacks

A non-trivial share of issues get stale-bot request «what's the status», 
then update from someone «checked, still happens».

If the issue goes stale again after another 60 / 90 days, then the amount
of unuseful traffic increases.

If we can &mdash; at the seame time &mdash; increase the share of useful
output en reasonable terms, we probably should bias our workflows towards
actionability, even if this is not 100% pareto-efficient.

---

This RFC proposes to adopt a common definition of the word stale and thereby
forgoes a hard earned consensus about an alternative definition of RFC 51.

This RFC's stance is that consenus was reached based on teleological
reasoning rather than experiment (or even data). This RFC promotes experiment
through the graduation period and would explicitly leave open the possibilty
to wind back upon significant and otherwise non-remediable data of adverse
efects. It also takes a stance to represent the (admittedly construed) needs
and preference of a significant portion of casual contributors, that I
assume to not have had their voice in RFC 51's discussion.

The assumption is that casual (inexperienced) contributors would benefit
even from the interaction with a bot. I can tell myself, that I have had
positive experiences which made my own contributinos more apt for reviewi,
inclusion and promotion in general.

Unfortunately, those casual contributors are consistently under-represented
across the current workflows of the Nix* community. But signs can be
percieved throughout the ecosystem, that some actors would wish to make
Nix* more atractive to new contributors and man power (see also this year's 
nixCon talks). This RFC is just a tiny screw in the gears.

Consensus about the _significance_ of this single screw is expected not o be
reached. Therefore this RFC will fail. But I hope it leaves a thought legacy
of furthering the intricacies of the mentioned umbrella topic of promoting
Nix* adoption.

# Alternatives
[alternatives]: #alternatives

No alternatives have been considered.

# Unresolved questions
[unresolved]: #unresolved-questions

At the time of writing, no unresolved questions apear of relevance.

# Future work
[future]: #future-work

Neutrally estimate the current share of instances where the drawback
manifests based on observable data.
