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

Making Nix packages more declarative, and without the usual `stdenv.mkDerivation`, nor
`callPackage` functions provide multiple benefits such as:

 - Replace the `override` and `overrideDerivation` functions by the update (`//`) operator.
 - Make faster lookup for packages names, as done by the `nix-env` tool.
 - Remove the unused memory held by `stdend.mkDerivation` and `callPackage` to be garbage collected by the Nix interpreter.
 - Normalize inputs of packages, to be used for future grafting techniques.

# Detailed design
[design]: #detailed-design

To install a package, we want to resolve a package attribute path to a derivation.  To list all
available packages, we want to resolve a package attribute path to a name.  To list all licences we
want to list all the meta-data of packages.

In all cases, we have the same input, but a different way to *view* the data provided by the
packages.  In one case we are interested in viewing the packages as a derivation, which generates
the derivation files, in an other case we are looking for the `name`, or `meta.license` attributes,
and we might even want to follow the dependencies as well.

Packages should be written as:

```nix
super: self: # [0]

{ name = "forty-two-1.0";
  src = super.fetchurl { … };
  drvBuilder = self.stdenv.mkDerivation; # [1]
  buildDeps = { inherit (self) foo bar; }; # [2]
  buildInputs = @: [ foo ]; # [3]
  buildPhase = @: ''
    command ${bar /* [4] */ }
  '';
}
```

The usual list of arguments is replaced by the default `super: self:` arguments [0], which includes
all packages.  This makes the call convention simple which provides the same set of arguments to all
packages, which avoid the creation of thousands of small attribute sets which have to be held alive
in order to be overriden.

The list of dependencies can still be overriden by using the `//` operator on the `buildDeps` [2]
attribute of the package.  Thus replacing a dependency by a different version follow the following
logic:

```nix
super: self:

{
  fortytwo_1_0 = super.fortytwo_1_0 // {
    buildDeps = super.fortytwo_1_0.buildDeps // {
      foo = self.foo_1_21;
    };
  };
}
```

The list of build dependencies [2] is processed by the `drvBuilder` function [1], which is called on
the attribute set which contains it.  To make all top-level packages of Nixpkgs be evaluated as a
derivation, we would have to use the following Nix expression:

```nix
let pkgs = (import <nixpkgs> {});
    asDerivation = deps: attrsMap (pkg: pkg.drvBuilder pkg) deps;
in asDerivation pkgs;
```

The `drvBuilder` function [1] is responsible for recursively applying the `asDerivation` function on
the list of build dependencies [2], before giving the evaluated set to a few specialized attributes
expected by the `drvBuidler` function, such as `buildInputs` and `buildPhase`.

Attributes such as `buildInputs`[3] are defined with the `@: …` syntax.  This Nix language syntax is
used to force all names on the right-hand-side to be strictly dynamically scoped.  This is
equivalent to have a new file with the expression `args: with args; …`, where the `args` binding is
hidden.  Using a strictly dynamically scoped names will prevent any of the attribute names to refer
to names which are not explicitly listed as part of the dependencies.  Ideally the `drvBuilder`
function should check that attributes such as `buildInputs` are asserted to be valid under the
`isDynamicScopedFunction` predicate that should be added to the builtins.

In order to simplify the override of the recipe we should have the evaluation of dynamic scoped
functions be dependent on the evaluation environment.  If a dynamic scoped function is not apply to
any attribute set argument and it is being evaluated, then it should called with the same argument
of the last dynamic scoped function call.  Such rule is needed in order to avoid boiler plate code
when overriding values such as `buildPhase`.

```nix
super /* [5] */: self:

{
  fortytwo_1_0 = super.fortytwo_1_0 // {
    buildDeps = super.fortytwo_1_0.buildDeps // {
      inherit (self) bad;
    };
    buildPhase /* [6] */ = @{ inherit (super.fortytwo_1_0) buildPhase /* [7] */; }: ''
      ${buildPhase /* [8] */}
      other_command ${bad}
    '';
  };
}
```

Thus, with the previous rule, `buildPhase` [6] which evaluates to a string, is called with the
attribute set which contains the derivations of `foo`, `bar` and `bad`.  This attribute set is then
pass down to the dynamically scoped function call [8] which corresponds to the previous `buildPhase`
[4], as `buildPhase` [7] is explicitly bound to the outer scope through the `super` [5] argument.

At this stage, overriding the dependencies or the recipe of a package is performed with the update
`//` operator.  Unfortunately the update operator is quite verbose, as we have to repeat all the
names at each level of the attribute set.  To makes this easier to manipulate we would have to
promote the `recursiveUpdate` function to give it some syntax as well.  Also, we would need to stop
the recursiveUpdate to avoid recursive updates of `foo` in the `buildDeps` attribute.


# Drawbacks
[drawbacks]: #drawbacks

One of the biggest drawback of this RFC is that we would have to convert all packages written in
Nixpkgs to this new format, which would mess-up with the history. We probably have solutions to
migrate most of the packages to the new scheme by using the `callPackage` and `stdenv.mkDerivation`
functions to convert existing expressions to the new scheme.

This feature require the addition of extra Nix syntax, which might have not easy semantics, as it
would depend on the evaluation environ, in a similar way as error messages are produced with
`addErrorContext`.

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

 - Find a syntax for a `recursiveUpdate` operator
