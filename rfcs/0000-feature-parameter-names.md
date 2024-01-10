---
feature: feature_parameter_names
start-date: 2024-01-10
author: Dmitry Bogatov
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Nixpkgs usually exports compile-time options of the upstream build system
through the named parameters of derivation function, but does it inconsistent
way.

# Motivation
[motivation]: #motivation

Developer interface for building environment with specific features enabled and
disabled is more complicated and requires more knowledge of implementation
details compared to already existing systems.

For example, Gentoo Linux has exhaustive list of [all known configuration
flags](https://www.gentoo.org/support/use-flags) and has means to
programmatically query what flags are available for particular package. Nixpkgs
has neither, and this RFC strives to rectify it.

# Detailed design
[design]: #detailed-design

1. Derivation function SHOULD expose compile-time options of the upstream build system
   to enable or disable a feature using parameters named either as `enableX` or `withX`,
   consistent with Autoconf naming convention.

   [Autoconf ENABLE](https://www.gnu.org/software/autoconf/manual/autoconf-2.66/html_node/Package-Options.html)
   [Autoconf WITH](https://www.gnu.org/software/autoconf/manual/autoconf-2.66/html_node/Package-Options.html)

2. If compile-time feature requires build and runtime dependency on package
   `libfoo`, corresponding feature parameter MUST be named `withFoo`. Prefix `lib`
   of the build dependency is discarded and first letter of the remaining name is
   capitalized.

3. If compile-time feature does not require any extra build dependencies,
   corresponding feature parameter MUST have name matching `^enable[^a-z]` and
   SHOULD correspond to the upstream naming.

4. These rules are to be enforced by static code analyse linter.

5. Parameter names matching `^(enable|with)` regular expression MUST not be
   used for any other purpose. In particular, they always must be boolean.

## The migration process.

Named parameters are part of the programming interface, and renaming them is a
breaking change. As such, renaming of the parameters is done in following way:

1. Following function is added into `lib` set:

```
let coalesce = old: new: if (old != null) then old else new;
```

Starting with following function:
```
{ lib
, stdenv
, nonCompliantFoo ? true
}:

# uses nonCompliantFoo
stdenv.mkDerivation { ... }
```

First step of migration is to replace it with the following:
```
{ lib
, stdenv
, nonCompliantFoo ? null
, enableFoo ? lib.warnIf (nonCompliantFoo != null)
                         "Feature flag nonCompliantFoo is renamed to enableFoo."
                         (lib.coalesce nonCompliantFoo true)
}:

# uses enableFoo
stdenv.mkDerivation { ... }
```

and after grace period of two releases, any mentions of `nonCompliantFoo` are
removed, and function becomes:
```
{ lib
, stdenv
, enableFoo ? true
}:

# uses enableFoo
stdenv.mkDerivation { ... }
```



# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

This is how one can query list of feature parameters that incur extra runtime dependencies:

```
$ nix eval --json --impure --expr 'with import ./. {}; builtins.attrNames gnuplot.override.__functionArgs' | jq '.[]| select(startswith("with"))'
"withCaca"
"withLua"
"withQt"
"withTeXLive"
"withWxGTK"
```

I picked the `gnuplot` as example since it is the closest to be compliant with proposed rules.

# Drawbacks

1. The migration process involves renaming feature parameters, so these changes
   will likely conflict with other outstanding changes to the derivation, and potentially
   even with automatic version bumps.

# Alternatives
[alternatives]: #alternatives

## Group all feature parameters into separate attrset parameter

Instead of writing

```
{ lib, stdenv, enableFoo ? true }:

# uses enableFoo
stdenv.mkDerivation { ... }
```

derivation can be written as
```
{ lib, stdenv, features ? { enableFoo = true; }}:

# uses features.enableFoo
stdenv.mkDerivation { ... }
```

It is definitely looks cleaner, but unfortunately hits several limitations of
the Nix language.

1. Nix language provides way to [introspect function argument names](https://nixos.org/manual/nix/stable/language/builtins.html#builtins-functionArgs),
   but no way to learn their default values. So this approach gives consistency, but no way to query list of derivation feature parameters.

2. Overrides become much more verbose. Simple and ubiquitous

   ```
   bar.override { withFoo = true; }
   ```

   becomes unwieldy

   ```
   bar.override (old: old // { features = old.features // { withFoo = true }; })
   ```

   That can be simplified by introducing `overrideFeatures` function, but we
   already have [way too many](https://ryantm.github.io/nixpkgs/using/overrides)
   `override` functions. Also, this version will silently override nothing in case
   of typo.

Any approach that tries to pass attribute set to function will have these
issues. Using existing [config.nix](https://github.com/NixOS/nixpkgs/blob/master/pkgs/top-level/config.nix)
is no different.

## Do nothing

Avoids all the work and drawbacks, but there is no evidence that consistency
problem will [solve itself evolutionary](https://github.com/NixOS/nixpkgs/pull/234463#issuecomment-1574892207).
For some build dependencies, we have multiple equally popular feature parameter
names, and people keep picking random one when adding new packages.

# Prior art
[prior-art]: #prior-art

As mentioned in motivation part, the best in class of feature flag
configuration system is Gentoo Linux:

- [https://www.gentoo.org/support/use-flags]

There is not much work I can find about this problem in Nixpkgs other than my
previous attempts to solve it on package-by-package basis:

- https://github.com/NixOS/nixpkgs/issues/148730
- https://github.com/NixOS/nixpkgs/pull/234463

# Unresolved questions
[unresolved]: #unresolved-questions

This RFC makes it possible to introspect feature parameters of particular
derivation, but still does not provide simple and efficient way to list all
existing feature parameters.

# Future work
[future]: #future-work

There are other configuration scenarios not covered by this RFC:

- Optional dependencies in shell wrappers (e.g [passage](https://github.com/NixOS/nixpkgs/blob/master/pkgs/tools/security/passage/default.nix#L12)).
- Feature parameter not a boolean, but string or number (e.g [path to default mailbox](https://github.com/muttmua/mutt/blob/master/configure.ac#L499))
- Finding way to get list of all existing feature parameters. That can be possibly done by building and distributing the index separately,
  like [nix-index](https://github.com/nix-community/nix-index) does it.
