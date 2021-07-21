---
feature: unprivileged-maintainer-teams
start-date: 2019-01-16
author: Graham Christensen <graham@grahamc.com>
co-authors: zimbatm <zimbatm@zimbatm.com>
related-issues: https://github.com/NixOS/ofborg/pull/303
category: process
---

# Summary
[summary]: #summary

Package maintainers who are not able to commit directly to Nixpkgs
don't have adequate tools to attentively maintain their package.
OfBorg requests reviews of maintainers it can identify. GitHub only
allows requesting a review of a Collaborator of the repository.

This RFC bridges that gap, and allows OfBorg to request reviews of
maintainers.

# Motivation
[motivation]: #motivation

The goal of this RFC is to involve package maintainers in reviewing
pull requests against their packages. This RFC does not grant
maintainers the ability to merge pull requests against their own
package.

Maintainers take a responsibility for their package, and want to know
about updates to their package's expression. However, Nixpkgs receives
over 1,000 pull requests each month and subscribing to them all is not
a reasonable requirement to maintain a package.

The ideal outcome is package maintainership means a more active role
in reviewing and approving changes to Nixpkgs.

# Detailed design
[design]: #detailed-design

Package maintainers will be a member of a GitHub team, allowing OfBorg
to request a review.

## The Team

We will create a GitHub team under the NixOS GitHub organization
called "Nixpkgs Maintainers" which only grants "read" access to
Nixpkgs.

This team will not grant any privileges to the Nix ecosystem
repositories which non-members don't already have. They will not be able to
close other people's issues or PRs or push branches. Experimentation
and documentation shows this will only grant access to a team
discussion board on GitHub.

Being a member of this team will let the user mark themselves as a
public member of the organization. This will show the NixOS logo on
their GitHub profile, and people will see "Member" next to their
account name when browsing issues.

In order to be a member, each user will need to enable 2FA on their
GitHub account, since [the GitHub organization requires 2FA of all
members](https://github.com/NixOS/nixpkgs/issues/42761).

See
https://help.github.com/articles/permission-levels-for-an-organization/
for more information about what this will grant.

## Changes to `maintainers/maintainer-list.nix`

The existing Nixpkgs maintainer list already contains a structured
attribute set of per-maintainer details, including GitHub account
names. Automation will sync this list of GitHub handles with the
team's membership, automatically adding and removing people to/from
the team as the master branch's maintainer list changes.

GitHub handles can change from one user to another, and so we will
change the maintainer list to include the GitHub user *ID* as well as
their handle. When syncing, the automation will validate the user ID
matches. GitHub User IDs are easily found at
`https://api.github.com/users/«username»`.

If a user ID's GitHub handle changes, the maintainer should remain
part of the team under their new handle. The user's entry in
`maintainer-list.nix` should be updated to reflect their new handle.

## Team Automation

The team must be automatically updated at least once a day to ensure
the maintainer list is fresh and up to date. The automation for this
will be written in Rust with the hubcaps library. It will run on the
NixOS infrastructure with limited credentials, with only sufficient
permission to manage the team.

The automation will fetch a fresh version of Nixpkgs's master branch,
extract the maintainer information, and update the team. It will
support a dry-run option.

New members of the team will receive an invitation to join the GitHub
organization.

## Changes to Reviewer/Maintainer Behavior

Reviewers and maintainers should use GitHub's review tools (Approve,
Request Changes, etc.) to clearly communicate their feedback about the
pull request.

## OfBorg changes

OfBorg will identify PRs which are approved by their maintainers, and
add a special label `approved-by-maintainer`.

## Roll-Out Plan

1. Write an explanatory post on Discourse about the what-and-why of
   this plan.
2. Select a small group of maintainers who are not committers to be
   part of the first round, and manually run the tooling, and pause
   half a week to see what changes.
3. Automate the tooling on the infrastructure.
4. Expand the group to one quarter of the maintainers, and pause a
   half a week to gauge response.
5. Expand the group to one half of the maintainers and wait one week.
6. Expand the group to all of the maintainers.

If we receive no major feedback or problems during the rollout, we
will continue to 100%.

# Drawbacks
[drawbacks]: #drawbacks

 - Putting each maintainer in a read only team will display
   maintainers as "member", without specifying which team they are a
   member of. This gives the impression of authority which maintainers
   don't already receive. This is a pro and a con.

 - A mistake in the automation, or in the admin panel of GitHub could
   grant the team write access to Nix ecosystem repositories.

 - Package maintainers who do not wish to have a GitHub account will
   not benefit from this change.

 - Package maintainers who do have a GitHub account, but do not wish
   to use 2 factor authentication will not benefit from this change.

 - Someone who is banned from the NixOS GitHub organization is not
   allowed to be a package maintainer.

# Alternatives
[alternatives]: #alternatives

Mentioning people in GitHub comments is the main alternative. This has
the major down-side of not receiving the support of [GitHub's UI
for requested reviews](https://github.com/pulls/review-requested).


# Resolved questions
[resolved]: #resolved-questions

 - Is it possible for the automation to spam a user who doesn't want
   to be part of the team with invitations?
   No.

# Unresolved questions
[unresolved]: #unresolved-questions

 - Do maintainers want to be part of this team?
 - Will the requirement of 2FA cause a significant number of people to
   not want to participate?
 - How will we handle people who have been invited, but have not
   accepted the invitation?

# Future work
[future]: #future-work

 - Writing the automation program.
 - Adding UIDs to every maintainer.
 - Creating the GitHub team
 - Updating the NixOS Org Configurations repository to run the
   automation with credentials on an automated basis.

# Future Potential RFCs
The following topics are explictly _not_ part of this RFC.

 - Allowing maintainers to merge pull requests against their packages
   without having commit access.
 - Requiring all maintainers to have a GitHub account with 2FA.
