---
feature: Defined conventions around testing of official Nixpkgs packages.
start-date: 2021-12-29
author: Jonathan Ringer
co-authors:
shepherd-team:
shepherd-leader:
related-issues:
  - [RFC 0088 - Nixpkgs Breaking Change Policy](https://github.com/NixOS/rfcs/pull/88)
---

# Summary
[summary]: #summary

When updating or modifying packages, several conventions for testing regressions
have been adopted. However, these practices are not standard, and generally it's not well
defined how each testing method should be implemented. It would be beneficial to have
an unambiguous way to say that a given package, and all downstream dependencies, have
had as many automated test ran possible. This will give a high degree of certainty that
a given change is less likely to manifest regressions once introduced on a release
channel.

Another desire of this rfc is also to have a way for various review tools
(e.g. ofborg, hydra, nixpkgs-review) to have a standard way to determine if a
package has additional tests which can help verify its correctness.

# Motivation
[motivation]: #motivation

Breakages are a constant painpoint for nixpkgs. It is a very poor user experience to
have a configuration broken because one or more packages fail to build. Often when
these breakages occur, it is because the change had a large impact on the entirety
of nixpkgs; and unless there's a dedicated hydra jobset for the pull request, it's
infeasible to expect pull request authors to verify every package affected
by a change they are proposing. However, it is feasible to specify packages that
are very likely to be affected by changes in another package, and use this information
to help mitigate regressions from appearing in release channels.

# Detailed design
[design]: #detailed-design

Standardize `passthru.tests.<name>` and `passthru.nixosTests.<name>` as a mechanism of 
more expensive but automatic testing for nixpkgs. As well as encourage the usage of
`checkPhase` or `installCheckPhase` when packaging within nixpkgs.

Usage for `passthru.nixosTests.<name>`
- Reserved for tests utilitizing the nixosTest utilties.
  - Generally these are more resource intensive, and may require additional system features
  such as kvm

Usage for `passthru.tests.<name>`:
- Running tests which include downstream dependencies.
  - This avoids cyclic dependency issues for test suites.
- Running lengthy or more resource expensive tests.
  - There should be a priority on making package builds as short as possible.
  - This reduces the amount of compute required for everyone reviewing, building, or iterating on packages.
- Referencing downstream dependencies which are most likely to experience regressions.
  - Most applicable to [RFC 0088 - Nixpkgs Breaking Change Policy](https://github.com/NixOS/rfcs/pull/88),
as this will help define what breakages a pull request author should take ownership.

Usage for mkDerivation's `checkPhase`:
- Quick "cheap" tests, which run units tests and maybe some addtional scenarios.
- Since this contributes to the "build time" of a package, there should be some
emphasis on ensuring this phase isn't bloated.

Usage for mkDerivations `installCheckPhase`:
- A quick trivial example (e.g. `<command> --help`) to demonstrate that one (or more)
of the programs were linked correctly.
- Assert behavior post installation (e.g. python's native extensions only get installed
and are not present in a build directory)

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

This section illustrates the detailed design. This section should clarify all
confusion the reader has from the previous sections. It is especially important
to counterbalance the desired terseness of the detailed design; if you feel
your detailed design is rudely short, consider making this section longer
instead.

# Drawbacks
[drawbacks]: #drawbacks

None? This is opt-in behavior for package maintainers.

# Alternatives
[alternatives]: #alternatives

Continue to use current ad-hoc conventions.

# Unresolved questions
[unresolved]: #unresolved-questions

How far should testing go?
- What consistitutes that "enough testing" was done to a package before a change was merged?

Should `<packaga>.passthru.tests` be flat?
For packages which have extremes in resource usage when testing (e.g. pytorch), it may
be beneficial to have additional structure for the tests to denote expectations of resources
and ownership of testing for upstream packages.

# Future work
[future]: #future-work

Problem with onboarding more test to aspects of nixpkgs CI and processes is the increased
need of compute, storage, and ram resources. Therefore, consideration of future work should
take into consideration how much testing is feasible for a given change.

Onboarding of CI tools to support testing paradigms:
- ofborg
  - Testing of <package>.passthru.tests is already done.
  - Testing of downstream dependencies and their tests when minimal (e.g. <10 rebuilds?)
- hydra
  - Allow for derivations exposed to hydraJobs to also probe for `<drv>.passthru.tests`?
