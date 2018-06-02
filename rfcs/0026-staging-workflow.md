---
feature: (fill me in with a unique ident, my_awesome_feature)
start-date: (fill me in with today's date, YYYY-MM-DD)
author: (name of the main author)
co-authors: (find a buddy later to help our with the RFC)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Define a new workflow for the `staging` branch that can better accomodate the
current and future influx of changes in order to deliver mass-rebuilds faster to
master. As part of this new workflow an additional branch, `staging-next`, shall
be introduced.


# Motivation
[motivation]: #motivation

The current workflow cannot handle the high amount of mass-rebuilds that are
continuously delivered, resulting in long delays for these deliveries to reach
`master`. When a certain delivery causes failures, attemps are typically made to
fix these failures and stabilize `staging` so that the specific delivery can still
reach `master`.

Often it happens that during this period of stabilization other mass-rebuilds
are submitted, and it is not uncommon that these also introduce failures, thus
again increasing the time it takes for a delivery to reach `master`. This is
especially worrysome in case of security fixes that need to be delivered as soon
as possible.

# Detailed design
[design]: #detailed-design

There shall be the following branches:
- `master` is the main branch and all small deliveries shall go here;
- `staging` is branched from `master` and mass-rebuilds and other large deliveries go to this branch;
- `staging-next` is branched from `staging` and only fixes to stabilize and security fixes shall be delivered to this branch.

Binary packages shall be build by Hydra for each of these branches. The
following table gives an overview of the branches, the check interval in hours,
amount of shares, and the jobset that they build.


| Branch         | Interval | Shares | Jobset
|----------------|----------|--------|-----------
| `master`       | 4        | High   | release.nix
| `staging`      | 12       | High   | release.nix
| `staging-next` | 6        | High   | release-small.nix


The check interval of `staging` is reduced from 24 hours to 12 hours. This can
be done because only stabilization fixes shall be submitted and thus fewer
rebuilds shall typically have to be performed. The `staging-next` shall have a
short interval of only 6 hours. This is done because of the relatively small
jobset, and to obtain a higher resolution to detect any troublesome deliveries.


# Drawbacks
[drawbacks]: #drawbacks

A potential drawback of this new workflow is that the additional branch may be considered complicated and/or more difficult to work with.

# Alternatives
[alternatives]: #alternatives

What other designs have been considered? What is the impact of not doing this?

# Unresolved questions
[unresolved]: #unresolved-questions

- The exact amount of shares, which is something that has the be found out.

# Future work
[future]: #future-work

-