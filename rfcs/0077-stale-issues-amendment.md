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

Under the interpretation of this motivation, the definition of stale was 
settled at 180 days.

This RFC modifies the motivation for marking issues as stale:

_A stale issue (or PR) is an issue on which the discussion has went stale. It
has no other semantic meaning than an aggregated indicator of individual
preferences (to not interact on a particular issue or PR)._

_Therefore, a PR goes stale after a 90 days period (vs previously 180 days)
and an issue goes stale after a 60 days period (vs previously 180 days)._

# Motivation
[motivation]: #motivation

Under the renewed definition of _stale_ under this PR but the currently
applied time periods, spectators based on their common understanding 
are not told about  aggregate choices as a fair proxy of chances of 
success by means of the stale label.

This discourages spectators with vested interests from promoting issues,
that are visibly exhibiting lack of interaction, and there by reduced
chances of (prompt) "success".

An issue that hasn't been interacted with for 60 days or a PR for 90 days
and in the vast majority of cases deserve an aggregate indication of
those individual preferences for the above reason.

Honesty and transparency are better in informing an individual's action
than preceived political correctness (judging by the discussions on RFC 51).

# Detailed design
[design]: #detailed-design

- Mark PRs as stale after 90 days
- Mark issues as stale after 60 days
- Keep the policy of never closing either PRs or Issues.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

It should be noted under this section, that it only takes a comment
to un-satale an issue or PR.

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

# Alternatives
[alternatives]: #alternatives

No alternatives have been considered.

# Unresolved questions
[unresolved]: #unresolved-questions

At the time of writing, no unresolved questions apear of relevance.

# Future work
[future]: #future-work

No future work is required.
