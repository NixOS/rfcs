---
identifier: disband-nix-core
start-date: 2019-04-25
author: Shea Levy
co-authors:
related-issues: NixOS/rfcs#25
category: process
---

# Summary
[summary]: #summary

Formally disband the Nix Core Team in favor of the RFC steering
committee.

# Motivation
[motivation]: #motivation

The Nix Core Team was a first attempt at more formal process for the
evolution of the Nix ecosystem and community. It was originally slated
as a year-long experiment.

It is now a little over a year since officially merging. In that time,
the core team has not made signifcant progress on its initial goals.
We now have the RFC steering/shepherding process which serves similar
goals (but for the whole ecosystem, not just Nix proper) and is
operating well. The remaining functions of the core team *not* covered
by the RFC process (e.g. PR triage) can be resurrected as more
narrowly defined responsibilities defined through RFCs.

# Detailed design
[design]: #detailed-design

Remove the github group, close down the communication channels,
announce on all relevant forums.

# Drawbacks
[drawbacks]: #drawbacks

* The RFC process is not based around Nix expertise per se, and so may
  not cover the right skillsets.
* There is not perfect overlap between the RFC process coverage and
  what the core team was intended to cover.

# Alternatives
[alternatives]: #alternatives

* Keep the core team around in its current form and responsibilities.
  Would require a fresh attempt to follow through on the relevant
  committments to be practical.
* Reform the core team based on what we've learned, including possibly
  narrowing the scope.

# Unresolved questions
[unresolved]: #unresolved-questions

N/A

# Future work
[future]: #future-work

Potentially explicitly enshrining some of the former core team
responsibilities in some future RFCs.
