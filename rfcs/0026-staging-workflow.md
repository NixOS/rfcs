---
feature: staging-workflow
start-date: 2018-03-05
author: Vladimír Čunát (@vcunat)
co-authors: Frederik Rietdijk (@FRidh)
related-issues:
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
- `master` is the main branch where all small deliveries go;
- `staging` is branched from `master` and mass-rebuilds and other large deliveries go to this branch;
- `staging-next` is branched from `staging` and only fixes to stabilize and security fixes shall be delivered to this branch. This branch shall be merged into `master` when deemed of sufficiently high quality.

Binary packages shall be build by Hydra for each of these branches. The
following table gives an overview of the branches, the check interval in hours,
amount of shares, and the jobset that they build.


| Branch         | Interval | Shares | Jobset
|----------------|----------|--------|-----------
| `master`       | 4        | High   | release.nix
| `staging-next` | 12       | Medium | release.nix
| `staging`      | 6        | Medium | release-small.nix


The check interval of `staging-next` is reduced from 24 hours (the current value
for `staging`) to 12 hours. This can be done because only stabilization fixes
shall be submitted and thus fewer rebuilds shall typically have to be performed.

The `staging` branch shall have a short interval of only 6 hours. This is because
of the relatively small jobset, and to obtain a higher resolution to detect any
troublesome deliveries.

# Drawbacks
[drawbacks]: #drawbacks

A potential drawback of this new workflow is that the additional branch may be
considered complicated and/or more difficult to work with. However, for most
contributors the workflow will remain the same, that is, choose `master` or
`staging` depending on the number of rebuilds.

# Alternatives
[alternatives]: #alternatives

## Maintain the status quo

The current situation could be kept, however, that would not solve any of the
issues mentioned in the "Motivation" section.

## Single branch

Instead of multiple branches only a single branch, say `master`, could be kept
for development. While this removes the issue of merge conflicts, it will result
in continuous mass-rebuilds on `master`, slowing down the delivery of binary
substitutes and thus development.

## Reduce Hydra jobset size

Reducing the size of the Hydra jobset would mean the iteration pace could be
higher, but has the downside of testing fewer packages, and having fewer binary
substitutes available.

The part about fewer binary substitutes could be partially mitigated by adding
another slower larger jobset that wouldn't block the channel.

# Unresolved questions
[unresolved]: #unresolved-questions

- The exact amount of shares, which is something that has the be found out.

# Future work
[future]: #future-work

- Document the new workflow;
- Create the new branch;
- Create a Hydra jobset for the new branch and adjust the existing jobs.
