---
feature: close-stale-issues
start-date: 2019-08-24
author: Ryan Mulligan
co-authors: (find a buddy later to help our with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Close stale Nixpkgs issues and pull requests (hereafter both referred
to as simply "issues") on GitHub using an application provided by
GitHub.

# Motivation
[motivation]: #motivation

The Nixpkgs GitHub page has a large number of open issues causing
community angst and misrepresenting the responsiveness of the project.

By closing stale issues, we can (in an automated way) refocus our
efforts on the ones that have at least one person interested in them.

# Detailed design
[design]: #detailed-design

1. Use the [Stale](https://github.com/marketplace/stale) application
   provided by GitHub on the [Nixpkgs
   repository](https://github.com/NixOS/nixpkgs).
2. Start by using the following `.github/stale.yml` configuration
   file:

   ```
   # Number of days of inactivity before an issue becomes stale
   daysUntilStale: 60
   # Number of days of inactivity before a stale issue is closed
   daysUntilClose: 7
   # Issues with these labels will never be considered stale
   exemptLabels:
   # Label to use when marking an issue as stale
   staleLabel: stale
   # Comment to post when marking an issue as stale. Set to `false` to disable
   markComment: >
     This issue has been automatically marked as stale because it has not had
     recent activity. It will be closed if no further activity occurs. Thank you
     for your contributions.
   # Comment to post when closing a stale issue. Set to `false` to disable
   closeComment: false
   ```

# Drawbacks
[drawbacks]: #drawbacks

People who want to keeps issues open will need to keep indicating
their interest.

Closing issues might make valueable contributions hard to find.

Marking issues stale might dissuade contributors who already feel
their contribution was being ignored.

# Alternatives
[alternatives]: #alternatives

1. Do nothing
2. Make custom tooling to do something more sophisticated

# Unresolved questions
[unresolved]: #unresolved-questions

1. Should we make use of the `exemptLabels` option?
