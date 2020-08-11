---
feature: community_coordination_hub
start-date: 2020-07-30
author: David Arnold <dar@xoe.solutions>
co-authors: (find a buddy later to help out with the RFC)
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
the best [leverage](https://nav.al/least) on the available resources:

- Efficient Management Processes, that bias the whole community towards 
  _coordinated and optimal Resource Employment_.
- Organizational Structure, that enacts necesary degrees of _Division of Labor_ 
  and _Coordination_.
- Organizational Culture, that helps to overcome the complexity bias. ([KISS](https://en.wikipedia.org/wiki/KISS_principle))

Analysis inspired by [New St.Gallen Managament Model].

[New St.Gallen Managament Model]: https://cio-wiki.org/wiki/The_New_St._Gallen_Management_Model

# Detailed design
[design]: #detailed-design

A repository shall exist, named `NixOS/community`, which acts as central hub
for coordinating the community dynamics.

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

To implement, a detailed review of https://github.com/kubernetes/community
shall be conducted as joint effort between the interested parties and as 
an Annex I to this RFC.

Based on this review, a clean repository shall be enacted implementing
such aspects considered worth porting to our community.

As a general guideline for this review, the vast success and impressive
dynamics of the kubernetes ecosystem shall be acknowledged not only as a
proof of concept, but as a very sucessfull and inspiring [viable system].

[viable system]: https://en.wikipedia.org/wiki/Viable_system_theory

## Brainstorm
[brainstorm]: #brainstorm

This section exposes loose ideas that have sparked interest of RFC commenters
in their order of submission. They shall be considered _optional_ material
during implementation, whereas implementors shall have the liberty to
deliver a consistent experience as they see fit.

- [Community Event Calender](https://github.com/kubernetes/community/tree/master/events)

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
As a mentor, I can _still_ \* maintain those high quality direct human
interactions, while having full support of a
_"[curriculum](https://en.wikipedia.org/wiki/Curriculum)-like"_ resource.

\* _still_, as an aside, because nix community is known for it's great
mentorship spirit.

# Drawbacks
[drawbacks]: #drawbacks

There _can_ be a better solution to the achieve _optimum levels of empowerment_
for our community. We _could just **wait**_ for them to unveil themselves.

# Alternatives
[alternatives]: #alternatives

- [Benevolent Dictatorship](https://discourse.nixos.org/t/what-would-you-do-if-you-were-the-bdfl-of-nix/6949)
- Ephemeral Conversations (Discourse)

The only current viable alternative for _coordination of resources and effort_
are ephemeral conversations in Discourse. While, they lend meaning to the 
individual's interpretations and views onto the ecosystem, they lack important
features such as:

- Structure
- Consolidation
- Ability to act as _Reference_

A portal page might at first sight seem like an alternative, especially for those
features. But, _optimum empowerment_ requires low barriers to interaction and
amendment. Hence a git repository. Repository tooling can complement this aspect
and deploy a static page under the nixos.org for a design lift on the content.

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

(those are way too many, of course)
