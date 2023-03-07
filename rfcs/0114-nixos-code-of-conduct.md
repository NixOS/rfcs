---
feature: NixOS Code of Conduct
start-date: 2021-11-03
author: @jonringer
co-authors:
shepherd-team: @edolstra @zimbatm @winterqt
shepherd-leader:
related-issues: #98 #102
---

# Summary
[summary]: #summary

The Nix community needs some foundation of shared values which can be used
to determine appropriate behavior when contributing and interacting with the community.
We currently have a [community ethos](https://github.com/NixOS/nixos-homepage/blob/3f30d59a663c565dd3e43490898f5ab75d06e07f/community/index.tt#L11-L24), but
this only states that we are an inclusive community, but doesn't define
inappropriate behavior when interacting with the community. This RFC aims
to establish the shared values, so they can be used to identify behavior
which is disruptive to the community.

This RFC does not intend to define moderation practices.

# Motivation
[motivation]: #motivation

The NixOS community lacks a clearly defined way in which someone's behavior may
be disruptive. A well-defined Code of Conduct gives an explicit
set of expectations for all contributors, which will also make it easier to identify
when behavior becomes disruptive.

# Detailed design
[design]: #detailed-design

These statutes are taken from [rust-lang's Code of Conduct](https://www.rust-lang.org/policies/code-of-conduct),
which provides a great compromise between explicit behaviors and subjective goals.
Only minor changes have been made.

- We are committed to providing a friendly, safe and welcoming environment for
all, regardless of level of experience, gender identity and expression,
sexual orientation, disability, personal appearance, body size, race, ethnicity, age,
religion (or lack thereof), socioeconomic status, nationality, or other similar characteristics.
- Please avoid using overtly sexual aliases or other nicknames that might
detract from a friendly, safe and welcoming environment for all.
- Please be kind and courteous. There’s no need to be mean or rude.
- Respect that people have differences of opinion and that every design or
implementation choice carries a trade-off and numerous costs. There is seldom a single right answer.
- Please keep unstructured critique to a minimum. If you have solid ideas
you want to experiment with, make a fork and see how it works.
- We will exclude you from interaction if you insult, demean or harass anyone.
That is not welcome behavior. We interpret the term “harassment” as including the definition in the
[Citizen Code of Conduct](https://github.com/stumpsyn/policies/blob/b8ee50e7a9fc79c39c936830901f8863d493b7cd/citizen_code_of_conduct.md);
if you have any lack of clarity about what might be included in that concept,
please read their definition. In particular, we don’t tolerate behavior that excludes
people in socially marginalized groups.
- Private harassment is also unacceptable. No matter who you are, if you feel
you have been or are being harassed or made uncomfortable by a community member,
please contact one of the channel ops or any of the NixOS moderation team immediately.
Whether you’re a regular contributor or a newcomer, we care about making this community
a safe place for you and we’ve got your back.
- Likewise any spamming, trolling, flaming, baiting or other attention-stealing behavior is not welcome.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

There have been a few spectacular failures of communication and good faith within the community.
Most notable recent examples include [ad-hominem attacks in a PR review](https://github.com/NixOS/nixpkgs/pull/120729#discussion_r621885348)
and associated [block evasion discourse thread](https://discourse.nixos.org/t/github-block-evasion-is-not-acceptable/12763),
heated discussions in [RFC #98](https://github.com/NixOS/rfcs/pull/98) and [RFC #111](https://github.com/NixOS/rfcs/pull/111).
Each of these incidents have caused significant discussion on IRC (when it was still official),
Matrix, Discourse, and would bleed over into GitHub and even non-official platforms.
These discussions are generally very polarizing, and cause an enormous amount
of emotional and mental stress to those involved.
These incidents are also very embarrassing for the entire Nix community,
and not having a way to identify disruptive before it becomes a heated
issue is detrimental to the health of the community.

In conjunction with a moderation team (out-of-scope for this RFC), these incidents could have been
better arbitrated as to have a more satisfactory resolution before escalation. This
Code of Conduct will better equip the moderation process by providing clear expectations
for behavior within the community.

# Drawbacks
[drawbacks]: #drawbacks

- There are potentially more "rules" for the community to follow. However, many of these rules
are enforced already under the current moderation team, but without an explicit definition.

# Alternatives
[alternatives]: #alternatives

- #98 Also provides an opinionated values and goals for the moderation team. However,
these rules are less well-defined, and allow for broader interpretations
of unacceptable behavior.

- #102 Codifies some of the existing moderation practices, and uses the
existing [community ethos](https://nixos.org/community/index.html) as moderation criteria.

- Use existing [community ethos](https://nixos.org/community/index.html) as moderation criteria.
However, this only includes inclusive statements, and doesn't define unacceptable behavior.

# Unresolved questions
[unresolved]: #unresolved-questions

# Future work
[future]: #future-work

- Add Code of Conduct to nixos.org, and mention the Code of Conduct on all relevant
repositories under the NixOS organization.

