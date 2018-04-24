---
feature: nix-release-model
start-date: 2018-03-28
author: Shea Levy <shea@shealevy.com>
co-authors: Michael Raskin <7c6f434c@mail.ru> (any other Nix committers on-board?)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

A model of when, what, and how to make new releases of Nix.

# Motivation
[motivation]: #motivation

We want to set clear expectations for users, provide guidance for
developers, and provide both groups the benefits of easy availability
of new improvements.

# Detailed design
[design]: #detailed-design

The proposed process contains a number of interrelated components.
I've numbered them for ease of reference and discussion, not to
indicate any meaningful ordering. Any aspect of this can be suspended
at the security team's discretion when handling a vulnerability, or at
the core team's discretion for especially destructive bugs (e.g. data
corruption).

1. Before merging to `master`, require testing, documentation,
   changelog entries, removal of WIP markers, etc. to keep `master`
   somewhat stable, maintain bisectability, and shorten the release
   preparation process. This includes both objective and subjective
   components, and will always involve something of a judgment call.
2. The Nix core team shall decide when a new release is warranted,
   through its normal decision procedures. That decision will also
   include designating a release manager for the release. The specific
   conditions for a release being warranted are intentionally out of
   scope of this RFC, but it is expected that the core team will
   balance both the needs of the community at large and the needs of
   developers working on Nix and the tradeoff between stability and
   development progress. In particular, if an especially major change
   has landed recently or is nearing readiness, the core team should
   either mark the release point as being before the relevant change
   or expect more stabilization work than normal.
3. The release manager will branch off a `#-maintenance` branch
   (e.g. `2.1-maintenance`) in advance of any mainline release. A
   mainline release is a release that is a direct git ancestor of
   `master` and is, in the relevant feature and bugfix senses, "ahead"
   of all other releases at the time it is made.
4. Changes aimed at getting the release ready (fixing bugs, improving
   docs, etc.) should target the `#-maintenance` branch and then
   be merged forward into `master`. Normally, during the stabilization 
   phase the '#-maintenance' branch should be merged into `master` 
   soon after each set of commits. This implies that especially large 
   changes ready around a release should either be included before
   branch-off (with extra time to stabilize the new feature) or 
   should, if possible, wait to be merged to `master` until after the
   release. Which path is taken should be a collaboration between the
   release manager and the developers of the change in question.
5. New development unrelated to the new release can go directly into
   `master` in parallel with a release stabilization.
6. During stabilization, the release manager should update
   `nixUnstable` to point to various commits of the `#-maintenance`
   branch, to easily enable wider testing and integration.
7. When the release manager determines readiness, the relevant commit
   is announced to the community. Barring objections or last-minute
   fixes judged valid by the release manager (or core team), the
   commit is tagged and the branch goes into the maintenance phase.
   Readiness is a judgment call, and should require increased
   scrutiny/validation for a release with more complex/major changes.
8. So long as no new feature work has yet happened on `master`,
   `master` should be kept equal with the most recent `#-maintenance`
   branch (through fast-forwards, not cherry-picks). Once new feature
   work occurs, the semver minor (or major) versions are bumped and
   normal development continues against `master`. This allows us to
   maintain the "no patch release without a corresponding mainline
   release" invariant (see point 12 below) while still allowing patch
   releases to happen on the appropriate `#-maintenance` branch.
9. Associated with each `NixOS` stable release is an associated
   `maintained` series of `Nix`, with the same support lifetime as
    the stable release.
10. Any important bugfix can be cherry-picked from `master` to a
    `#-maintenance` branch of a supported `maintained` series at any
    committer's discretion.
11. In rare cases, if a change truly only makes sense on a
    `#-maintenance` branch (e.g. when we added support to `1.11` to
    be able to work with a `2.0` database schema) it can be targeted
    directly to the `#-maintenance` branch. This should be avoided if
    possible and subject to especially careful testing and review.
12. A maintenance release can be tagged off of the `#-maintenance`
    branch at any time *after* there is a mainline release that
    contains all of the fixes included in the desired maintenance
    release, at the discretion of the Nix core team. If for there is
    also a newer `#-maintenance branch`, it should also be released 
    before (or simultaneously with) the older one. This implies that
    maintenance releases may be tagged off of commits behind the tip
    of the maintenance branch, if the latest commits haven't been
    included in a mainline release.

# Drawbacks
[drawbacks]: #drawbacks

The main drawback to having a formalized model in general is our model
may not match a reasonable productive process in practice and so may
lead to obnoxious busy work or delays for no purpose.

The drawbacks of this specific model are a bit hard to see without
putting it into practice. One thing that seems apparent is there is a
non-trivial amount of complexity (12 bullet points!) which could
perhaps be reduced. It also may prove difficult under this model to
develop especially large features, as without the right development
practices (e.g. feature flags on `master`) this can tend to create
new long-lived branches that can effectively become the new `master`.

# Alternatives
[alternatives]: #alternatives

If we don't do anything at all, we are likely to have more long-lived
unreleased branches and significant undertested divergence, as well as
lack of guidance/clear policy for the Core team to handle release
requests.

This model is a synthesis of a [discussion] on the nix-core mailing
list, some other concrete designs can be seen there. Additionally, it
has evolved through the discussion on the [PR].

[discussion]: https://groups.google.com/forum/#!msg/nix-core/9L7jZ9W8VGc/8LaBUc_tBQAJ
[PR]: https://github.com/NixOS/rfcs/pull/28

# Unresolved questions
[unresolved]: #unresolved-questions

What specific criteria should the Nix core team use when deciding to
start a release process?

# Future work
[future]: #future-work

CI, both to ensure `master` is working and to ensure actively
maintained series can build and install `master`.

Streamlined responsive code review practices, ideally to the point of
allowing low-friction branch protection.

Interface descriptions and guarantees suitable to semver.

We may in the future decouple maintenance support from the `NixOS`
release cycle. Any work which involves splitting components out of
`Nix` or breaking `Nix` itself up into components will also need to
keep this in mind.

Automated testing of semver bounds could be nice. Newer versions
running older testsuites, alternating new and old versions running
operations on the same store, old versions running all new versions
testsuites except tests explicitly marked as being bugfixes since
then, etc.

Explicit guidelines/process around developing major features without
long-lived branches or mainline instability.

Some kind of policy around reversions, particularly when the process
described here is accidentally violated, would be helpful.
