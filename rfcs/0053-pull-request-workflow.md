---
feature: pull-request workflow
start-date: 2019-09-28
author: Ingolf Wagner (@mrVanDalo)
co-authors: lassulus (@lassulus)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: 
---

# Summary
[summary]: #summary

Pull-Request on GitHub are the main way we improve our code base.
This Document should settle everything that needs to be done
to bring code upstream in the
[Nixpkgs Repository](https://github.com/nixos/nixpkgs/).

# Motivation
[motivation]: #motivation

Eliminate questions from contributors and maintainers
about what should be done next and who should do it.
This is not a new approach, it is more a settlement
on how we do it now.

# Detailed design
[design]: #detailed-design

Define all steps of a Pull-Request.
Use Roles to define responsibilities in every step.

## Roles
[roles]: #roles

Everybody involved in the process of contributing has one or multiple
of the following roles

* Contributor
* Bot
* Reviewer
* Maintainer (has merge privileges)

The responsibilities of theses roles are defined in the rest of this RFC.

## States of a Pull-Request
[state]:#states

This diagram defines all states of a Pull-Request,
and their transitions to other states.

![pull-request state](0053-pull-request-workflow/pull-request-states.svg)

## Responsibilities and Actions
[responsibilities]:#responsibilities

The responsibilities of every role is defined by the following diagram:

![pull-request activity](0053-pull-request-workflow/pull-request-roles.svg)

## About Pull-Request

### Packages

* contributor must decide if a Backport is necessary
* after the Pull-Request to `master`, `staging` or `staging-next` is merged,
  the Backport Pull-Request is created
* Backport Pull-Requests must be linked to the original Pull-Requests (using `git cherry-pick -x`).
* reviewer and maintainer can deny the Backport

### Modules

* modules should have tests
* new modules must have tests
* modules should not be Backported
* Backports of modules must be pretty good argued.

## Links

* [How to write Module Tests](https://nixos.org/nixos/manual/index.html#sec-nixos-tests)
* [Contribution Guidelines](https://github.com/NixOS/nixpkgs/blob/master/.github/CONTRIBUTING.md)

# Unresolved questions
[unresolved]: #unresolved-questions

* The Pull-Request of a Backport should be created by the bot.
  But if that is the case, the original contributor might not be able
  to make changes on the branch behind the Pull-Request.
* Backports without changes in master are not discussed.
  for example security patches that only affect older versions in stable.

# Future work
[future]: #future-work

* The Pull-Request template needs an option "Backport needed?"
* Add a link to this document in the 
  [Contribution Guidelines](https://github.com/NixOS/nixpkgs/blob/master/.github/CONTRIBUTING.md)
