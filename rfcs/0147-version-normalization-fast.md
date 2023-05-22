---
feature: nixpkgs_version_normalization_fast
start-date: 2023-05-22
author: Ryan Hendrickson
co-authors:
shepherd-team:
shepherd-leader:
related-issues:
---

# Summary
[summary]: #summary

Resolve several technical issues with respect to how
unstable/snapshot/unreleased/etc. versions are described and compared in
Nixpkgs derivations, with the minimum changes to the status quo necessary to
achive the goal.

# Motivation
[motivation]: #motivation

The Nixpkgs manual [currently states](
https://nixos.org/manual/nixpkgs/unstable/#sec-package-naming) that the
version attribute for a package taken from a repository commit not associated
with a tagged version _must_ be in `"unstable-YYYY-MM-DD"` format. This causes
several issues in practice; this RFC focuses on the following three:

- `builtins.parseDrvName` does the wrong thing if a package version doesn't
  start with a digit:

```example
nix-repl> builtins.parseDrvName "mpv-unstable-2021-05-03"
{ name = "mpv-unstable"; version = "2021-05-03"; }
```

- `builtins.compareVersions` (and every tool and Nixpkgs library function that
  uses that function or equivalent logic) always considers stable versions to
  be older than unstable versions

- External package monitoring services like [Repology](https://repology.org/)
  can't effectively compare unstable versions with stable versions of the same
  package from other package repositories.

This RFC follows a previous attempt ([[RFC 0107]](
https://github.com/NixOS/rfcs/pull/107)) to address these same three
motivations, which stalled out in large part due to lack of consensus over the
ideal version format for unstable versions. This RFC is thus motivated by a
fourth item:

- Make as few waves as possible, and get something that does some good agreed
  upon quickly rather than waiting forever for something that does the most
  possible good.

# Detailed design
[design]: #detailed-design

## Change to policy

Amend the [Coding conventions > Package naming](
https://nixos.org/manual/nixpkgs/unstable/#sec-package-naming) section of the
Nixpkgs manual by removing this bullet point:

> - If a package is not a release but a commit from a repository, then the `version` attribute _must_ be the date of that (fetched) commit. The date _must_ be in `"unstable-YYYY-MM-DD"` format.

and replacing it with this bullet point:

> - If a package is not a release but a commit from a repository, then the `version` attribute _must_ be the version number of the most recent release preceding that commit (use `0` if no such release exists), followed by `-unstable-`, followed by the date of the fetched commit in `YYYY-MM-DD` format. (examples: `1.9.11-unstable-2022-04-23`, `0-unstable-2018-01-01`)

## Change to functionality

Amend the implementation of Nix's built-in function `compareVersions` to handle
`-unstable-` as a special separator. The new implementation should behave like
the following Nix function (in which `builtins.compareVersions` refers to its
current implementation, not the implementation being defined here):

```nix
v1: v2:
let
  stableV1 = builtins.head (builtins.split "-unstable-" v1);
  stableV2 = builtins.head (builtins.split "-unstable-" v2);
  cmp = builtins.compareVersions stableV1 stableV2;
in
if cmp != 0 then
  cmp
else
  let
    offset1 = builtins.stringLength "${stableV1}-unstable-";
    offset2 = builtins.stringLength "${stableV2}-unstable-"; 
    unstableV1 = builtins.substring offset1 (builtins.stringLength v1 - offset1) v1;
    unstableV2 = builtins.substring offset2 (builtins.stringLength v2 - offset2) v2;
  in
  if unstableV1 == unstableV2 then
    0
  else if unstableV1 < unstableV2 then
    -1
  else
    1
```

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

When considering the change to the Nixpkgs manual, please note that the word
‘_must_’ is used in the same way in both versions; this RFC does not create a
mandatory duty to adhere to a particular format where previously there was
none, and neither does it create any exceptions for package authors to use
their own judgment where previously there were none. In no way should this RFC
be read as somehow more or less ‘authoritative’ than the proposed language in
the Nixpkgs manual implies. It is entirely agnostic as to whether it is good or
bad for package authors to ignore this section of the manual. It simply amends
what the manual states. Cracking down on scofflaws or encouraging more
diversity is out of scope for this proposal.

A briefer, if not as suitable for a normative spec, description of how the new
`compareVersions` should behave is as follows: it should compare versions as if
it first parsed versions into a Haskell-y pair `(StableVersion, Maybe Text)` by
splitting on the first occurrence of `"-unstable-"`, and then used the natural
lexicographic ordering (with the ordering on `StableVersion` defined by the
current `compareVersions` implementation).

The following list is sorted by the new `compareVersions` logic:

```
0-unstable-2023-05-01
0.0.1
1.0.pre1
1.0.pre1-unstable-2021-01-01
1.0
1.0-unstable-2023-01-01
1.0-unstable-2023-01-02
1.0-unstable-2023-02-01
1.0.1
1.0.1-unstable-2022-12-31
1.0.2
1.1
```

The remainder of this section comprises examples adapted directly from [RFC 0107].

- Bochs is a typical Sourceforge-hosted project; its labeled snapshots can be
  fetched from tarballs obtained via URLs like
  <https://sourceforge.net/projects/bochs/files/bochs/2.6.11/>

  For this example, we have `pname = "bochs"; version = "2.6.11";`.

- MPV is a typical Github-hosted program; its labeled snapshots can be fetched
  from tarballs obtained via URLs like
  <https://github.com/mpv-player/mpv/releases/tag/v0.33.1>.

  For this example, we get rid of the `"v"` prepended to the version tag: `pname
  = "mpv"; version = "0.33.1";`.

- SDL2 is hosted on Github; its latest labeled version can be downloaded from
  <https://github.com/libsdl-org/SDL/releases/tag/release-2.0.14>. Therefore we
  have `pname = "SDL2"; version = "2.0.14";`.

  _However_, this labeled version was released December 21, 2020, while the
  latest change was done in May 28, 2021.

  Therefore, for this particular unlabeled releases of SDL2, we have `pname =
  "SDL2"; version = "2.0.14-unstable-2021-05-28";`.

- Cardboard is a typical Gitlab-hosted program. It has no labeled release yet,
  therefore we use `0` as default dummy stable version; further, the latest
  commit was made on May 10, 2021.

  Therefore, for this particular commit have `pname = "cardboard"; version =
  "0-unstable-2021-05-21";`.

- Python is a famous programming language and interpreter. Before the
  deprecation of its 2.x series in 2020, Python had two release branches,
  popularly known as 'Python 2' and 'Python 3'. Indeed this peculiar situation
  reflected in many package management teams, especially Nixpkgs, that employed
  `python2` and `python3` as `pname`s for these particular programs.

  As an exercise of imagination, suppose the scenarios described below:

  Python 2.6 was released 2008-10-01; an unlabeled snapshot of Python 2 branch
  released at 2008-12-04 would have `version = "2.6-unstable-2008-12-04"`.

  At the same time, Python 3.0 was released 2008-12-03; an unlabeled snapshot of
  Python 3 branch released at 2008-12-04 would have
  `3.0-unstable-2008-12-04"`.

- The Linux drivers for Realtek rtl8192eu can be fetched from a Github page,
  <https://github.com/Mange/rtl8192eu-linux-driver>. It has no labeled release;
  the latest code is from May 12, 2021. Perhaps it was built for Linux kernel
  version 5.10.01, but this is not strictly speaking a component of the version
  of the _driver_. This RFC doesn't state what to do with the kernel
  version—perhaps it should be part of the `pname`, like `pname =
  "rtl8192eu-linux5.10.01"`, or perhaps it should be in some other metadata
  field—other than to say that it should _not_ be included in the version
  attribute. The version of this driver module should be `version =
  "0-unstable-2021-05-12";`.

# Drawbacks
[drawbacks]: #drawbacks

Altering a built-in is more difficult than just working within Nixpkgs.
Fortunately, the change requested should not negatively impact the vast
majority, if not all, current uses of the built-in. Also fortunately, the
proposed version numbering policy is only partially mishandled by the existing
implementation of `compareVersions`, while the existing `unstable-YYYY-MM-DD`
format is _entirely_ mishandled when compared to stable versions—which means
that the situation is still improved by adopting the new policy in Nixpkgs
without necessarily waiting for the built-in to change.

It's always possible that there exists a person who would look at the string
`3.21.0` and think that it looks like a version number; would look at the
string `unstable-2023-05-01` and think that it looks like a version number; but
would look at the string `3.21.0-unstable-2023-05-01` and be baffled as to what
it could mean. (In other words, a person who is not displeased by the status
quo but would be displeased with the proposal.) I hope such people are rare.

Other than that, there shouldn't be any real drawbacks to this proposal that
would not equally apply to keeping things as they are.

# Alternatives
[alternatives]: #alternatives

## Using a word other than ‘unstable’

It has been suggested that `unstable` is not the correct word to use for this
purpose, because it implies the wrong thing, it is insufficiently descriptive,
or it doesn't correspond with the terminology used by an upstream project or
ecosystem. An entire thesaurus of alternatives have been discussed in
https://github.com/NixOS/rfcs/pull/107, such as ‘unreleased’, ‘patched’,
‘date’, and ‘snapshot‘; and every proposal has been objected to by at least one
participant.

Of all the possibilities, `unstable` has one objective advantage that sets it
apart from the rest: the word is already part of the format mandated by the
Nixpkgs manual, however imperfectly that mandate is being applied. Nobody can
prefer the status quo to this proposal on the grounds that they object to the
word ‘unstable’.

RFCs are not, as I understand it, intended to be immutable, irrevocable policy.
If, in the future, the one true prophet of version numbering manifests before
us to teach us that the word we must always use for this purpose is ‘gwelm’,
and all who hear the prophet's voice nod their heads at this self-evident and
incontrovertible wisdom (which is approximately the level of supernatural
intervention I am expecting would be necessary to achieve consensus on this),
there is simply no reason an enlightened disciple of gwelmism can't open
another RFC and correct our error, regardless of whether an older, humbler RFC
on the topic of numbering was previously accepted.

## Extensible version number microformat

The previously mentioned [[RFC 0107]](https://github.com/NixOS/rfcs/pull/107)
adopted an approach that, in aesthetic if not in technical specification,
somewhat resembled a URL query string and implied that future extensions to
version strings could be added in a straightforward way by tacking on another
key-value pair.

This approach required using characters like `:`, `+`, and/or `=` that don't
necessarily play well in all places a version string is expected to appear,
even in the common, single-key case of just wanting a `date`. The additional
complexity cost of supporting multiple, mostly hypothetical fields was too high
a price to pay for what was still considered by many an imperfect resolution to
the original problems.

## Coming up with a version string format that subsumes all others in use in Nixpkgs

Attempting this sounds like a good way to flush a lot of your time down your
residential waste chute. The goals of conforming to upstream's conventions,
however wacky they may be, and having a single universal implementation of
version comparison are fundamentally in tension, and you aren't going to find a
compromise everyone likes.

## Replacing version strings with structured data

This is probably not as hopelessly constrained as the universal version string
alternative, but it still would require a lot of design and probably
implementation work before it's even possible to weigh the pros and cons of
this, other than the obvious con of requiring that up-front investment.

## Replacing ‘_must_’ with ‘_should_’

This would bring the policy as written in line with how it seems to be applied
in practice, and personally I'm somewhat in favor of it. However, it would
constitute another change that would be a potential sticking point for an
objector relative to the status quo, and so I have chosen not to include it in
this proposal. The written word remains ‘_must_’, and the Nixpkgs community's
relationship to the written word remains as it is, for better or worse.

# Unresolved questions
[unresolved]: #unresolved-questions

This design is intentionally limited in scope and as such should have no
unresolved questions, but plenty of potential future work.

# Future work
[future]: #future-work

- Actually migrate version numbers in Nixpkgs to conform to the new numbering
  policy

  Why is this future work and not part of the proposal proper? Because it's
  easy for me to imagine that there are corners of Nixpkgs where far more care
  and debate would be required before changing the version format they
  currently use. Even without sprinting on a migration, new packages can be
  written in line with the new policy, and motivated maintainers can have cover
  to migrate their own packages as well; the RFC isn't pointless without a
  migration sprint.

- Design and implement per-package version comparison

  This is what I think should be the long-term solution to package
  idiosyncracies. There's no fundamental reason why we should need to be able
  to compare the version of Neovim to the version of Firefox. So, a package
  should be able to define its own version comparison logic, like as an
  attribute on `passthru`, and that should be used preferentially by Nixpkgs
  functions and external Nix-aware tools to compare versions of that package.
  Then packages can adopt upstream conventions or ecosystem-specific
  conventions for version numbering, and we can amend the Nixpkgs manual again
  to make this a legal alternative to following the default format. And _then_
  we can start cracking down on packages that don't do one or the other.
