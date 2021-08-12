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

Add a new `meta` attribute to non-source-built packages, `fromSource = false`.
Leave other packages as-is with the assumption of a missing attribute meaning
`true`.

Add a mechanism to allow `.nixpkgs/config.nix` to specify
`allowNonSource = false` to prevent use of these packages in a similar manner
to `allowUnfree`.

# Alternatives
[alternatives]: #alternatives

I might have been tempted to collect the inverse, i.e. `isBinary = true` but
this runs into problems with clunky terminology. In my mind, the kind of package
that fails the transparency/malleability tests goes beyond what many people
would argue is "a binary". For instance, many (most?) java packages in nixpkgs
simply pull opaque `.jar`s - if not for their own app, they pull `.jar`
dependencies from maven. These are not transparent or malleable, but it's quite
an obtuse and disputable use of the term "binary" to describe them as such.

I decided that those packages which _did_ pass these transparency/malleability
tests had more in common than those that don't: that they are "from source", a
form where users have as much ability to inspect and alter the result as the
original author did.

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

- Some maintainers may be upset by having their packages marked as
  `fromSource = false`.
- It could spur us to disappear into endless navel-gazing conversations about
  what really counts as "from source" and what doesn't.
- On the other hand, _not_ discussing where the line stands thoroughly enough
  could cause the flag to be over-applied and thus become useless. Should we be
  compiling all our fonts where e.g. fontforge files are available? If all of
  these got marked as `fromSource = false`, all of a sudden users with
  `allowNonSource = false` set may end up with no installable desktop.

# Unresolved questions
[unresolved]: #unresolved-questions

Exact attribute names are open for debate.

# Future work
[future]: #future-work

The author is willing to spend a significant amount of time finding and marking
non-source packages in nixpkgs.
