---
feature: python-scope-package-set
start-date: 2018-02-24
author: Frederik Rietdijk
co-authors:
related-issues:
---

# Summary
[summary]: #summary

The Nix Packages collection (Nixpkgs) is a large collection of packages. A
significant portion of these packages are written in the Python language or are
to be used by a Python interpreter. A distinction is made in this RFC between
*applications* that happen to be written in Python and *libraries* which are
Python packages that are used in a development environment. This RFC formalizes
and thereby clarifies this distinction and defines as well the scope of the
*package set*, which is a curated set of compatible libraries that can be used
in a development environment.

# Motivation
[motivation]: #motivation

The motivation of this RFC is to formalize and thereby clarify the current way
of working regarding the package set scope. The reason to have this formalized
is to have a clear reference and guideline when making the daily decisions about
what to include or exclude from the package set.

# Detailed design
[design]: #detailed-design

## Introduction

The Nix Packages collection (Nixpkgs) consists of a large amount of expressions
of which a significant portion corresponds to package sets. Major package sets
at the time of writing exist e.g. for the Haskell, Perl and Python languages.
The scope and way working with these package sets depends on multiple factors,
such as the tools provided upstream, the demand from the community and the
maintainers of the package sets and the individual expressions. Another
important factor is whether *upstream* provides a curated set of packages that
are known to be compatible. An example of a curated set or snapshot is Stackage
for Haskell. If such set exists and serves the needs from the community, then
the scope may be limited to providing that set.

## Definitions

The following definitions are used in the scope of this RFC:
- application: a package providing programs that happen to be written in Python
- library: a package providing modules and programs that are used in a Python environment for development purposes or as dependency for applications
- package set: a curated set of compatible libraries that can be used in a development environment and as dependencies for applications
- maintainer: a maintainer of an expression as typically noted in the `meta.maintainers` field
- package set maintainer: a maintainer of the Python package set as noted in the `CODEOWNERS` file

Examples on the usage of application and library:
- `scipy` is a collection of routines for scientific computing. It is used for development purposes or as a library and is therefore considered a *library*
- `calibre` is a program for managing e-books that happens to be written in Python. The package is therefore considered an *application*
- `pytest` is a test runner. While a program, it can only be used in conjunction with the Python environment where it needs to import the modules that are to be tested. It is therefore considered a *library*

## Scope of the package set

The purpose of the package set is to provide a set of compatible libraries that
can be used for development purposes and as dependencies by Python applications.
Applications are not considered part of the package set and their expressions
shall thus also be placed elsewhere.

For each NixOS release, a set of compatible libraries shall be formed
that functions on all supported platforms, interpreter versions and
implementations.

That in effect means only one version of a package is permitted as having
multiple versions in the set may lead to collisions. Exceptions can be made,
like in the case of build or test-time dependencies like the `pytest` test runner.

## Contributing and maintaining expressions

Maintenance of the expressions takes effort. All expressions shall therefore
have a maintainer. Packages that have no maintainer may be removed from the
package set or marked as broken in case they seem to be unused, untouched in an
extended period of time, or in whatever way cause additional work for other
maintainers or package set maintainers. Guidelines for contributing expressions
to the package set shall be made available in the Nixpkgs manual.

# Drawbacks
[drawbacks]: #drawbacks

-

# Alternatives
[alternatives]: #alternatives

## Use expression generators for package set

Instead of manually creating a curated set of packages, an expression generator
such as `pypi2nix` could be used. Using an expression generator could reduce the
amount of work needed for writing and updating expressions. The `pypi2nix` tool
uses `pip` to resolve dependencies.

This is not recommended because:
- non-Python dependencies are not specified upstream
- excessive pinning of dependencies can lead to an unsatisfiable set
- curated sets need to be generated for multiple combinations of platforms,
interpreter versions and implementations. That requires being able to check out
the upstream database (PyPI) at a certain state. While technically possible, no
solutions are yet available.

## Limit scope to application dependencies

The scope of the package set could be limited to only providing dependencies for
*applications*. Developers could use 3rd-party expression generators like
`pypi2nix` to create expressions for development purposes. This is not
recommended because:
- applications can vary significantly in their dependencies, requiring different
versions of packages, negating the use of a shared package set
- of the reasons against using expression generators.


# Unresolved questions
[unresolved]: #unresolved-questions

-

# Future work
[future]: #future-work

No future work is implied by this RFC as it describes the current informal way of working.