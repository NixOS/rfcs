---
feature: nix-core-team
start-date: 2018-01-31
end-date: 2019-04-25
author: Graham Christensen
co-authors: Daniel Peebles, Eelco Dolstra, Peter Simons, Shea Levy, Vladimír Čunát
related-issues: #44 (disbands the team)
category: process
---

# Superseded!

This RFC is superseded by [RFC 44](./0044-disband-nix-core.md). The original text
is preserved below.

# Summary
[summary]: #summary

Create an experimental Nix Core Team to help lead the direction of
Nix. This RFC may not be perfect, and we don’t have good answers to
all the possible questions, but let’s try it.

# Motivation
[motivation]: #motivation

 - Improve visibility in to how the project operates
 - Distribute the work Eelco has been doing across more people
 - "Unstuck" pull requests which are sitting idle
 - Provide a more diverse group of experiences when evaluating changes
   to core Nix

# Detailed design
[design]: #detailed-design

## This team will:

 - Evaluate larger features being proposed to Nix
 - Serve as a second opinion on Nix changes that Eelco doesn't
   otherwise see the value to
 - Make road-mapping decisions
 - Evaluate a change to determine if it is ready for inclusion
 - Follow up on unreviewed pull requests

The core team will have a GitHub team, a public mailing list, and
perhaps an IRC channel. The team will comprise long-term, trusted
community members who have a deep understanding of Nix and the Nix
ecosystem.

## To start with, the team will be:

 - Daniel Peebles @copumpkin
 - Eelco Dolstra @edolstra
 - Peter Simons @peti
 - Shea Levy @shlevy
 - Vladimír Čunát @vcunat

The team will be considered experimental to encourage revisiting how
the processes work and refining them over time. We encourage the use
of the RFC process to guide the process of the team itself. We
explicitly invite the wider community to propose RFCs to help with
this.

Ultimately, we hope for a similar process to develop for NixOS as
well.

This experiment will run for one year, to allow for a few Nix and
NixOS releases.

## Making Decisions

In all cases, the team will strive to reach consensus. However,
consensus will not always be possible. Decisions will be made after
four out of five members vote for approval.

Votes are registered through `+1`s and `-1`s. `Looks good to me`, `I
don't know`s and `I'm not sure`s aren't votes.

If some members abstain from the discussion, the following voting
rules apply:

1. In any case, if two people are -1 on a proposal, it fails.
2. If after a sufficient period of time (to be determined later,) if
   only one person is -1 on a proposal and two or more people are +1,
   it passes.

## What this team is not

This team is not about infrastructure, Nixpkgs, NixOS, Hydra, or the
Foundation. This team is to focus very narrowly on Nix.
