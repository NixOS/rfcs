---
feature: collect-non-source-package-meta
start-date: 2021-03-14
author: Robert Scott
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: @asymmetric, @aforemny, @alyssais
shepherd-leader: @asymmetric
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Collect and maintain a new `meta` attribute in packages allowing users to easily
identify and manage their preference for binary (more broadly "non-source")
packages.

# Motivation
[motivation]: #motivation

Different users have different expectations from a software distribution. We
acknowledge that much with the collection of license information and the
existence of the `allowUnfree` nixpkgs option, much as Debian maintains a
separate `-nonfree` repository.

Similarly, there are a number of different reasons users may have to disfavour
those packages not built-from-source:

- Transparency: an ever-growing concern with more focus than ever on
  supply-chain attacks.
- Malleability: being able to conveniently override packages with patches or an
  altered build process is a key advantage of Nix, and for nixpkgs maintainers
  it's not generally possible to backport security fixes to binary packages.

For some users, these concerns are enough to deter them from using Nix entirely.

# Detailed design
[design]: #detailed-design

Add a new `meta` attribute to non-source-built packages, `sourceProvenance`.
The value of this attribute being a list of at least one entry from a
collection of possibilities maintained in `lib.sourceTypes`. These possibilities
should have entries to represent at least "built from source", "binary native
code", "binary bytecode" and "binary firmware".

Packages built from source can be left as-is with the assumption of a missing
attribute being the equivalent of `[ lib.sourceTypes.fromSource ]`.

Multiple values present in a package's `sourceProvenance` would be used to
mean that the package contains parts that fall under each of these categories.
However, a "source type" not appearing in a package's `sourceProvenance` would
_not_ necessarily mean that the package _doesn't_ contain parts which fall
under that category - it could simply mean that a package hasn't been fully
assessed yet. See "Future work" for discussion of adding the ability to make
such a "comprehensive" declaration.

Add a mechanism to allow `.nixpkgs/config.nix` to specify
`allowNonSource = false` to prevent use of these packages in a similar manner
to `allowUnfree`. An `allowNonSourcePredicate` parameter would allow the
distinction to be customized, but the default predicate should take into account
the possible hierarchical nature of `lib.sourceTypes` entries.

# Alternatives
[alternatives]: #alternatives

The original proposal used a simple boolean attribute to declare whether the
package contains any binary parts, mostly in an attempt to avoid having
to go down the route of devising and debating an ontology of source types. This
was deemed by the shepherding meeting to not embrace extensibility enough.

Another suggestion involved using a single value from a collection of "source
types" to describe the source provenance in an effort to avoid complexity, but
this appeared to have the disadvantages of requiring an ontology to be agreed
upon and still yet not providing sufficient flexibility to cover many cases.
The missing ability to express multiple provenances might even encourage
maintainers to proliferate source types that represent combinations of others.

There already exists a rather informally-applied convention of adding a `-bin`
suffix to the package names of "binary packages". This is non-ideal because:

- It doesn't allow a user to filter the use of these packages in a better way
  than simply not requesting a package with a `-bin` suffix. Binary-package
  _dependencies_ of non-`-bin` packages will still be installed regardless.
- It falls into the terminology trap over the term "binary", and if we expanded
  the definition of what a "binary" package is, *very many* packages in nixpkgs
  would have to be renamed, causing not only visual clutter but possible
  breakage and churn.

If we _don't_ do anything about this, then I think we continue to signal to
users who have such concerns over the source of their software that
nixpkgs/NixOS isn't for them. Far from being a concern just for obscure
extremists, most Debian users would probably balk at our appetite for binary
packages.

# Drawbacks
[drawbacks]: #drawbacks

- It could spur us to disappear into endless navel-gazing conversations over
  the `lib.sourceTypes` ontology.

# Unresolved questions
[unresolved]: #unresolved-questions

Exact attribute names and contents of `lib.sourceTypes` are open for debate.

# Future work
[future]: #future-work

The author is willing to spend a significant amount of time finding and marking
non-source packages in nixpkgs.

Addition of a simple accompanying boolean flag could allow the meaning of the
`sourceProvenance` field to be changed to imply the declaration is
"comprehensive" and that "source types" missing from the declaration are not
present. This is something that could be added once a maintainer has thoroughly
inspected a package, but should not place extra burden on someone wanting to
simply flag up that they have spotted some binary element in the package.
