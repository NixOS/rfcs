- Feature Name: simple_override_strategy
- Start Date: 2017-02-26
- Authors: Nicolas B. Pierron, Peter Simons
- RFC PR: 
- Related Issue: (link to related github issues)

# Summary
[summary]: #summary

Change the way of writing packages in Nixpkgs to make the packages more declarative, and to not
require the evaluation of a function.

# Motivation
[motivation]: #motivation

Making Nix packages more declarative, i-e as a simple attribute set, without the *wrapping* of `stdenv.mkDerivation` and
`callPackage`. Using such declarative approach has multiple benefits such as:

- Replace the `override` and `overrideDerivation` functions by the update (`//`) operator.
- Make faster lookup for packages names, as done by the `nix-env` tool.
- Remove reflexivity hacks added by `stdend.mkDerivation` and `callPackage`.
  Do not keep the inputs alive after their evaluations.
- Normalize inputs of packages, to be used for future grafting techniques.

# Detailed design
[design]: #detailed-design

This work add the notion of *view*.  A view is a way to evaluate a set of packages.
 - name view: extract the names of all the packages.
 - licenses view: extract the `meta.license` information, and do the same for dependencies.
 - package view: evaluate the derivation, and register them to the Nix daemon.

In all cases, we have the same inputs, but different ways to *view* the data.

This RFC first introduces:
1. The new way to write packages.
2. How to override such packages.
3. A Recursive Update operator, to remove hierachies of update operators.

## Packages

With this proposal all packages should be written in standalone files, or in the same file as done for python packages.

```nix
self: super: # [0]

{ name = "forty-two-1.0";
  src = super.fetchurl { … };
  drvBuilder = self.stdenv.mkDerivation; # [1]
  buildDeps = { inherit (self) foo bar; }; # [2]
  buildInputs = with :; [ foo ]; # [3]
  buildPhase = with :; /* [4] */ ''
    command ${bar /* [5] */ }
  '';
}
```

The usual list of arguments is replaced by the default `self: super:` arguments [0], which includes
all packages.  The benefit of this approach is that this avoid redundant information, and avoid the
creation of thousands of small attribtue set when looking for names of packages.

The set of dependencies, instead of being given as arguments, are listed in the `buildDeps` attribute
set[2].  This is equivalent to the set generated currently by the `callPackage` function, as an
intersection of the names expected by the functions, and the packages available in `self`.

The new syntax `with :;` [3][4] is detailed below, while describing how to override such attribute set.

## Overrides

Today, `callPackage` add the ability to `.override` the arguments of the function.  This override
ability is provided by keeping the original function instance.  With this new approach, there is
no need to keep the original function, but only its attribute set result.  As any other attribute set,
we can use the update (`//`) operator on the `buildDeps` attribute [2].

With this new design, an overlay which would replace a dependency by a different version would look like:

```nix
self: super:

{
  fortytwo_1_0 = super.fortytwo_1_0 // {
    buildDeps = super.fortytwo_1_0.buildDeps // {
      foo = self.foo_1_21; # [9]
    };
  };
}
```

This approach being quite verbose, would need some additional syntax to express recursive updates of
attribute sets.  A suggestion is described below, on a new syntax to support recursive updates of
attribute sets.

The list of build dependencies [2] is processed by the `drvBuilder` function [1], which is called on
the attribute set which contains it.

```nix
pkg: pkg.drvBuilder pkg
```

The `drvBuilder` function [1] is responsible for applying the `drvBuilder` function on
the list of build dependencies [2]. Once this set computed, it is given as argument to other attributes
which are starting with `with :;`, such as `buildInputs` [3] and `buildPhase`.

Attributes such as `buildInputs`[3] are starting with the `with:; …` syntax.  This is a new Nix
language syntax is used to force all names on the right-hand-side to be *strictly* dynamically scoped.
This is equivalent to have a *new file* with the expression `args: with args; …`, where the `args`
binding is hidden.

Using a strictly dynamically scoped names will prevent any of the attribute names to refer
to names which are not explicitly listed as part of the build dependencies (`buildDeps`).  Thus,
if a variable is not bound the writer of the Nix expression would be notified to add it in the
`buildDeps` attribute set.

Ideally the `drvBuilder` function should check that attributes such as `buildInputs` are asserted
to be valid under the `isDynamicScopedFunction` predicate that should be added to the builtins.

To override and extend the `buildPhase` attribute, we need additional semantic to the dynamically
scoped functions, i-e that the hidden attribute set should be added as part of the evaluation
environment, and be used by other dynamicaly scoped function which are wrapped under the evaluation.

