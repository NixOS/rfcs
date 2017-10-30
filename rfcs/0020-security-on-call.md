---
feature: security-on-call
start-date: 2017-10-30
author: Graham Christensen
co-authors:
related-issues:
---

# Summary
[summary]: #summary

Organize and distribute the handling of public vulnerability
disclosures, through the use of a community-based team and rotating
"point" or "on-call" assignments.

# Motivation
[motivation]: #motivation

## 1. Security Posture, Prompt Patching, and Documented Process

Our process for security issues is currently fairly well executed, but
porly defined. How to participate and how to do the job is very
nebulous and boils down to:

1. Everybody pays attention
2. Everybody patches

This system means there is no division of labor, and no documented way
to ensure patches are patched the same way, every time.

## 2. Community and Commitment Sensitivity

As a community, we have a few dedicated contributors patching
the vast majority of security issues. This has worked well, and has
even ensured fairly good coverage for some time now.

Security patching work is an easy way to burn contributors out. The
perpetual feed of new issues to fix is exhausting. This is concerning,
because most of the patches are being applieed by highly skilled,
involved, and "core" members of the NixOS community. It would be a
shame to lose them.

At the same time, most security patches are easy to apply:

 - Most announcements to security email lists include easy-to-apply
   patches.
 - Well established, well funded distributions have full time
   employees focusing on security matters. These other distributions
   regularly publish their minimal security patches on their bug
   trackers or in their source trees.
 - Many security issues can be easily fixed by minor package bumps.

Some of the more tricky parts are determining how to backport the
patch, and finding build capacity for testing large rebuild changes.
Both of these questions can easily be answered by asking more
experienced community members for help.

# Detailed design
[design]: #detailed-design

I propose we create an on-call rotation for publicly disclosed
security issues. Each member of the team will be on call for 24 hours,
and expected to handle every new issue which is created within their
on-call period.

The patching team will not handle issues under embargo.

## Patching Team

The team should be of at least 10 members, preferably over 14.

Members of this team should range from new contributors looking to
participate, to more skilled and well known contributors.

### Requirements

Each team member should:

 - Know how patches work, or at least be willing to learn
 - Be comfortable with Git and our backporting workflow
 - Know their personal limits and be confident asking for help

## On Call

An on-call rotation system should be used or made to handle scheduling
and informing people about their shift. A shift is 24hrs long, and
should probably start at midnight UTC, to be equally unfair to
everyone.

### Responsibilities

1. Monitor a well defined list of mailing lists for new issues.
2. Ensure each issue is triaged and addressed if needed.

#2 is a bit vaguely worded, as the person is not required to
_actually_ fix the issue. They are allowed to delegate the patching to
other people. However, they _are_ responsible for ensuring the issue
is _fixed_.

#### Triage and Fixing

1. Check to see if the issue impacts each supported version of NixOS.
2. Write and / or backport patches as applicable, either by version
   bumps, large patches, or minimal patches.
3. Prepare an advisory to send to the nix-security-announce mailing
   list, which a member of the NixOS Security Team will send.

## The Well Defined List of Mailing Lists

The list should not live in the RFC documentation, but an external set
of documentation used to document the security patching process.
However, an initial starting list to consider:

1. oss-security
2. full-disclosure
3. an assortment of distro advisory announcements:

 - debian
 - redhat
 - suse
 - gentoo

## Ensuring Complete Mailing List Coverage

This is a tricky problem, and I propose that the first implemention
be naive, simple, quick, and ugly.

I propose we have a shared email account with a norm that if you mark
an issue read, you are obligated to handle the issue. Once issues are
patched and released to channels, they should be removed from the
inbox. Each member of the patching team will have access to the
account.

# Drawbacks
[drawbacks]: #drawbacks

This process will take time away from other projects contributors may
be interested in undertaking.

This project will introduce more mass rebuilds and additional load on
Hydra.

# Alternatives
[alternatives]: #alternatives

1. RequestTracker for email-to-issues, but the RT module is somewhat
   broken, not to mention the scars we all have around RT.
2. Custom email-to-issue software
3. Allow certain community members to be single points of failure

# Unresolved questions
[unresolved]: #unresolved-questions

1. A place to house documentation and run-books for the patching team
2. A review process for advisories
3. Guidelines for backporting vs. separate patches when fixing a
   package for Stable
4. A tool for handling the On Call schedule asignments and
   on-call/off-call notification reminders.

# Future work
[future]: #future-work

Please see Unresolved Questions :)
