- Feature Name: rfc-process
- Start Date: 2017-02-12
- RFC PR:
- Related Issue:

# Summary
[summary]: #summary

The "RFC" (request for comments) process is intended to provide a consistent
and controlled path for new features to enter the nix language, packages and
OS, so that all stakeholders can be confident about the direction the
ecosystem is evolving in.

# Motivation
[motivation]: #motivation

There are a number of GitHub issues, PRs and mailing-list discussions where
significant contribution was put in but then grind to a halt. Usually because
there is either not a clear desirable outcome, the direction taken is not
desired (PR) or the stakeholder doesn't have enough brain space available to
think about the issue.

The motiviation for introducing this process is to avoid losing all that work.
By putting contributors through the RFC process for significant changes, it
should help clarify the path for contribution when the other routes aren't
suitable.

# Detailed design
[design]: #detailed-design

Many changes, including bug fixes and documentation improvements can be
implemented and reviewed via the normal GitHub pull request workflow.

Some changes though are "substantial", and we ask that these be put through a
bit of a design process and produce a consensus among the Nix community and
the core team.

This is the bulk of the RFC. Explain the design in enough detail for somebody
familiar with the ecosystem to understand, and implement.  This should get
into specifics and corner-cases, and include examples of how the feature is
used.

## When you need to follow this process

You need to follow this process if you intend to make "substantial" changes to
the Nix ecosystem. What constitutes a "substantial" change is evolving based
on community norms, but may include the following.

  - Any semantic or syntactic change to the language that is not a bugfix.
  - Removing language features
  - Big restructuring of nixpkgs
  - Introduction of new interfaces or functions

Some changes do not require an RFC:

  - Adding, updating and removing packages in nixpkgs
  - Additions only likely to be _noticed by_ other developers-of-nix,
    invisible to users-of-nix.

If you submit a pull request to implement a new feature without going
through the RFC process, it may be closed with a polite request to
submit an RFC first.

## What the process is

In short, to get a major feature added to the Nix ecosystem, one must first
get the RFC merged into the RFC repo as a markdown file. At that point the RFC
is 'active' and may be implemented with the goal of eventual inclusion into
the Nix ecosystem.

* Fork the RFC repo https://github.com/NixOS/rfcs
* Copy `0000-template.md` to `rfcs/0000-my-feature.md` (where
'my-feature' is descriptive. don't assign an RFC number yet).
* Fill in the RFC
* Submit a pull request. The pull request is the time to get review of
the design from the larger community.
* Build consensus and integrate feedback. RFCs that have broad support
are much more likely to make progress than those that don't receive any
comments.

Eventually, somebody on the [core team] will either accept the RFC by
merging the pull request, at which point the RFC is 'active', or
reject it by closing the pull request.

Whomever merges the RFC should do the following:

* Assign an id, using the PR number of the RFC pull request. (If the RFC
  has multiple pull requests associated with it, choose one PR number,
  preferably the minimal one.)
* Add the file in the `rfcs/` directory.
* Create a corresponding issue on the appropriate repo (NixOS/nix, NixOS/nixpkgs, ...).
* Fill in the remaining metadata in the RFC header, including links for
  the original pull request(s) and the newly created issue.
* Commit everything.

Once an RFC becomes active then authors may implement it and submit the
feature as a pull request to the nix or nixpkgs repo. An 'active' is not a
rubber stamp, and in particular still does not mean the feature will
ultimately be merged; it does mean that in principle all the major
stakeholders have agreed to the feature and are amenable to merging it.

# Drawbacks
[drawbacks]: #drawbacks

There is a danger that the additional process will hinder contribution more
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

1. Does this RFC strike a favorable balance between formality and agility?
2. Does this RFC successfully address the aforementioned issues with the current
   informal RFC process?
3. Should we retain rejected RFCs in the archive?

[PEP]: http://legacy.python.org/dev/peps/pep-0001/
