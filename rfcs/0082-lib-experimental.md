---
feature: lib.experimental
start-date: 2020-12-17
author: Francois-Rene Rideau
co-authors: N/A
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

I propose that we create a directory lib/experimental for experimental code,
also available as lib.experimental and pkgs.lib.experimental. Such code is
available for limited use within select parts of nixpkgs, with the explicit
opt-in approval of their respective maintainers, but not for widespread use
in other parts of nixpkgs.

# Motivation
[motivation]: #motivation

Some libraries we *must* use
mandatorily unless it's impossible or at least unreasonable not to.
Some libraries we *should* use
unless there's a good reason not to.
Some libraries we *may* use
according to each contributors' preferences.
Some libraries we *may not* use
without an explicit endorsement by enough maintainers of the relevant packages.
Some libraries we *shouldn't* use
without a strong reason to do it.
Some libraries we *mustn't* use
and is only left temporarily for backward compatibility until complete migration off of it.

I propose we create a directory `lib/experimental`
to tag libraries as explicitly being part of the *may not* category.

Creating this experimental section to nixpkgs makes it clearer to maintainers
which code they may use where, and which code they may not.
If you are the maintainer of a package, and understand the risks related to using
experimental code, you may use this code or accept patches using it.
But you may also freely reject it, and no one should impose you that code without your consent.
In particular you understand that the code and its API may change, and
you may have to update your code accordingly, or accept patches that do.
Thus you agree to collaborate with the author of the experimental code
while the code remains in the experimental section.

Code that should *not* go into `lib.experimental` but directly into `lib` include:
* code that is good quality, well tested, known to work, with a stable API,
  good documentation, and no controversy among maintainers of nixpkgs.

Code that should *not* go into `lib.experimental` and not into nixpkgs at all include:
* code that bad quality, untested, not working, etc.
* code that is not yet used by any package in nixpkgs nor by any extension to nixpkgs.
* code that while cool has no purpose in nixpkgs as such and can well live outside it.

Making these social constraints explicit avoid accidents and conflict that would happen
if they were left implicit.

# Detailed design
[design]: #detailed-design

Experimental library code should be placed under the `lib/experimental` directory,
where it will be made available in the `pkgs.lib.experimental` attrset,
that will *not* re-export "direct" versions of the code directly in a parent attrset.

A README.md will explain the purpose of this directory, by quoting this RFC and linking to it.

The process for taking things out of experimental is when there is a consensus to do so:
when enough maintainers use this code rather than alternatives or workarounds,
when its API is stable and well documented, with enough years of good use,
when multiple maintainers are ready to service the code and it's not controversial anymore,
and/or when a RFC blesses the code to be made a direct part of lib.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

The [Gerbil](https://cons.io) packages in the
http://github.com/muknio/nixpkgs/archive/devel.tar.gz fork of nixpkgs use a
prototype object system called `POP` as a more versatile and principled alternative
to the traditional extension mechanisms in `lib.fixedPoints` or `lib.customisation`.
The libraries or use to good effects in particular by
[Glow](http://gitlab.com/mukn/glow) for local overrides.

Under this RFC, the code for POP would go in `lib/experimental/POP.nix`
and be available as `pkgs.lib.POP`.
Package maintainers may opt into using it like Gerbil does,
but contributors may not use it without the consent
of the maintainers of the code they contribute to.

If and when maintainers have adopted the code, and it becomes prevalent enough
compared to alternatives, and it is stable and well-documented,
it may move out of `lib/experimental` into `lib`.

# Drawbacks
[drawbacks]: #drawbacks

Without this section, some code may be included directly into `lib` that is not ready for it.
Then, contributors will try to use it and be frustrated when they can't get it to work,
or it gets rejected by maintainers. Or worse, maintainers may later find they have to maintain
code that they are not equipped to handle.

Conversely, without this section, some code may be altogether excluded from `nixpkgs`
when it could have been really useful to a handful of maintainers who have no trouble using it,
without in any way being a nuisance to other maintainers.

# Alternatives
[alternatives]: #alternatives

* We could accept code liberally in `lib` and have a huge mess.
* We could very conservatively reject code from `nixpkgs` altogether
  and miss on good features while repelling innovative contributors.
* We could let package maintainers each reinvent their own lacking and
  non-interoperable variants of the same code in each of the sections
  each of them maintain.
* We could adopt the idea but rename `experimental` to some other name.

# Unresolved questions
[unresolved]: #unresolved-questions

N/A

# Future work
[future]: #future-work

The process to get code in and out of `lib.experimental`
is deliberately left pretty informal.
It will be time to formalize it when there is a controversy about it.
