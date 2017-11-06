---
feature: pr-testing
start-date: 2017-11-06
author: @globin
co-authors: (find a buddy later to help out with the RFC)
related-issues: https://github.com/NixOS/hydra/pull/516 https://github.com/mayflower/nixborg
---

# Summary
[summary]: #summary

In order to properly test Pull Requests and reduce the maintainers' workload
we need automation to build PRs on Hydra. This RFC specifies an architecture
to achieve this and contains a reference implementation.

# Motivation
[motivation]: #motivation

We currently have peaks of ~70 PRs a month at release time, this consumes an
immense amount of maintainers' time to test the PRs.

Another issue is the difficulty of testing mass-rebuilds. Only a few people
have resources for themselves to test such computation intensive builds and
Hydra access is limited to only a small amount of people.

Due to having already built all packages prior to merging this would reduce
the need for staging.

# Detailed design
[design]: #detailed-design

The general idea is to have a service which receives webhooks from github,
then requires some acknowledgement of a maintainer to build/test a PR and
subsequently schedules a jobset on Hydra.

## Details of the reference implementation at https://github.com/mayflower/nixborg
(to be moved to the NixOS github organisation if accepted)

The current implementation consists of three seperate services:
 - nixborg: flask app to receive github hooks and fill a queue (currently redis, probably switching to rabbitmq in the future)
 - nixborg-workers: workers consuming the queue, doing the git handling, commenting on github, HTTP requesting to nixbot-receiver
 - nixbot-receiver: stdlib-dependency-only python script to be run on Hydra that calls out to hydra-update-jobset (PR: https://github.com/NixOS/hydra/pull/516)

1. the main service `nixborg` listens for `issue_comment` hooks containing `@nixborg build`
2. `nixborg` passes the hook on to the `nixborg-workers`
3. a `nixborg-worker` rebases the PR on the base branch of the PR (mainly master, staging or release-XX.XX)
4. the rebased branch gets pushed to a `pr-XXXXX` branch
5. a `nixborg-worker` HTTP calls out to the `nixbot-receiver` on Hydra with all necessary information for a jobset; this message is HMAC authenticated
6. `nixbot-receiver` passes on the information to create/update a jobset `pr-XXXXX` with the newly implemented `hydra-update-jobset` CLI utility

Some small remarks on the architecture:
 - the rebasing is done in order to:
   - make sure Hydra builds a commit that has been reviewed by a maintainer
   - ensure an older PR is tested based on the current state of the base branch
 - `nixbot-receiver` is implemented as a stdlib-dependency-only python script not doing any logic to have a stable interface to Hydra that doesn't need to be updated
    often, when iterating on nixborg and to not have a large footprint (cpu, memory, disk space)

# Alternatives
[alternatives]: #alternatives

 - The Hydra jobset management could be achieved by using declarative jobsets, this does not work out currently as jobsets cannot be compared across projects
 - [bors](https://bors.tech/) is the bot the Rust developers use to automate their testing with buildbot. It would have to be adapted to call out to Hydra
   and currently AFAIK is not that easy to run yourself, when not using heroku. A lot of nixborg is inspired by bors.

# Unresolved questions
[unresolved]: #unresolved-questions

 - Which "release.nix" should be used to test:
   - We probably want to test aarch64 and x86_64-darwin, not only x86_64-linux, as only a little number of maintainers/pull requesters have access to these architectures.
   - We probably want to also test NixOS module tests, especially for PRs touching these
 - Can Hydra handle the additional workload by this, we probably have to start with a small number of PRs being tested to evaluate this.

# Future work
[future]: #future-work

 - "Rollup testing": Rebase a small number of PRs ontop of each other to reduce jobset creation and speedup testing
 - With the addition of a webhook sent by Hydra and machine-readable status reporting by Hydra this can be extended to automatically merge PRs
 - This can be combined with [drafted RFC #19, MAINTAINERS file and utility](https://github.com/NixOS/rfcs/pull/19) to allow maintainers that aren't GH org members test PRs
   that only touch packages they maintain.
 - A mentionbot (also see drafted RFC #19) could be handled by nixborg

# Drawbacks
[drawbacks]: #drawbacks

 - Higher load on Hydra
