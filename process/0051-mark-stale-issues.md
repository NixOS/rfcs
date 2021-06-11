---
feature: mark-stale-issues
start-date: 2019-08-24
author: Ryan Mulligan
co-authors: (find a buddy later to help our with the RFC)
shepherd-team: @globin, @grahamc, and @peti
shepherd-leader: @peti
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Mark stale Nixpkgs issues and pull requests (hereafter both referred
to as simply "issues") on GitHub using an application provided by
GitHub.

# Motivation
[motivation]: #motivation

We have a large number of open issues that have accumulated
over the years. Not all of them are still valid and need our
attention.

By marking stale issues, we can more easily filter issues for ones
that have at least one person interested in them.

# Detailed design
[design]: #detailed-design

1. Use the [Stale](https://github.com/marketplace/stale) application
   provided by GitHub on the [Nixpkgs
   repository](https://github.com/NixOS/nixpkgs).
2. Start by using the following `.github/stale.yml` configuration
   file:

   ```
   # Number of days of inactivity before an issue becomes stale
   daysUntilStale: 180
   # Number of days of inactivity before a stale issue is closed
   daysUntilClose: false
   # Issues with these labels will never be considered stale
   exemptLabels:
     - 1.severity: security
   # Label to use when marking an issue as stale
   staleLabel: 2.status: stale
   # Comment to post when marking an issue as stale. Set to `false` to disable
   markComment: >
     Thank you for your contributions.

     This has been automatically marked as stale because it has had no
     activity for 180 days.

     If this is still important to you, we ask that you leave a
     comment below. Your comment can be as simple as "still important
     to me". This lets people see that at least one person still cares
     about this. Someone will have to do this at most twice a year if
     there is no other activity.

     Here are suggestions that might help resolve this more quickly:

     1. Search for maintainers and people that previously touched the
        related code and @ mention them in a comment.
     2. Ask on the [NixOS Discourse](https://discourse.nixos.org/).
     3. Ask on the [#nixos channel](irc://irc.freenode.net/#nixos) on
        [irc.freenode.net](https://freenode.net).

   # Comment to post when closing a stale issue. Set to `false` to disable
   closeComment: false
   ```

# Drawbacks
[drawbacks]: #drawbacks

People will need to indicate their interest twice a year.

Marking issues stale might dissuade contributors who already feel
their contribution was being ignored.

# Alternatives
[alternatives]: #alternatives

1. Do nothing
