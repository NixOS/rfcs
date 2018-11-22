---
feature: rfc-process-team-amendment
start-date: 2018-10-27
author: Robin Gloster <mail@glob.in>
co-authors: Graham Christensen <graham@grahamc.com>
related-issues: 1 (initial process), 24 (implementation)
---

# Summary
[summary]: #summary

This RFC proposes an RFC Steering Committee who decide on a group of RFC
shepherds for each RFC who guide the discussion to a general consensus and then
propose a motion for a "Final Comment Period" (FCP) with a disposition for
acception, rejection or postponing. (see Glossary for a short definition of
these terms)


# Motivation
[motivation]: #motivation

A lot of RFCs have stalled and already an [RFC has been submitted exactly on
this topic](https://github.com/NixOS/rfcs/pull/18), which ironically has not
been decided on either. This new RFC takes the above into account and tries to
expand on that to flesh out the process further. During this effort a lot of
inspiration has been taken from [Rust's RFC
process](https://github.com/rust-lang/rfcs#what-the-process-is) which works well
and we have adapted to our needs.


# Detailed design
[design]: #detailed-design

## Glossary

##### RFC Steering Committee
A team of people defined by _this_ RFC and stays consistent until the team
members are changed via a follow-up RFC. This committee is responsible for
forming an RFC Shepherd team from the available nominations on each RFC. This
team also names the leader of the Shepherd team. This has to happen within 1
week after the PR has been opened. Until then the Steering Committee is
responsible for guiding the discussion. In case of the Shepherding Team not
doing its work the Steering Committee shall encourage them or step in and assign
new Shepherds. They also are in charge of merging accepted and rejected RFCs.
Generally by these expectations they should find time to meet once a week for
about an hour.

##### Shepherd
A team of 3-4 community members defined unanimously by the RFC Steering
Committee, responsible for accepting or rejecting RFCs. This team is created per
RFC from community members nominated in the discussion on that RFC.

This team should be people who are very familiar with the main components
touched by the RFC.

##### Leader
The Shepherd Leader is in charge of the RFC process for a specific RFC, and is
responsible for ensuring the process is followed in a timely fashion. 


## Process from Creation to Merge

*In short, to get a major change included in Nix or nixpkgs, one must
first get the RFC merged into the RFC repository as a markdown file under the
`accepted` directory. At that point the RFC is accepted and may be implemented
with the goal of eventual inclusion into Nix or nixpkgs.*

0. Have a cool idea!
1. Find a co-author. A co-author is critical to making sure your RFC is viable
   and will receive support. Your co-author helps flesh out the RFC, and should
   also support the RFC.
2. Fill in the RFC. Put care into the details: RFCs that do not present
   convincing motivation, demonstrate understanding of the impact of the design,
   or are disingenuous about the drawbacks or alternatives tend to be
   poorly-received. You might want to create a PR in your fork of the RFCs
   report to help you flesh it out with a few supporters or chat/video
   conference with a few people involved in the topic of the RFC.
3. Submit a pull request. As a pull request the RFC will receive design feedback
   from the larger community, and the author should be prepared to revise it in
   response.
4. For the nomination process for potential members of the RFC Shepherd Team,
   that is specific to each RFC, anyone interested can either nominate another
   person or themselves to be a potential member of the RFC Shepherd Team. This
   can already be done when submitting the PR.
5. The RFC Steering Committee assigns a subset of the nominees to the RFC
   Shepherd Team and designates a leader for it. This has to be done
   unanimously.
6. Build consensus and integrate feedback. RFCs that have broad support are much
   more likely to make progress than those that don't receive any comments. Feel
   free to reach out to the RFC Shepherd Team leader in particular to get help
   identifying stakeholders and obstacles. We would like to encourage reviewers
   to only make comments on the content of the RFC and reach out to the author
   directly (via IRC, e-mail, etc.) for wording or typos.
7. The RFC Shepherd Team will discuss the RFC pull request, as much as possible
   in the comment thread of the pull request itself. Discussion outside of the
   pull request, either offline or in a video conference, that might be
   preferable to get to a solution for complex issues, will be summarized on the
   pull request comment thread.
8. RFCs rarely go through this process unchanged, especially as alternatives and
   drawbacks are shown. You can make edits, big and small, to the RFC to clarify
   or change the design, but make changes as new commits to the pull request,
   and leave a comment on the pull request explaining your changes.
   Specifically, do not squash or rebase commits after they are visible on the
   pull request.
9. At some point, a member of the RFC Shepherd Team will propose a "motion for
final comment period" (FCP), along with a disposition for the RFC (merge, close,
or postpone).
    * This step is taken when enough of the tradeoffs have been discussed that
      the RFC Shepherd Team is in a position to make a decision. That does not
      require consensus amongst all participants in the RFC thread (which is
      usually impossible). However, the argument supporting the disposition on
      the RFC needs to have already been clearly articulated, and there should
      not be a strong consensus against that position outside of the RFC
      Shepherd Team. RFC Shepherd Team members use their best judgment in taking
      this step, and the FCP itself ensures there is ample time and notification
      for stakeholders to push back if it is made prematurely.
    * For RFCs with lengthy discussion, the motion to FCP is usually preceded by
      a summary comment trying to lay out the current state of the discussion
      and major tradeoffs/points of disagreement.
    * Before actually entering FCP, all members of the RFC Shepherd Team must
      sign off the motion.
10. The FCP lasts ten calendar days, so that it is open for at least 5 business
days. It is also advertised widely, e.g. in NixOS Weekly and through Discourse
announcements. This way all stakeholders have a chance to lodge any final
objections before a decision is reached.
11. In most cases, the FCP period is quiet, and the RFC is either merged or
closed. However, sometimes substantial new arguments or ideas are raised, the
FCP is canceled, and the RFC goes back into development mode.
12. In case of acceptance, the RFC Steering Committee merges the PR into the
`accepted`, in case of rejection into the `rejected` directory.


![RFC Process](./0036-rfc-process.png)
![Review Process](./0036-review-process.png)


## The RFC life-cycle

Once an RFC is accepted the authors may implement it and submit the feature as a
pull request to the Nix or nixpkgs repo. Being accepted is not a rubber stamp,
and in particular still does not mean the feature will ultimately be merged; it
does mean that in principle all the major stakeholders have agreed to the
feature and are amenable to merging it.

Furthermore, the fact that a given RFC has been accepted implies nothing about
what priority is assigned to its implementation, nor does it imply anything
about whether a Nix/nixpkgs developer has been assigned the task of implementing
the feature. While it is not necessary that the author of the RFC also write the
implementation, it is by far the most effective way to see an RFC through to
completion: authors should not expect that other project developers will take on
responsibility for implementing their accepted feature.

Minor modifications to accepted RFCs can be done in follow-up pull requests. We
strive to write each RFC in a manner that it will reflect the final design of
the feature; but the nature of the process means that we cannot expect every
merged RFC to actually reflect what the end result will be after implementation.

In general, once accepted, RFCs should not be substantially changed. Only very
minor changes should be submitted as amendments. More substantial changes should
be new RFCs, with a note added to the original RFC. Exactly what counts as a
"very minor change" is up to the RFC Shepherd Team of the RFC to be amended, to
be decided in cooperation with the RFC Steering Committee.


## Members of the RFC Steering Committee

In cooperation and discussion with Eelco Dolstra and all nominees the proposal
for the first iteration of members of the RFC Steering Committee are:

 - Eelco Dolstra (edolstra, niksnut)
 - Shea Levy (shlevy)
 - Domen Kožar (domenkozar)
 - Jörg Thalheim (Mic92)
 - Robin Gloster (globin)


# Drawbacks
[drawbacks]: #drawbacks

If the Steering Committee were too biased, it might select a biased Shepherding
Team. We are hoping for them and believe them to commit to doing their work in
the interest of the community. Also this RFC introduces more process and
bureaucracy, and requires more meetings for some core Nix/nixpkgs contributors.
Precious time and energy will need to be devoted to discussions.

# Alternatives
[alternatives]: #alternatives

The current state, which hardly ever results in an RFC being accepted.

# Unresolved questions
[unresolved]: #unresolved-questions

None, as of now.

# Future work
[future]: #future-work

Work on auto-labeling RFCs and automation of parts of the process that either do
not need human intervention or to remind people to continue their work.

Define how the Steering Committee is picked in the future.
