---
feature: nixos-release-schedule
start-date: 2020-11-28
author: Jonathan Ringer (@jonringer)
co-authors: Frederik Rietdijk (@FRidh)
shepherd-team: @ryantm, @domenkozar and @garbas
related-issues:
---

# Summary
[summary]: #summary

NixOS is released twice a year; the current release schedule targets March
and September for the release months. However, trying to provide a polished
desktop-user experience is difficult and moving the target release months to
May and November should minimize the amount of in-house work needed to
cut a release.

# Motivation
[motivation]: #motivation

By changing our release dates to follow those of certain upstream projects,
we could reduce the amount of issues we encounter during stabilization.
In particular, GNOME and KDE Plasma both have a release in September, which
allows ample time for NixOS contributors to package and stabilize the
desktop managers before the November release. For the May release, GNOME will
have a similar stabilization period; while Plasma, which has a four month
release cadence, will have a slightly older but still supported non-LTS
release. Using LTS releases is not feasible as there is no guarantee that
they will be compatible with the version of systemd during branch-off.

The current March and September release months may be the worst months for
GNOME and Plasma, as the release available during stabilization would be
End-of-Life a few weeks after the target release date. Also, this period marks
the greatest potential dependency "drift" from development on unstable. For example,
many of the 20.09 release blockers were related to issues with systemd-246 and plasma-5.18,
however, plasma-5.19 and the yet-released 5.20 both supported systemd-246 with
zero additional effort.

Choosing branch-off points in master where the major desktop manager use
cases should be well stabilized will allow for release stabilization to
focus on failing builds and minor issues.

## Core changes

The 21.03 release will be delayed until 21.05, and the current 20.09 release
will be supported until June 2021. After the initial 21.05 release, all subsequent
releases will occur six months apart following a YY.05 and YY.11 convention.

# Drawbacks
[drawbacks]: #drawbacks

There will be some initial confusion with stable users as to why the 21.03
release was delayed.

# Alternatives
[alternatives]: #alternatives

## Maintain the status quo regarding release dates

We could keep the release dates in March and September. However, we
would need some other way to minimize the work and risk from trying to
provide a polished experience for 60,000+ packages, 17 desktop managers,
and 30+ window managers.

# Future work
[future]: #future-work

- Update .version on master to 21.05
- Update unstable osinfo-db entry to 21.05pre
- Document the release schedule in the NixOS manual.
- Announce the various deadlines on the mailing list (Discourse).
