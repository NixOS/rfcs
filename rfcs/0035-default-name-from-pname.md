---
feature: default_name_from_pname
start-date: 2018-10-02
author: Patrick Hilhorst (@Synthetica9)
co-authors: (find a buddy later to help our with the RFC)
related-issues:
  - https://github.com/NixOS/nixpkgs/pull/41627
---

# Summary
[summary]: #summary

Whenever the `version` and `pname` attribute are both present, use
`"${pname}-${version}"` as the default value for `name` for `mkDerivation`.

# Motivation
[motivation]: #motivation

The string `"${pname}-${version}"` appears verbatim in the nixpkgs repo [627
times](appendixA), at the time of this writing. Variants of this string appear
[746 times][appendixA], with the most common variant being `baseName`. This RFC
would reduce repetition in nixpkgs, and would allow for the `rec` keyword to be
removed from an unknown number of places.

This RFC was originally submitted as [nixpkgs PR #41627][originalPR]. This PR
received some positive attention:

![Positive attention on the original PR][Upvotes]

However, it was [suggested][useRFC] by @edolstra that this should go through the
RFC process instead of directly implementing it in nixpkgs.

# Detailed design
[design]: #detailed-design

The basic design is simple: change the default value for the `name` attribute of
`mkDerivation` to `"${pname}-${version}"` if both attributes are present
(implemented in [`c313e07`][basicChange])

Care should be taken to assure that position information is transferred
correctly (implemented in [`0c1d5d1`][positionInfo]) and to add an assertion
that the generated name is consistent with the actual name if all three
attributes are present (implemented in [`e0d2348`][checkConsistent]). Because
some packages already define a prefix to their `pname`-`version` pair (for
example: `python2.7-setuptools-40.2.0`), it might be better to use
`lib.strings.hasSuffix` here instead of `(==)`.

`git cherry-pick`-ing these three commits (keeping the mentioned caveats in
mind) should be sufficient to get this RFC implemented. It is discouraged to
continue on the original PR, since a lot of it has gone out of date since.

# Drawbacks
[drawbacks]: #drawbacks

  * It could confuse users unfamiliar with this RFC where a package gets its
    name from.
  * It makes a currently unofficial (but not discouraged) practice official,
    and enshrines the `pname` attribute name into "law". Once this RFC is
    implemented, there is no easy way of changing this attribute name again.
    _Note: `pname` is already used for Python packages, but in this context,
    `name = "${python.libPrefix}-${pname}-${version}"`.

# Alternatives
[alternatives]: #alternatives

Other than doing nothing, there doesn't seem to be an alternative design.

# Unresolved questions
[unresolved]: #unresolved-questions

* Is `pname` the correct attribute name to use for this? Or should we go with
  the (~7.5×) less common, but more descriptive `baseName`?

# Future work
[future]: #future-work

Future PR's that use the old pattern of `"${pname}-{version}"` (or a variant
thereof) should be requested to change to use the new pattern suggested here.

There could be a gradual cleanup of old code, to make sure all derivations use
this new pattern.

# Appendix A: Occurances of Variants
[appendixA]: #appendix-A

```sh     
$ ag --nix '"\$\{\w+\}-\$\{version\}"' --no-filename --only-matching | sort | uniq --count | sort --numeric-sort
      1 "${appname}-${version}"
      1 "${appName}-${version}"
      1 "${attr}-${version}"
      1 "${cmd}-${version}"
      1 "${drvName}-${version}"
      1 "${flavor}-${version}"
      1 "${fullName}-${version}"
      1 "${nameMajor}-${version}"
      1 "${name_}-${version}"
      1 "${package_name}-${version}"
      1 "${packageName}-${version}"
      1 "${pkgName}-${version}"
      1 "${plainName}-${version}"
      1 "${pName}-${version}"
      1 "${prefix}-${version}"
      1 "${shortName}-${version}"
      1 "${simpleName}-${version}"
      1 "${srcName}-${version}"
      1 "${stname}-${version}"
      1 "${toolName}-${version}"
      2 "${artifactId}-${version}"
      2 "${pkg}-${version}"
      2 "${p_name}-${version}"
      2 "${shortname}-${version}"
      3 "${basename}-${version}"
      3 "${libname}-${version}"
      3 "${_name}-${version}"
      3 "${package}-${version}"
      3 "${program}-${version}"
      4 "${project}-${version}"
      5 "${pkgname}-${version}"
      5 "${product}-${version}"
      7 "${gemName}-${version}"
      9 "${repo}-${version}"
     24 "${name}-${version}"
     85 "${baseName}-${version}"
    627 "${pname}-${version}"
    746
```

<!-- Links used in the RFC: -->

[originalPR]:      https://github.com/NixOS/nixpkgs/pull/41627
[upvotes]:         https://i.imgur.com/vosd6YG.png
[useRFC]:          https://github.com/NixOS/nixpkgs/pull/41627#issuecomment-395750781

[basicChange]:     https://github.com/NixOS/nixpkgs/pull/41627/commits/c313e07
[positionInfo]:    https://github.com/NixOS/nixpkgs/pull/41627/commits/0c1d5d1
[checkConsistent]: https://github.com/NixOS/nixpkgs/pull/41627/commits/e0d2348
