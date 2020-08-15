---
feature: Declarative Wrappers
start-date: (fill me in with today's date, YYYY-MM-DD)
author: Doron Behar <me@doronbehar.com>
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: POC Implementation at [#85103](https://github.com/NixOS/nixpkgs/pull/85103).
---

# Summary
[summary]: #summary

Manage the environment of wrappers declaratively and reduce the usage and
deprecate shell hooks such as `wrapGAppsHook` and `wrapQtAppsHook` in favor of
a new method to add an environment to an executable.

# Motivation
[motivation]: #motivation

- Make wrappers a separate derivation to make mere changes to the environment
  not trigger a heavy rebuild.
- Make it easier to debug why env vars are added to an executable, by using Nix
  as the language to evaluate what env vars are needed, instead of not
  documented good enough and not easily debug-able shell hooks.

We have numerous issues regarding wrappers and our wrapper shell hooks. Here's
a list of them:

<!-- TODO: explain each one better or categorize them -->

- https://github.com/NixOS/nixpkgs/issues/32790 :: Only related - they talk about patching some packages to use GI_GIR_PATH
- https://github.com/NixOS/nixpkgs/pull/83321
- https://discourse.nixos.org/t/declarative-wrappers/1775/1
- https://github.com/NixOS/nixpkgs/pull/53816 :: [RFC] Python library wrappers
- https://github.com/NixOS/nixpkgs/pull/70691
- https://github.com/NixOS/nixpkgs/pull/71089
- https://discourse.nixos.org/t/wrapqtappshook-out-of-tree/5619/6
- https://github.com/NixOS/nixpkgs/pull/83705
- https://github.com/NixOS/nixpkgs/issues/87667
- https://github.com/NixOS/nixpkgs/pull/89145 :: issue with luarocks generated luasockets vs when built with `buildLuaPackage`
- https://github.com/NixOS/nixpkgs/issues/87883 :: gimp: No module named gtk / plugins do not work
- https://github.com/NixOS/nixpkgs/pull/61213 :: scons: Fix a wrapping issue which overrides your PATH
- https://github.com/NixOS/nixpkgs/pull/61553 :: cc-wrapper: add hook
- https://github.com/NixOS/nixpkgs/pull/32552 :: makeWrapper: Use case not elif-chaining, and other cleanups
- https://github.com/NixOS/nixpkgs/issues/78792 :: general idea regarding how to orchestrate wrap hooks
- https://github.com/NixOS/nixpkgs/issues/83667 :: propagated-build-inputs in cross compilations
- https://github.com/NixOS/nixpkgs/issues/85306 :: Just another unwrapped derivation living in the wild issue
- https://github.com/NixOS/nixpkgs/pull/86166 :: an unclear fix to an issue with wrappings of stdenv tools
- https://github.com/NixOS/nixpkgs/issues/53111 :: small issue regarding gnome apps using `gapplication launch` which may be solved nicely if wrapped
- https://github.com/NixOS/nixpkgs/issues/86369 :: qt plugin path
- https://github.com/NixOS/nixpkgs/issues/86054 :: qt translations not found
- https://github.com/NixOS/nixpkgs/issues/86048 :: hplip unwrapped
- https://github.com/NixOS/nixpkgs/issues/84308 :: gtk-doc cross references
- https://github.com/NixOS/nixpkgs/issues/84249 :: git-remote-hg not wrapped correctly
(unreported) kdoctools exports an XDG_DATA_DIRS file for kdeconnect
(unreported) kconfigwidgets.dev is refernced by kdeconnect because of QT_PLUGIN_PATH
(unreported) bin/ of gobject-introspection.dev is added to (e.g) beets
- https://github.com/NixOS/nixpkgs/issues/87033 :: Something related to GDK_PIXBUF
- https://github.com/NixOS/nixpkgs/issues/49132 :: GDK_PIXBUF compatibilities
- https://github.com/NixOS/nixpkgs/issues/54278 :: GDK_PIXBUF compatibilities
- https://github.com/NixOS/nixpkgs/issues/39493 :: no ability to wrapProgram every executable that depends on gdk-pixbuf
- https://github.com/NixOS/nixpkgs/issues/60260 :: General complain about wrappers.
- https://github.com/NixOS/nixpkgs/issues/87667 :: VLC and gtk path 

# Detailed design [design]: #detailed-design

Consider every env var set by our shell hooks and our builders such as
`buildPythonPackage` and friends. Every such var is usually set because certain
packages used in the wrapped package's inputs, imply that this env var will be
needed during runtime. Many such vars' values are known to concatenated with
`:`.

Now, What if we'd write down in the `passthru`s of these packages, that "in order to
run something that requires this package, you need `THIS_ENV_VAR` to include
`$out/this/value`? Imagine this information was available to us in a consistent
manner. We could then write a Nix function, that will calculate the necessary
arguments to the shell functions `makeWrapper` or `wrapProgram`, somewhat
similarly to how our fixup hooks already do this.

This Nix function, let us call it `wrapGeneric`, should iterate recursively all
`buildInputs` and `propagatedBuildInputs` of a given derivation, and decide
what environment this derivation will need to run.  

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

This section illustrates the detailed design. This section should clarify all
confusion the reader has from the previous sections. It is especially important
to counterbalance the desired terseness of the detailed design; if you feel
your detailed design is rudely short, consider making this section longer
instead.

# Drawbacks
[drawbacks]: #drawbacks

If we think our shell hooks can scale, and that they are easily manageable, and
that we are OK with 

# Alternatives
[alternatives]: #alternatives

What other designs have been considered? What is the impact of not doing this?

# Unresolved questions
[unresolved]: #unresolved-questions

What parts of the design are still TBD or unknowns?

# Future work
[future]: #future-work

What future work, if any, would be implied or impacted by this feature
without being directly part of the work?
