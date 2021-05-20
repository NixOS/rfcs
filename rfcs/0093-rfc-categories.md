---
feature: rfc_categories
start-date: 2021-05-19
author: David Arnold
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues:
---

# Summary
[summary]: #summary

The RFC process is amended with means to categorize RFCs into one of: _feature_, 
_information_ or _process_, where each category sets different accents that
improve the overall process.

# Motivation
[motivation]: #motivation

Some issues are not addressed by the community:

There is no appropriate venue for it. 

Specifically, it is hard to propose a well coordinated experiment across the community,
document and acknowledge design issues, record proof-generated insight, but also to
amend the RFC process itself, the forum rules, the code of conduct or propose any other 
other binding changes to community workflows or infrastructure.

# Detailed design
[design]: #detailed-design

Every RFC that is eligible for the RFC process is classified by the author into the
_information_, _process_ or _feature_ category. How those categories are defined in every
detail, can remain subjective, but the following should give a sufficient idea:

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

Before this RFC reaches FCP, the RFC template is amended accordingly through this PR.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

This section illustrates the detailed design. This section should clarify all
confusion the reader has from the previous sections. It is especially important
to counterbalance the desired terseness of the detailed design; if you feel
your detailed design is rudely short, consider making this section longer
instead.

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

# Prior Art

This RFC is primarily inspired by the [BORS RFC][bors-rfc] process.

[bors-rfc]: https://bors.tech/rfcs/
