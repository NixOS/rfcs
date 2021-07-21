---
feature: rfc_categories
start-date: 2021-05-19
author: David Arnold
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: @kevnicox, @Mic92, @gytis-ivaskevicius
shepherd-leader: @kevincox
related-issues:
category: process
---

# Summary
[summary]: #summary

The RFC process is amended with means to categorize RFCs into one of: _feature_, 
_information_ or _process_, where each category sets different accents that
improve the overall outcome of the process.

# Motivation
[motivation]: #motivation

## Some issues are not addressed by the community

There is no appropriate venue for it. When reading the current RFC process, it becomes
clear that it was made primarily with purely technical decisions in mind. It might only
be a perception, but this perception systemically skews what's being discussed and what
not.

As a result, important topics might not be adressed and settled by the community at large
in a generally accepted procedure.

Specifically, it is hard to propose a well coordinated experiment across the community,
document and acknowledge design issues, record proof-generated insight, but also to
amend the RFC process itself, the forum rules, the code of conduct or propose any other 
binding changes to community workflows or infrastructure.

**For example**, the [flake RFC](https://github.com/NixOS/rfcs/pull/49), which by many is
considered a failed RFC process, might have benefited from a framework to transition into
a general experiment in the form of an _informational_ RFC as soon as it had become
clear that it won't be accepted as a _feature_ RFC. Its subsequent closure has rendered
the entire flake experiment to a largely undocumented, unstructured, and intransparent
process that still elicites strong opinions within the community. Clarity over RFC options
and venues _might_ have helped mitigate this situation.

## Some issues are not addressed from the appropriate angle

Even if, in the past, people might have used the RFC Process to gather broader consensus
around some of those hard-to-propose topics, the ensuing discussion still might have been
framed in a way that is not best suited. This actually starts with the structure of the
template.

By explicitly categorizing RFCs, it will be immediatly evident for participants that
those RFCs are a) legitimate and b) require an evaluation within the fair boundaries
of their categories.

**For example**, [RFC31](https://github.com/NixOS/rfcs/pull/31), a feature RFC, then was
closed and superseded by [RFC46](https://github.com/NixOS/rfcs/pull/46), which ended up 
being an informational RFC with certain inclination towards a process RFC, that was accepted.
RFC46 is a prime example of the usefulness of "documenting language", as the RFC relates to
its purpose. Having an explicit categorization is expected to suggest making use of these
venues to a broder RFC author base.

## Add structure to an increasingly used RFC process

As the RFC process will be more widely used by a growing community, it becomes necesary to
structure and differentiate the process further to remain as efficient and accessible as
possible. Adding a category metadata and differentiate the templates will help to better
accomodate the multiple aspects that might require a "Request For Comment" from the broader
community. It is expected that we identify more useful categories and nuances to the process
as its usage increases.

# Detailed design
[design]: #detailed-design

Every RFC that is eligible for the RFC process is classified by its author into the
_informational_, _process_ or _feature_ category. For each category a different template
is made available. How those categories are defined in every detail can remain
subjective, but the following should give a sufficient idea:

- Informational RFCs
  - Start a talk, meetup, or social networking account that will be expected to officially “represent nix”
  - Document design issues, deciding to never implement a feature
  - Proposing an experiment
  - Recording a proof-generated insight 
- Process RFCs
  - Change the RFC process, the organization of the issue tracker or the support forum
  - Changes to community workflows or other community infrastructure
  - Amend the Code of Conduct        
- Feature RFCs
  - Anything that is currently covered by the RFC process and does not better fit into
    any of the other two categories.

Authors are advised to choose the most prevalent category for their classification. For
example, if an informational RFC requires some changes to the community infrastructure,
but still mainly proposes an experiment, it would go into the "informationl" category.

This RFC is accompanied by commits that implement it. Please refer to them for the detailed
design.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

The relevant examples and interactions are exposed in the motivation section.
The detailed design does not require further exemplification, since it is intended to be
an authors personal best judgment that drives the categorization, not a specific set of criteria.
I don't think its feasible to develop such fixed set of criteria herein in a meaningful way.

# Drawbacks
[drawbacks]: #drawbacks

No substantial drawback comes to my mind, that would not be an alibi for this section.

# Alternatives
[alternatives]: #alternatives

No alternative comes to my mind, that would not be an alibi for this section.

# Unresolved questions
[unresolved]: #unresolved-questions

At the point of initiating this RFC, the detailed changes to the template are not yet known.
They will be complemented at any suitable point before reaching FCP.

# Future work
[future]: #future-work

With the additional metadata proposed herein present in RFCs, we might start to find it useful
to present different RFC categories in different contexts.

One such example can be to render
_Process RFCs_ within the governance section of the Discourse forum.

Another example might be to formally frame the discussion differently according to the RFC category.
Since we can't know yet, I'm not proposing any of this in here.

Once we have some experiences with those categories, we might also decide to:

- differentiate categories, add more
- differentiate processes for different categories, for example, for a Process RFC that modifies
   workflows, we could adopt a different workflow:
  1. Create a Process RFC
  1. Initial Comment Period
  1. Implement Prototype, request infrastructure for prototype
  1. Generate data & insights from Prototype and record them in the RFC
  1. Proceed to Final Comment Period
  1. Fully implement in production after RFC acceptation.

# Prior Art

This RFC is primarily inspired by the [BORS RFC][bors-rfc] process.

[bors-rfc]: https://bors.tech/rfcs/
