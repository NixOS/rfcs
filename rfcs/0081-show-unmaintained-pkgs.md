---
feature: show unmaintained packages
start-date: 2020-12-10
author: lassulus
co-authors: Mic92
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

This RFC is about the policy (whether we should do this) not about implementation details (how we should do this)

When evaluating a system (for example with nixos-rebuild) unmaintained packages should show up, so people are encouraged to maintain them.

# Motivation
[motivation]: #motivation

Get all commonly used packages maintained. Get more maintainers, encourage users to contribute to nixpkgs.

# Detailed design
[design]: #detailed-design

When evaluating a package a check would test `meta.maintainers` and raise a warning if it is empty. Add an option to disable it to speedup evaluation again.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

```
package bzip2 is unmaintained: (https://github.com/nixos/nixpkgs/pkgs/tools/compression/bzip2/default.nix) it is required by nix, firefox, X11 ...
```

(not sure if we want to print the whole dependency list)

# Drawbacks
[drawbacks]: #drawbacks

Does evaluation take longer?
People could be afraid to see how many unmaintained packages there are and switch to $distro.

# Alternatives
[alternatives]: #alternatives

Have a fancy website to show all currently unmaintained packages.

# Unresolved questions
[unresolved]: #unresolved-questions

What parts of the design are still TBD or unknowns?

# Future work
[future]: #future-work

Implement the feature :)
