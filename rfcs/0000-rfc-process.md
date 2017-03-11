---
feature: rfc-process
start-date: 2017-02-12
author: zimbatm
co-authors: teh, MoreTea
related-issues: https://github.com/zimbatm/rfcs/pull/2
---

# Summary
[summary]: #summary

The "RFC" (request for comments) process is intended to provide a consistent
and controlled path for new features to enter the Nix language, packages and
OS, so that all stakeholders can be confident about the direction the
ecosystem is evolving in.

# Motivation
[motivation]: #motivation

There are a number of changes that are significant enough that they could
benefit from wider community consensus before being implemented. Either
because they introduce new concepts, big changes or are controversial enough
that not everybody will agree on the direction to take.

Therefore, the purpose of this RFC is to introduce a process that allows to
bring the discussion upfront and avoid unnecesary implementations. It forces
developers to formulate their ideas without getting bogged down into
implementation details. This RFC is used to bootstrap the process and further
RFCs can be used to refine the process.

# Detailed design
[design]: #detailed-design

Many changes, including bug fixes and documentation improvements can be
implemented and reviewed via the normal GitHub pull request workflow.

Some changes though are "substantial", and we ask that these be put through a
bit of a design process and produce a consensus among the Nix community.

This is the bulk of the RFC. Explain the design in enough detail for somebody
familiar with the ecosystem to understand, and implement.  This should get
into specifics and corner-cases, and include examples of how the feature is
used.

## When this process is followed

This process is followed when one intends to make "substantial" changes to the
Nix ecosystem. What constitutes a "substantial" change is evolving based on
community norms, but may include the following.

* Any semantic or syntactic change to the language that is not a bugfix
* Removing language features
* Big restructuring of nixpkgs
* Expansions to the scope of nixpkgs (new arch, major subprojects, ...)
* Introduction of new interfaces or functions

Certain changes do not require an RFC:

* Adding, updating and removing packages in nixpkgs
* Fixing security updates and bugs that don't break interfaces

Pull requests that contain any of the afore mentioned 'substantial' changes may be closed if there is no RFC connected to the proposed changes.

## Description of the process

In short, to get a major feature added to the Nix ecosystem, one should first
go through the RFC process in order to improve the likelyhood of inclusion.
Here are roughly the steps that one would take:

* Fork the RFC repo https://github.com/NixOS/rfcs
* Copy `0000-template.md` to `rfcs/0000-my-feature.md` (where 'my-feature' is
  descriptive. don't assign an RFC number yet).
* Fill in the RFC
* Submit a pull request. Rename the rfcs with the PR number. (eg: PR #123 would
  be `rfcs/0123-my-feature.md`)

At this point, the person submitting the RFC should find at least one "co-author"
that will help them bring the RFC to completion. The goal is to improve the
chances that the RFC is both desired and likely to be implemented.

Once the author is happy with the state of the RFC, she/he should seek for
wider community review by stating the readyness of the work. Advertisement on
the mailing-list and IRC is an acceptable way of doing that.

After a number of rounds of review the discussion should settle and a general
consensus should emerge. This bit is left intentionnaly vague and should be
refined in the future. We don't have a technical commitee so controversial
changes will be rejected by default.

If a RFC is accepted then authors may implement it and submit the feature as a
pull request to the Nix or nixpkgs repo. An 'accepted' RFC is not a rubber
stamp, and in particular still does not mean the feature will ultimately be
merged; it does mean that in principle all the major stakeholders have agreed
to the feature and are amenable to merging it.

Whoever merges the RFC should do the following:

* Fill in the remaining metadata in the RFC header, including links for the
  original pull request(s) and the newly created issue.
* Commit everything.

If a RFC is rejected, whoever merges the RFC should do the following:
* Move the rfc to the rejected folder
* Fill in the remaining metadata in the RFC header, including links for the
  original pull request(s) and the newly created issue.
* Include a summary reason for the rejection
* Commit everything

## Role of the "co-author"

To goal for assigning a "co-author" is to help move the RFC along.

The co-author should:
* be available for discussion with the main author
* respond to inquiries in a timely manner
* help with fixing minor issues like typos so community discussion can stay
  on design issues

The co-author doesn't necessarily have to agree with all the points of the RFC
but should generally be satisfied that the proposed additions are a good thing
for the community.

# Drawbacks
[drawbacks]: #drawbacks

There is a risk that the additional process will hinder contribution more
than it would help. We should stay alert that the process is only a way to
help contribution, not an end in itself.

# Alternatives
[alternatives]: #alternatives

Retain the current informal RFC process. The newly proposed RFC process is
designed to improve over the informal process in the following ways:

* Discourage unactionable or vague RFCs
* Ensure that all serious RFCs are considered equally
* Give confidence to those with a stake in the Nix ecosystem that they
  understand why new features are being merged

As an alternative, we could adopt an even stricter RFC process than the one
proposed here. If desired, we should likely look to Python's [PEP] process for
inspiration.

# Unresolved questions
[unresolved]: #unresolved-questions

To be solved in the future:

1. Does this RFC strike a favorable balance between formality and agility?
2. Does this RFC successfully address the aforementioned issues with the current
   informal RFC process?

[PEP]: http://legacy.python.org/dev/peps/pep-0001/
