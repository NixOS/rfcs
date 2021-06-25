---
feature: experimental-flakes-release
start-date: 2021-06-25
author: gytis-ivaskevicius
co-authors:
shepherd-team:
shepherd-leader:
related-issues:
---

# Summary
[summary]: #summary

Add a way for users to use Nix flakes without enabling any options in `nix.conf` file

# Detailed design
[design]: #detailed-design
Reimplementation of [this PR](https://github.com/NixOS/nixpkgs/pull/120141).
Possibly with rename `nixFlakes` to `nixExperimentalFlakes` or something along
those lines.

# Unresolved questions
[unresolved]: #unresolved-questions

Do we change package names?
Do we add additional warnings of some sort so that end-users realize that they
are using an experimental feature?

# Future work
[future]: #future-work

Removal after actual release :)