Also, as the dynamically scoped function are stricly removing every binding from the out-side, we
have to explicitly inherit it, as the following example show:

```nix
self: super:

{
  fortytwo_1_0 = super.fortytwo_1_0 // {
    buildPhase /* [6] */ = with : // { inherit (super.fortytwo_1_0) buildPhase /* [7] */; }; ''
      ${buildPhase /* [8] */}
      other_command ${foo}
    '';
  };
}
```

This overriden package will evaluate the `buildPhase` [6] as to a string.  This string interpolates
the evaluation of the `buildPhase` [8], which is inherited [7] from the out-side and corresponds to
the evaluation of the previous `buildPhase`[4].

The dynamic scope given to the `buildPhase` [6], and provided by the evaluation of the `buildDeps` [2]
by the `drvBuilder` [1], is forwarded seamlessly to any dynamically scoped function under it, such as
the `buildPhase` [8] evaluation, inherited from the overriden attribute set.

Thus, the interpolation of `foo` and `bar` [5], correspond to the `outPath` of the derivation provided
by the `drvBuilder` as the dynamic scope.

At this stage, overriding the dependencies [2] or the recipe of a package [4] is performed with the update
`//` operator.  This respectly replaces the need for the `override` and `overrideDerivation` functions, and
by such any need for reflexivity.

## Recursive Update

Unfortunately the update operator is quite verbose, as we have to repeat all the
names at each level of the attribute set.  To makes this easier to manipulate we would have to
promote the `recursiveUpdate` function to give it some syntax as well.  Also, we need a way to stop
the recursiveUpdate to avoid recursive updates in the attribute `foo` [9] of the `buildDeps` attribute.

The update operator `//`, is only updating the top-level attribute set.  A recursive update operator
need a way to *start zipping* (`/</`) attribute sets, and to *stop zipping* (`/>/:`) them to default to
the update logic.

Also, we need a way to refer to the original attribute set, such that we can alias the `buildPhase` [7],
without repeating the package name.  In the following example, this is achieved with the stop operator,
which alias the left-hand-side value of the update operator (`/>/@lhs:`).

```nix
self: super:

{
  fortytwo_1_0 = super.fortytwo_1_0 /</ {
    buildDeps.foo = />/: self.foo_1_21; # [9]
    buildPhase = />/@buildPhase: with : // { inherit buildPhase; }; ''
      ${buildPhase}
      other_command ${foo}
    '';
  };
}
```

# Drawbacks
[drawbacks]: #drawbacks

One of the biggest drawback of this RFC is that we would have to convert all packages written in
Nixpkgs to this new format, which would mess-up with the history. We probably have solutions to
migrate most of the packages to the new scheme by using the `callPackage` and `stdenv.mkDerivation`
functions to convert existing expressions to the new scheme.

This feature require the addition of extra Nix syntax, which might have not easy semantics, as it
would depend on the evaluation environment.

# Alternatives
[alternatives]: #alternatives

Today, packages are written as

```nix
{stdenv, fetchurl, foo, bar}:

stdenv.mkDerivation {
  name = "forty-two-1.0";
  src = fetchurl { … };
  buildInputs = [ foo ];
  buildPhase = ''
    command ${bar}
  '';
}
```

This example highlight that the arguments of a package can either be used as a `buildInputs` or
directly interpolated in a string, such inside the `buildPhase`.

The new scheme proposed as part of this RFC, which is detailed below, consists of moving the
`mkDerivation` under the set which would be given to it as argument.  Doing this only one step would lead
us to the following way of writing:

```nix
{stdenv, fecturl, foo, bar}:

{ mkDerivation = stdenv.mkDerivation;
  name = "forty-two-1.0";
  src = fetchurl { … };
  buildInputs = [ foo ];
  buildPhase = ''
    command ${bar}
  '';
}
```

This way of writing Nix packages removes the evaluation of `mkDerivation` function, but this has
some side issues.

We assume that `foo` and `bar` are derivation which can be interpolated as a derivation. This
implies that there is some logic to convert these sets to a derivation.  Thus the `callPackage` function now becomes
responsible of calling the `mkDerivation` function provided by this set with this set as argument.
This has the issue that we have to evaluate the function twice, once to get the `mkDerivation`
fucntion, and a second time to evaluate it.  Fortunately, this limitation is removed from
`callPackage` once we remove the list of arguments, as suggested in this RFC.

# Unresolved questions
[unresolved]: #unresolved-questions

 - Should we evaluate all derivations as part of `self`, or as part of the `drvBuilder` function?
