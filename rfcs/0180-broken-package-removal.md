---
feature: broken-package-removal
start-date: 2024-07-14
author: Jörg "Mic92" Thalheim
co-authors:
shepherd-team: "@emilazy @preisi @jopejoe1"
shepherd-leader: "@jopejoe1"
related-issues:
---

# Summary

[summary]: #summary

This RFC defines conditions under which we remove broken packages or unmaintained leaf packages.
The RFC does not aim to define all possible reasons for removing a package but instead focuses on simple, automatable rules.
Since this document serves as a guideline for automatic package removal, it also allows for the possibility of removing a package earlier for other reasons.

# Motivation

[motivation]: #motivation

Broken and unmaintained packages still consume valuable time.
Broken packages need to be evaluated to some extent, and unmaintained packages might still need to be rebuilt when one of their dependencies changes.
Removing unmaintained or unused code should improve overall package quality and help save resources.
Since adding packages is easy, removing them should also be simple, ideally automated.

# Detailed Design

[design]: #detailed-design

All broken packages or unmaintained leaf packages will be removed after a full NixOS release cycle.
For example, if `hello-unmaintained` is marked as unmaintained in 23.11, it can be removed from master after the 24.05 release.

If a NixOS module depends on any removed package and is non-functional without it, the module will be removed as well.
In `pkgs/top-level/aliases.nix`, we can link to the pull request that removed the package, making it easier for users to recover the nix expression if needed.

In the pull request that removes a package, the people who have substantially contributed to the package declaration before and have not left the project should be pinged.

## Broken Packages

Packages that are unconditionally marked as broken on all platforms are candidates for removal.
If a package has dependent packages, those dependent packages will also be marked as indirectly broken.
If the dependent packages cannot function without the broken package, they should also be removed.
For example, if a library is broken and an application depends on it, the application will also be removed within the same time frame.

## Unmaintained Packages

We will add an "unmaintained" warning for all packages with an empty maintainer field that do not have any dependent packages with a maintainer.
Ideally, we will have automation or semi-automation in place to create pull requests for this process (see future work).

# Examples and Interactions

[examples-and-interactions]: #examples-and-interactions

- A release manager or another contributor marks `packageA` as broken in 23.11, notifying the maintainer.
- They have one full release cycle, as described, to fix `packageA`.
- After the 24.05 release, `packageA` can be automatically removed from the nixpkgs master branch, as outlined in this RFC.

# Drawbacks

[drawbacks]: #drawbacks

Some unmaintained packages may still have users who will no longer be able to use them, but the hope is that removing unmaintained packages will encourage these users to step up as maintainers.
In such cases, recovering the package from the git history should be relatively easy.

# Alternatives

[alternatives]: #alternatives

- Keep all packages.
- Archive removed nix expressions. Note that this RFC does not prevent this effort from being implemented in addition.

# Prior Art

[prior-art]: #prior-art

- Most Linux distributions have rules for removing unmaintained packages, e.g.:
  - Debian: [Orphaning a package](https://www.debian.org/doc/manuals/developers-reference/developers-reference.en.html#orphaning-a-package).
  - Gentoo:
    - [Ebuild removal](https://devmanual.gentoo.org/ebuild-maintenance/removal/index.html).
    - [Treecleaner](https://wiki.gentoo.org/wiki/Project:Treecleaner)
    - [Treecleaner policy](https://wiki.gentoo.org/wiki/Project:Treecleaner/Policy)
 
- [Nixpkgs eval time is increasing too fast](https://github.com/NixOS/nixpkgs/issues/320528): This issue discusses ways to improve evaluation time.
- FreeBSD Porters Handbook: [13.15. Marking a Port for Removal](https://docs.freebsd.org/en/books/porters-handbook/book/#dads-deprecated)

# Unresolved Questions

[unresolved]: #unresolved-questions

None.

# Future Work

[future]: #future-work

- Develop automation that opens pull requests to remove packages.
- Add deprecation warnings for packages scheduled for removal to notify potential users i.e. as described in [RFC0127 problems](https://github.com/NixOS/rfcs/blob/master/rfcs/0127-issues-warnings.md)
