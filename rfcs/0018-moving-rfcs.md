---
feature: Moving forward RFCs
start-date: 2017-10-15
author: Leo Gaspard (@Ekleog)
co-authors: (find a buddy later to help our with the RFC)
related-issues: --
---

# Summary
[summary]: #summary

Decide whether the RFC should be merged or not when debate dries up.

# Motivation
[motivation]: #motivation

RFCs are currently in the following status:
 * 4 waiting for something unknown (RFC5 reads as “ok to go” to me, RFC11 reads
as mostly negative comments to me, RFC12 I am biased for being the author though
I don't know what to do next for a decision to be reached, RFC17 looks “ok to
go” to me),
 * 4 waiting for the author (RFC3, RFC8, RFC14, RFC17),
 * 2 accepted (RFC1 doesn't really count, RFC4, RFC15), and
 * 2 stalled in debate (RFC9, RFC10))
 * 1 closed (RFC6 which, incidentally, has not been rejected as per RFC1)

The aim of this PR is to give an explicit status to the 4 waiting PRs, and not
have 10 open PRs with no clue as to what is the next step.

# Detailed design
[design]: #detailed-design

A team of people should be designated as “responsible for pushing RFCs forward”.
For example, it is possible to pick the team of people with push rights on the
RFCs repository. The members of this team should be explicitly listed in the
RFCs repository's README.

Two weeks after the last comment, someone from this team not personally involved
in the PR should review the comments, and decide of a status to give it among
the following ones:
 * Accepted
 * Rejected
 * Waiting for changes from the author
 * Waiting for information from anyone

Depending on the choice of status, the following action will then be taken by
the reviewer:
 * Accepted or rejected: Post a comment stating the decision along with a call
   for serious not-answered-before objections, with a two-weeks delay until
   application of the decision. Also add a `final-comments` tag
 * Waiting for changes from the author: Add a `waiting-for-edits` tag and
   recapitulate the requested changes in a comment on the PR
 * Waiting for information from anyone: Add a `waiting-for-information` tag and
   recapitulate the unanswered questions in a comment on the PR

## Examples
[examples]: #examples

For example, were I member of the said team, here are the decisions I would have
taken after the visit to all the PRs I just did to write this one (note: I
reviewed them quickly for I was reviewing them all at once, there could be
mistakes in this list):
 * RFC3: Waiting for information
   (https://github.com/NixOS/rfcs/pull/3#issuecomment-291546550,
   https://github.com/NixOS/rfcs/pull/3#issuecomment-312644253)
 * RFC5: Accept
 * RFC6: Reject (explicitly, so it ends up in the rejected/ folder)
 * RFC8: Waiting for changes
   (https://github.com/NixOS/rfcs/pull/8#issuecomment-312489557)
 * RFC9: Waiting for information (from @edolstra to either agree or disagree)
 * RFC10: Accept (though I'd most likely ask for someone else in the team for
   their reading of the comments, but there seem to be no unanswered criticism
   of it to me)
 * RFC11: Reject (especially given
   https://github.com/NixOS/rfcs/pull/11#issuecomment-292996438)
 * RFC12: Call for someone else of the team, since I am personally involved in
   this PR
 * RFC13: Waiting for changes (see the TODOs in the RFC)
 * RFC14: Waiting for changes
   (https://github.com/NixOS/rfcs/pull/14#issuecomment-312444984)
 * RFC17: Waiting for information
   (https://github.com/NixOS/rfcs/pull/17#discussion_r132817106) and waiting for
   changes (https://github.com/NixOS/rfcs/pull/17#discussion_r132816993)

# Drawbacks
[drawbacks]: #drawbacks

This would put some work on the team responsible for reviewing the RFCs.

# Alternatives
[alternatives]: #alternatives

Not doing anything is the only alternative I could think of, and the experiment
up to now isn't really successful.

# Unresolved questions
[unresolved]: #unresolved-questions

 * Who should be in the team responsible for reviewing PRs?
 * Does Github have labels that will be automatically removed by any subsequent
   comment on the PR, so that it's easier for a reviewer to see which PRs to
   review? (the list would then be the list of PRs with no comment for 2 weeks
   and no label attached)

# Future work
[future]: #future-work

None known.
