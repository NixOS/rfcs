---
feature: broken-package-removal
start-date: 2024-07-14
author: Jörg "Mic92" Thalheim
co-authors:
shepherd-team:
shepherd-leader:
related-issues:
---

# Summary

[summary]: #summary

This RFCs defines under what conditions we remove broken and unmaintained leaf packages.
The RFC does not have the ambition to define all reasons to remove a package but
instead focuses on simple rules that can be automated.
Because this document is just the guideline for automatic package removal,
it also leave it open, that a package can be removed earlier for other reasons.

# Motivation

[motivation]: #motivation

Broken and unmaintained packages still cost us valuable time.
Broken packages still have to be evaluated to some extent
and unmaintained packages might still have to rebuild when one of their dependencies changes.
Removing unmaintained/unused code hopefully increases the overall package quality and helps us
to save resources.
Because it is easy to add packages, it should be also easy to remove them, ideally automated.

# Detailed design

[design]: #detailed-design

All packages marked as broken/unmaintained will be removed after a full NixOS release.
For example `hello-unmaintained` will be marked as unmaintained in 23.11 then once we
have 24.05, we can remove it from master.

## Broken Packages

Packages that are marked as broken unconditionally platforms should are canidates for removal.
If the package had dependencies, those dependencies are also marked as indirectly broken.
If they are not functional without the broken package, they should be removed as well.

## Unmaintained packages

We add an unmaintained warning for all packages, with an empty maintainer field that do not have packages depending on it.
Ideally we have an automation or semi-automation that creates pull requests for that (see future work).

If a NixOS module depends on any of removed package, this module gets removed as well, if it is non-functional without the package.
In `pkgs/top-level/aliases.nix` we can link to the pull request that removed the package,
to make it easier for people to recover the nix expression.

In the pull request that removes a package, we also will ping people that have modified/updated the package excluding those that only
touched the package as part of treewide.

# Examples and Interactions

[examples-and-interactions]: #examples-and-interactions

-

# Drawbacks

[drawbacks]: #drawbacks

Some maintained packages might still have users that won't be able to use the package,
but the hope is that the removal of unmaintained package will lead to these people
stepping up as a maintainer. Recovering from the git history should be easy in that case.

# Alternatives

[alternatives]: #alternatives

- Keep all packages.
- Put removed nix expressions in an archive. Note that the this RFC
  does not stop this effort from beeing implemented additionally.

# Prior art

[prior-art]: #prior-art

- Most Linux distributions have rules around removing unmaintained packages i.e. [Debian](https://www.debian.org/doc/manuals/developers-reference/developers-reference.en.html#orphaning-a-package).
- [Nixpkgs eval time is increasing too fast](https://github.com/NixOS/nixpkgs/issues/320528):
  This issue discusses how we can improve the evaluation time.

# Unresolved questions

[unresolved]: #unresolved-questions

?

# Future work

[future]: #future-work

- Write automation that will open pull request to remove packages.
- Add deprecation warnings for packages that are about to become removed, so that potential users are notified
