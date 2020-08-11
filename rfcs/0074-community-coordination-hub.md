---
feature: community_coordination_hub
start-date: 2020-07-30
author: David Arnold <dar@xoe.solutions>
co-authors: Doron Behar <me@doronbehar.com>
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Adopt goals, spirit, concept and execution of [`kubernetes/community`]
where it _does_ fit [us](https://nixos.org/).

[`kubernetes/community`]: https://github.com/kubernetes/community

# Motivation
[motivation]: #motivation

We lack an optimum level of _empowerment_ on distinct vital aspects for
the best [leverage](https://nav.al/least). We don't have:

- Efficient Management Processes, that bias the whole community towards 
  _coordinated and optimal Resource Employment_.
- Organizational Structure, that enacts necesary degrees of _Division of Labor_ 
  and _Coordination_.
- Organizational Culture, that helps to overcome the complexity bias. ([KISS](https://en.wikipedia.org/wiki/KISS_principle))

# Detailed design
[design]: #detailed-design

A repository shall exist, named `NixOS/community`, which will act as central hub
for coordinating the community's efforts.

It shall comprehend, consolidate and showcase aspects of:

- Communication
  - Channels
  - Modes & Policies
- Governance
  - Processes
  - Structure
- Onboarding
  - Code Contributions
  - Community Engagement

It shall omit any technical subject about nix or code in general, other than
repository tooling.

To implement, myself, and anyone interested, will review https://github.com/kubernetes/community
to the smallest details.

Based on this review, we'll create a clean new repository at
`NixOS/community`, with what we considered was worth porting from
[Kubernetes' community portal](https://github.com/kubernetes/community).

As a general guideline for this review, we'd acknowledge the success
and impressive dynamics of the Kubernetes ecosystem.

## Brainstorm
[brainstorm]: #brainstorm

This section exposes loose ideas we might put into `NixOS/community` collected during
this RFC's review process.

- [Community Event Calender](https://github.com/kubernetes/community/tree/master/events)
- Explain and Support an Efficient Code Review Process.

# User Stories
[user-stories]: #user-stories

If this RFC is implemented ...

## As a newcomer
As a newcomer, I'd be able to quickly find my way around, and start beeing
useful before beeing turned down by inconsistent and spread-out onboarding.

## As a veteran
As a veteran, I'd be able to promote some ideas, that I care about,
towards completion while suffering from less friction and overly complex
coordination. I can leverage my experience and skills more effectively
for the benefit of the community.

## As a mentor
As a mentor, I can inform my efforts with a clear and consistent reference.
It helps me to more effectively maintaining those high quality human 
interactions that the NixOS community is known for.

# Drawbacks
[drawbacks]: #drawbacks

There _can_ be a better solution to achieve _optimum levels of empowerment_
for our community. We _could just **wait**_ for them to unveil themselves.

# Alternatives
[alternatives]: #alternatives

- [Benevolent Dictatorship](https://discourse.nixos.org/t/what-would-you-do-if-you-were-the-bdfl-of-nix/6949)
- Ephemeral Conversations (Discourse)

The only current viable alternative for _coordination of resources and effort_
are ephemeral conversations in Discourse. While they lend meaning to the 
individual's interpretations and views onto the ecosystem, they lack important
features such as:

- Structure
- Consolidation
- Ability to act as _Reference_

A portal page might at first sight seem like an alternative mean to establish
a community coordination hub, especially for the above features. But, _optimum
empowerment_ requires low barriers to interaction and amendment. Hence we suggest
a git repository. Repository tooling can provide the means to make this body
of resources available through a complementary portal page.

# Unresolved questions
[unresolved]: #unresolved-questions

Is this the right level of abstraction to act as an enabling RFC for future
improvements and thereby resume the author's stance in a way that effects
the highest leverage over time?

# Future work
[future]: #future-work

- Constitution of Woring Groups, such as (examplifications):
  - WG Contribution Workflows
  - WG Onboarding
- Constitution of Special Interest Groups (examplifications):
  - SIG Rust
  - SIG Security
  - SIG Golang
  - SIG Python
  - SIG Contributor Experience
  - SIG Command Line Interface "nix 2.0"
  - SIG Tooling & Automation
  - SIG Testing & Infrastructure
- Constitution of User Groups (examplifications):
  - UG NixOS
  - UG Flakes

(those might be way too many, of course)

# Credits

This analysis is somewhat inspired by the following schools of thought:

- [New St.Gallen Managament Model](https://cio-wiki.org/wiki/The_New_St._Gallen_Management_Model)
- [Viable System Theory](https://en.wikipedia.org/wiki/Viable_system_theory)
- [Complexity and Self-organization](http://pcp.vub.ac.be/Papers/ELIS-complexity.pdf)

