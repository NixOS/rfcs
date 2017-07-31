---
feature: readonly-recursive-nix
start-date: 2017-04-02
author: Shea Levy
co-authors: (find a buddy later to help our with the RFC)
related-issues: https://github.com/NixOS/nix/issues/13
---

# Summary
[summary]: #summary

Allow nix builds to perform readonly operations on the subset of the
nix store exposed to them.

# Motivation
[motivation]: #motivation

The primary motivation for this feature is as an incremental step
toward full recursive nix, described in [NixOS/nix#13][nix-issue-13]
and to be fleshed out in its own RFC. However, even without the full
solution this feature would replace the `exportReferencesGraph` nix
feature and make it more general.

# Detailed design
[design]: #detailed-design

1. Break out daemon code into `Daemon` class that can be instantiated
   by `DerivationGoal`, with a separate thread to handle incoming
   connections.
2. Add a readonly mode to the `Daemon`.
3. Add a parameter to the `Daemon` code to restrict the view exposed
   by its underlying `Store` to just those paths that are inputs to
   the build.
4. Add an environment variable to specify the daemon socket path.
5. Create a daemon socket in the build directory.

# Drawbacks
[drawbacks]: #drawbacks

Increased complexity, increased attack surface for builds (which now
have a new communication channel with a root process). The daemon is
already intended to be safe to have arbitrary users connect to it, and
if need be we can put this behind an option.

# Alternatives
[alternatives]: #alternatives

The main alternative to full recursive nix is import from derivation,
which currently works but has some significant issues. It is also less
expressive than full recursive nix:

* Import-from-derivation breaks dry-run evaluation and separation of
  evaluation-time from build-time.
* Import-from-derivation won't work if your expression-producing build
  needs to run on a different machine than your evaluating machine,
  unless you have distributed builds set up at evaluation time
* Import-from-derivation doesn't keep a connection between the build
  rule and its dependencies: the expressions imported-from-derivation
  are not discoverable from the final drv
* Import-from-derivation requires you to know up front all of the
  possible branches that involve recursive evaluation, whereas
  recursive nix can branch based on information derived during the
  build itself.
* Certain far-future goals, such as a gcc frontend that does all
  compilations as nested derivations to get free distcc and ccache,
  would be very impractical to shoehorn into an import-from-derivaiton
  regime.

The alternative to readonly recursive nix is just to continue to used
the existing `exportReferencesGraph` mechanism. But not doing this
work means not doing full recursive nix, which blocks quite a number
of valuable use cases, including using nix as a make replacement.

# Unresolved questions
[unresolved]: #unresolved-questions

None as far as I know

[nix-issue-13]: https://github.com/NixOS/nix/issues/13
