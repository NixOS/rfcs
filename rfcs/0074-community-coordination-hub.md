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

We lack an optimum level of _empowerment_<sup>[1](#empowerment)</sup> on distinct vital aspects for
the best [leverage](https://nav.al/least)<sup>[2](#leverage)</sup>. We don't have:

- Efficient Management Processes, that bias the whole community towards 
  _coordinated and optimal Resource Employment_.
- Organizational Structure, that enacts necesary degrees of _Division of Labor_ 
  and _Coordination_.
- Organizational Culture, that helps to overcome the complexity bias. ([KISS](https://en.wikipedia.org/wiki/KISS_principle))

<sub><a name="empowerment">1</a>: In the sphere of organizational theory, 
"empowerment" often refers loosely to processes for giving members greater
discretion and resources: distributing control in order to better serve 
the organization (adapted from 
[Wikipedia](https://en.wikipedia.org/wiki/Empowerment#In_management)).</sub>

<sub><a name="leverage">2</a>: Increasing leverage is the act of scrutinizing every decision or choice
as to potentialize it's desired outcome. You can be leveraged by code, community,
media, capital, labor and other ways. We need to better leverage our community
resources (tools, knowledge, people).</sub>

> Please express your approval/disapproval about this motivation in this poll: https://github.com/NixOS/rfcs/pull/74#issuecomment-675176621

> Please express your opinion, if something needs to be done about in this poll: https://github.com/NixOS/rfcs/pull/74#issuecomment-675176805

# General Design
[design]: #general-design

A repository shall exist, named `NixOS/community`, which will act as central hub
for coordinating the community's efforts.

It shall make it easy to mentally grasp how the community coordinates as a whole.
Getting involved with the community should feel as natural as skimming through
code on github (or on a local clone).

It shall be a place where established truths or conclusions that (have) emerge
from the communities conversations and decision making processes are recorded.

Therefore it shall act as single source of truth for aspects of:

- Communication
  - Channels
  - Modes & Policies
- Governance
  - Processes
  - Structure
- Onboarding
  - Code Contributions
  - Community Engagement

It shall _not_:

- document the standard library (or any other highly specific and established technical subject).
- act as discussion forum (but document outcomes).
- implement code (but coordinate it's implementation).
- exhibit established content that best fits into the manual (but call out to it and coordinate working drafts or ideas about it).

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

- Commnication/Channels: [Community Event Calender](https://github.com/kubernetes/community/tree/master/events)
- Governance/Processes: Community Event Planning
- Onboarding/Code Contributions: Explain and Support an Efficient Code Review Process.
- Onboarding/Community Engagement: Move non-technical aspects of nixpkgs' manual here
- Governance/Processes/Transparency: Record Meeting Minutes of working groups
- Governance/Structure: What are the structures about which the community behaves and coordinates?
- Governance/Structure/Acting Bodies: Evolve Design Prototypes before moving to RFC with in special interest groups
- Governance/Processes: How does the Community make decisions (formal and informal)?
- Governance/Processes: How disagreement are resolved (given consensus about a need is established)?
- Onboarding/Code Contributions: How to quickstart and where to find detailed (authoritative resoures)?
- Onboarding/Community Engagment: Don't be scared about asking stupid questions, unless you are aware they are stupid!

## User Stories
[user-stories]: #user-stories

If this RFC is implemented ...

### As a newcomer
As a newcomer, I'd be able to quickly find my way around, and start beeing
useful before beeing turned down by inconsistent and spread-out onboarding.

### As a veteran
As a veteran, I'd be able to promote some ideas, that I care about,
towards completion while suffering from less friction and overly complex
coordination. I can leverage my experience and skills more effectively
for the benefit of the community.

### As a mentor
As a mentor, I can inform my efforts with a clear and consistent reference.
It helps me to more effectively maintaining those high quality human 
interactions that the NixOS community is known for.

> Please express your approval/disapproval about this general design in this poll: https://github.com/NixOS/rfcs/pull/74#issuecomment-675177658

# Initial Repository Specification
[initial-spec]: #initial-repository-specification

After obtaining general consensus about the three items below,
we shall amend this section with a detailed initial specification of the
proposed repository based on the above mentioned detailed review
of `kubernetes/community` and other feedback.

The necesary consensus that unblocks to start work on this section is:

- We agree that the motivation is valid and there is a problem.
- We agree something ought to be done about it.
- We agree the git repository is the right medium and should be
  chosen as the implementation going forward?

Consensus shall be polled through github reactions on the PR's discussion.

This RFC can only be finally approved once this section is completed.

# Drawbacks
[drawbacks]: #drawbacks

There _can_ be a better solution to achieve _optimum levels of empowerment_
for our community. We _could just **wait**_ for them to unveil themselves.

# Alternatives
[alternatives]: #alternatives

- [Benevolent Dictatorship](https://discourse.nixos.org/t/what-would-you-do-if-you-were-the-bdfl-of-nix/6949)
- Ephemeral Conversations (Discourse)
- RFC process itself

One currently viable alternative for _coordination of resources and effort_
are ephemeral conversations in Discourse. While they lend meaning to the 
individual's interpretations and views onto the ecosystem, they lack important
features such as:

- Structure<sup>[3](#structure)</sup>
- Consolidation<sup>[4](#consolidation)</sup>
- Ability to act as _Reference_<sup>[4](#reference)</sup>

<sub><a name="structure">3</a>: Discourse does have inherent _structures_ that make people talk, it does 
not have (optimal) inherent structures to make people act.</sub>
<sub><a name="consolidation">4</a>:  In conversational style, a _conclusion_ lexically is nothing more than 
another agent speaking: we cannot systematically _establish_ ("consolidate") conclusions.</sub>
<sub><a name="reference">5</a>:  Lack of structure and consolitation make efforts of referencing arbitrary
in contrast to a legtimate single source of truth.</sub>

Another current viable alternative for _coordination of resources and effort_
are RFCs, like this one. However the RFC process has a structure that is 
biased towards (final) decision making, evidenced by the initial confusion
about this very RFC and the fact that barely any commenter proposes ideas
for the brainstorming section. This process, while stringent, well established
and prestigious falls short when applied to the need for more lenient and
ad hoc coordination. `NixOS/community` shall be, among others, a place
where RFCs might incubate and ripen  within the limited scope of a special
interest group or a working group or similar acting body.

RFCs also aren't a good fit for effective, yet legitimate subordinate decision
making. Therefore a framework for suboordinate, yet legitimate, decision making
should be conceived that empowers the acting bodies.

A portal page, like a repurposed [nix.wiki](https://nix.wiki) might at first
sight seem like an alternative mean to establish a community coordination hub.
But, _optimum empowerment_ requires low barriers to interaction and amendment.
Hence we suggesta GitHub repository. Repository tooling can provide the means
to make this body of resources available through a complementary portal page,
like https://nix.wiki or https://nix.community. Discussion with @samueldr is
expected to unfold with the aim to establish a join vision of this RFCs 
motivation and the future of https://nix.wiki.

Finally, we could resort to implementing eventually-deemed-useful artefacts
of the proposed `kubernetes/community` template freely into whatever medium
seems most fit for any given artefact. This, however, defies to address the
problems outlined by the _Motivation_ section in a _central **hub**_. Any
implementation, that does not exhibit a clear and central entrypoint is an
essentially an "anti-implementation" of this RFC.

# Unresolved questions
[unresolved]: #unresolved-questions

Is this the right level of abstraction to act as an enabling RFC for future
improvements and thereby resume the author's stance in a way that effects
the highest leverage over time?

What can we do to prevent proliferation of unhelahty overahead 
("excessive talking about doing, instead of doing")? Contributions
that are a collateral of a person's or company's own need _must_
not be discouraged.

What process should constitute an acting body such as a special interest group,
working group (or anything else)? - Should they be enacted through RFCs?
Or should RFCs be reserved for technical progress and acting bodies
constitute via a separate mechanism defined in `NixOS/community`?
See [Future Work](#future).

# Future work
[future]: #future-work

## Legitimize Acting Bodies

We need to define by which process acting bodies can legitimately conform, 
so they can rightfully excercise their entrusted authonomy.

## Constitue Acting Bodies
- Constitution of Woring Groups, such as (examplifications):
  - WG Contribution Workflows
  - WG Onboarding
- Constitution of Special Interest Groups (examplifications):
  - SIG Manual
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
