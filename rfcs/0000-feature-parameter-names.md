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

1. Derivation function MAY expose compile-time boolean options of the upstream
   build system to enable or disable a feature using parameters named either as
   `enableX` or `withX`, consistent with Autoconf naming convention.

   [Autoconf ENABLE](https://www.gnu.org/software/autoconf/manual/autoconf-2.66/html_node/Package-Options.html)
   [Autoconf WITH](https://www.gnu.org/software/autoconf/manual/autoconf-2.66/html_node/Package-Options.html)

2. If compile-time feature requires build and runtime dependency on package
   `libfoo`, corresponding feature parameter MUST match regular expression
   `^with[^a-z]`. See guidelines below for choosing name of feature parameter.

3. If compile-time feature does not require any extra build dependencies,
   corresponding feature parameter MUST have name matching `^enable[^a-z]` and
   SHOULD correspond to the upstream naming.

4. If upstream build features and build dependencies do not map one-to-one,
   then one `with` feature parameter SHOULD be added for every build dependecy
   and one `enable` feature SHOULD be added for every upstream build feature
   intended to be optional. Assertions to preclude incoherent feature
   configurations MAY be added.

5. These rules are to be enforced by static code analyse linter. Since no
   static code analyzis is perfect, it shall have support for inhibiting
   warnings in individual cases that do not fit into general scheme.

5. Parameter names matching `^(enable|with)` regular expression MUST not be
   used for any other purpose. In particular, they always must be boolean.

6. Derivation function MAY expose compile-time string or numeric options of the
   upstream build system using feature parameters that MUST match `^conf[^a-z]`
   regular expression, e.g `confDefaultMaildir`.

7. Due overwhelming amount of possible combinations of feature flags for some
   packages, nixpkgs maintainer is not expected to test or maintain them all,
   but SHOULD accept provided technically sound contributions related to
   configurations with non-default feature flags.

8. Due overwhelming amount of possible combinations of feature flags for some
   packages, only configurations that has name in package set (e.g `emacs-nox`)
   shall be built on CI.

## The migration process.

Named parameters are part of the programming interface, and renaming them is a
breaking change. As such, renaming of the parameters is done in following way:

1. Following function is added into `lib` set:

```
let renamed = { oldName, newName, sunset, oldValue }: newValue:
   let warning = builtins.concatStringsSep " "
      [ "Feature flag"
      , oldName
      , "is renamed to"
      , newName
      , "; old name will no longer be available in nixpkgs="
      , sunset
      , "."
      ]
   in lib.warnIf (value != null) warning (if (value != null) then value else newValue);
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
, enableFoo ? lib.renamed {
    oldName = "nonCompliantFoo";
    newName = "enableFoo";
    sunset = "25.11";
    value = nonCompliantFoo;
  } true
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

## Feature parameter naming guidelines

1. Feature flags that require single external dependency SHOULD be named after
   that dependency. Prefix `lib` SHOULD be removed. For example,
   ```
   systemd => withSystemd
   libgif  => withGif
   curl    => withCurl
   ```

2. When multiple feature flags require the same build dependency, for example
   derivation has optional support for FTP and HTTP protocols, any of which
   incur dependency on `curl`, and derivation would look like following:

   ```
   { lib, stdenv, curl, withCurl ? true, enableFTP ? true, enableHTTP ? true }:

   # Assertions are fully optional.
   assert enableFTP -> withCurl;
   assert enableHTTP -> withCurl;

   stdenv.mkDerivation {
      ...

      buildInputs = lib.optionals withCurl [ curl ];

      ...
   }
   ```

3. Mutually-exclusive build dependencies that provide the same feature are also
   handled with assertions. For example, if derivation has optional SSL support
   that may be provided by multiple libraries, but only one may be used and it
   must be chosen at compilation time, derivation will look like following:

   ```
   { lib, stdenv, enableSSL ? false, openssl, withOpenSSL ? false, libressl, withLibreSSL ? false }:

   # Assertions are fully optional.
   assert enableSSL -> withOpenSSL || withLibreSSL;
   assert !(withLibreSSL && withOpenSSL);

   stdenv.mkDerivation {
      ...

      # Asserts above make sure that at most one SSL implementation will be in
      # the list.
      buildInputs = lib.optionals withLibreSSL [ libressl ]
                  ++ lib.optionals withOpenSSL [ openssl ];

      ...
   }
   ```

4. When build dependency comes from particular package set, it MAY make sense to
   name feature parameter after it. E.g build dependency on `qt6.qtbase` should
   have `withQt6` feature parameter.

5. If feature parameter name suggested by previous point is too generic,
   package name from the set MAY be included into the feature parameter name.
   Optional dependency on `pythonPackages.pillow` MAY have feature parameter
   `withPythonPillow`.

6. Build dependency on bindings to low-level libraries SHOULD be named after
   underlying library. For example, optional dependecy on `pyqt5` Python
   bindings to `Qt5` library should have `withQt5` feature parameter.


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
- Finding way to get list of all existing feature parameters. That can be possibly done by building and distributing the index separately,
  like [nix-index](https://github.com/nix-community/nix-index) does it.

# Changelog

1. Changed wording to not imply that every upstream build system knob SHOULD be
   exported via feature parameters. (Thx: @7c6f434c)

2. Relaxed wording on the name of feature parameters to avoid painting ourselves
   into ugly and non-intuitive names. (Thx: @7c6f434c)

3. Fix typo in regex to be consistent that feature flag name can't have small
   letter after `with|conf|enable` prefix. (Ths: @don.dfh)

4. Explicitly mention that static code analysis has support for overrides based
   on human judgement call. (Thx: @7c6f434c)

5. Clarify solution scenarios when build inputs and feature flags don't match
   one-to-one. (Thx: @Atemu, @7c6f434c)

6. Refine the deprecation plan to make sure the warning includes the sunset
   timestamp. (Thx: @pbsds)

7. Add rules about non-boolean feature parameters. (Thx: @Atemu, @pbsds)

8. Set expectations for building and maintaining multiple configurations. (Thx: @pbsds)

9. Removed non-boolean parameters from "Future Work" section.

10. Relaxed requirements for assertions about conflicting flags (Thx: @Atemu)

11. Add guideline so `pythonPackages.pillow` does not get `withPython` feature name. (Thx: @7c6f434c)
