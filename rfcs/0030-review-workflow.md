---
feature: review_workflow
start-date: 2018-08-12
author: Timo Kaufmann
co-authors: (find a buddy later to help our with the RFC)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Formalize a standard workflow for pull-request review and the lifecycle of a
pull request.

# Motivation
[motivation]: #motivation

Currently, there is not much process to PR-reviews. Basically some people go
through recent PRs regularly and review them. That has various drawbacks:

1. PRs can get lost if nobody reviews them in time and they end up too deep in
  the list of recent PRs

2. PRs can be forgotten in the middle of the review cycle. Then the PR is already
  too old to be discovered and additionally already has a lot of discussion,
  making it look "handled"

3. Reviews of people without commit access are discouraged. When those people
  review a PR, they essentially *lower* its chances to be merged because of
  the same reason: by the time they are ready to merge, they look "handled" and
  are less likely to get the attention of somebody with commit access.

4. It is hard to judge how many PRs actually need to be reviewed at the moment.
  That kind of statistic would be interesting.

# Detailed design
[design]: #detailed-design

## PR states

Inspired by the [sage trac](https://trac.sagemath.org/query?desc=1&order=id&group=status&status=!closed&summary=~upgrad&or&status=!closed&summary=~updat),
I propose that we introduce a set of states a PR might be in. Every PR has to
be assigned to exactly one of these states and might change between these states
regularly. The most important states would be `needs:work` and `needs:review`.
`needs:work` means that the PR is not ready to be merged as-is and needs to be
improved. `needs:review` means that all the work is done and somebody (usually
the PR creator) thinks that it should be ready for merge. Reviewers (with or
without commit access) can then go through the list of `needs:review` PRs and
review them. They can than either request changes and set the state to
`needs:work` or merge the PR. In case of review by non-commiters, we could
introduce an additional state like `needs:merge`. Reviewing and merging those
PRs should then take little time for the committers and could double as a sort
of training program for potential new committers.

## Tooling

This workflow is not currently possible due to GitHub's restrictions. Namely
only people with commit access can set tags on a PR. This can be resolved
through tooling. Work on this is [in progress](https://github.com/NixOS/ofborg/pull/216).

The tooling should then initialize the PR status on new PRs. In general this
is going to be `needs:review`. One exception of this are PRs that are work in
progress (indicated by a `WIP` tag in the title). Those should start at
`needs:work`. Other exceptions may include RFC type PRs, which may warrant their
own state (`needs:opinions`?).

To reduce friction for new contributors, the tooling could later be expaned
to explain this process to first time contributors.

## Advantages

All the above issues should be resolved by this:

1. There is no reason anymore to preferably review recent PRs. Before, recent
   commit were the only ones where one can be sure that they are not reviewed
   yet (and thus in a `needs:work` state). Now, reviewers can randomly choose
   and `needs:review` PR.

2. Similarly, the reviewer may change at any time. If the first reviewer forgets
   or loses interest in a PR, the PR will just end up in the `needs:review` list
   again and can easily find a new reviewer.

3. People without commit access can help reviewing commits and lessen the load
   on committers without putting the reviewed PRs at a disadvantage.

4. We can easily gather statistics. In the long run, we might even implement
   some sort of automated triage where we regularly ping `needs:work` PRs and
   close them after the authors went unresponsive for a while. Or we could
   tag them as `needs:takeover`. But this is out of scope.


An example PR might go like this. `contributor` creates the PR, `reviewer1`
reviews without commit access, `reviewer2` reviews with commit access.

> contributor: hello: 42.0 -> 43.0 [PR text]

[the bot automatically sets the new PR to `needs:review`]

> reviewer1: Looks good to me. Just one little nitpick: Please add a waving emoji to the name.
> @GrahamcOfBorg status needs:work

> contributor: Good point, more emojis are always good. Done.
> @GrahamcOfBorg status needs:review

> reviewer1: Thanks! I think this is ready for merge.
> @GrahamcOfBorg status needs:merge

> reviewer2: LGTM
> @GrahamcOfBorg build-and-merge

# Drawbacks
[drawbacks]: #drawbacks

- Contributing would be a bit more complicated. There is one more bit of
  knowledge new contributors need. It is possible that some contributors forget
  to set the PR to `needs:review` again after a fixup. That might be resolved
  by some form of automatic triage as explained above. It would also be not much
  than the current status, since the first reviewer will still be notified by
  GitHub.

- We rely even more on the tooling than we do now. However the general workflow
  should be portable to different tooling and might even work better there.

# Alternatives
[alternatives]: #alternatives

- Move to a different issue tracker. That would be a great effort and most
  more powerful issue trackers would also be unfamiliar to new contributors,
  discouraging drive-by contributors.

- Do nothing. All the issues mentioned in the motivation remain unsolved.

# Unresolved questions
[unresolved]: #unresolved-questions

- List the exact states. We should probably start simple and evolve from there.

- Finish the tooling.

- Write documentation. It should at least be explained in `CONTRIBUTING.md`,
  maybe a greeting bot explaining it to first time contributors would be even
  better.

# Future work
[future]: #future-work

Re-evaluate if the workflow had the predicted benefits.
