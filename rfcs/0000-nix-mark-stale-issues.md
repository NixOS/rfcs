---
feature: nix-mark-stale-issues
start-date: 2022-04-18
author: John Ericson (@Ericson2314)
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: @ryantm, @nh2, @infinisil
shepherd-leader: @ryantm
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Do not auto-close Nix issues and PRs.

Make the policy clear, and harmonize Nix's with Nixpkgs's, which was approved by
[RFC 51](https://github.com/NixOS/rfcs/blob/master/rfcs/0051-mark-stale-issues.md).

# Motivation
[motivation]: #motivation

## Background

In 2019, after much discussion,
[RFC 51](https://github.com/NixOS/rfcs/blob/master/rfcs/0051-mark-stale-issues.md) was approved to mark old Nixpkgs issues and PRs as stale,
but not close anything.

In 2021, @garbas contributed [Nix PR 4526](https://github.com/NixOS/nix/pull/4526),
which initially just made a stale bot configuration in line with Nixpkgs.
But @edolstra [specifically requested](https://github.com/NixOS/nix/pull/4526#discussion_r571687438) that stale items do be closed.
To be clear, there *is* no formal violation, as that RFC was just about Nixpkgs, but we should reconsider whether this was a good idea.

## Clear policy

Firstly, whatever the policy is, it should be clearly announced.

Without a big announcement of this decision, many of us were caught of guard when issues were closed the other day.
Anyone that just saw the previous stale bot "marking stale" messages probably assumed stale bot was configured like Nixpkgs.
Without knowing that auto-closing was enabled, people who might have bothered to aggressively triage stale issues before the auto-close deadline didn't.
For the social aspects of the stale bot auto-closing to work as intended, it is very important people *do* know the policy, because incentivizing that triaging by the threat of auto-closing is precisely the point!

This RFC, no matter the outcome, can help make the policy clear and known to all.

## Consistent policy

All things equal, it is probably not a good idea to pick a different policy for Nix than the one decided by the community for Nixpkgs.
The strong opinions in RFC 51 attest do attest that the community doesn't like auto-closing in that context.
Many of those strong opinions apply to issue tracking for open source project in general, not just for Nixpkgs in particular.

## Nix's particular backlog

Still, we might ask whether the situation in Nix is different from Nixpkgs in ways that would motivate a different decision.
We would in fact argue the opposite: that Nix is an especially *poor* candidate for auto-closing.
Nix's backlog in particular reflects a long history of the community being able to raise issues without being empowered to address their own issues.
This asymmetry inevitably led an ever-growing backlog.

We are doing somewhat better now, but have been busy just trying to keep up with new issues, and not yet working retroactively through the backlog as a team.
To finish turning a new leaf, it would be very healthy gesture to go through that backlog, atoning for the prior state of affairs.
Closing the backlog without review forfeits that opportunity.

## Summary

For these reasons, we advocate in priority order:

1. Making the policy, whatever it may be, loud and clear.

2. Making the Nix policy match the Nixpkgs policy, for simplicity.

3. Making the Nix policy not auto-close, in light of the special situation of how the backlog arose in the first place.

# Detailed design
[design]: #detailed-design

Apply this diff to the `.github/stale.yml` configuration file:

1. ```diff
   diff --git a/.github/stale.yml b/.github/stale.yml
   index fe24942f4..539720b6d 100644
   --- a/.github/stale.yml
   +++ b/.github/stale.yml
   @@ -1,10 +1,8 @@
    # Configuration for probot-stale - https://github.com/probot/stale
    daysUntilStale: 180
   -daysUntilClose: 365
   +daysUntilClose: false
    exemptLabels:
      - "critical"
   +  - "never-stale"
    staleLabel: "stale"
   -markComment: |
   -  I marked this as stale due to inactivity. &rarr; [More info](https://github.com/NixOS/nix/blob/master/.github/STALE-BOT.md)
   -closeComment: |
   -  I closed this issue due to inactivity. &rarr; [More info](https://github.com/NixOS/nix/blob/master/.github/STALE-BOT.md)
   +markComment: false
   +closeComment: false
   ```

2. Reopen recently auto-closed items, either automatically *en masse*, or manually allowing some triage.
   The route will be chosen based on human resourcing constraints; it is unclear which is less work.

# Drawbacks
[drawbacks]: #drawbacks

Manually combing through the backlog takes time.

# Alternatives
[alternatives]: #alternatives

1. Align Nixpkgs's and Nix's configs some other way.

2. Leave config as-is.
