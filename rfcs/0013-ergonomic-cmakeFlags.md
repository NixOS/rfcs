---
feature: ergonomic_cmakeFlags
start-date: 2016-08-20
author: Aneesh Agrawal
co-authors: (find a buddy later to help out with the RFC)
related-issues: https://github.com/NixOS/nixpkgs/pull/17886
---

# Summary
[summary]: #summary

Make usage of `cmakeFlags` in Nixpkgs more ergonomic
by representing them as structured data in the form of attribute sets,
and passing them more intelligently to the builder.

# Motivation
[motivation]: #motivation

Improvements:
- Enable first-class Nix handling of `cmakeFlags`,
  including easier extension and overriding
- Handle spaces, newlines and other whitespace correctly
- Make it possible to reference build-time environment variables directly

# Detailed design
[design]: #detailed-design

There are two main parts to this change:
- Using attribute sets for `cmakeFlags` in Nix
- Passing `cmakeFlags` to the builder more intelligently

## Using Attribute Sets for `cmakeFlags`

Almost all flags passed to `cmakeFlags` are setting CMake cache options
with `"-D<name>=<value>"` or `"-D<name>:<type>=<value>"`.
Because the CMake cache is essentially a set of keys and values,
model `cmakeFlags` as an attribute set in Nix as well.

`mkDerivation` will take an incoming `cmakeFlags` set and convert each
key/value pair to an appropriate `"-D"` option for CMake. String values
are used as is, while integers are converted to strings and booleans are
converted to `"ON"` and `"OFF"`. This presents the following benefits:
- Removal of `"-D"` visual noise everywhere for ease of reading.
- The `=` operater is literal, allowing extra whitespace for more ease
  of reading.
- CMake options are now first class Nix values that can be operated on
  directly with the full strength of the Nix language. For example,
  boolean values can be used directly because the serialization logic is
  consolidated into `mkDerivation`, getting rid of helpers like `edf`
  and making it easier to re-use feature flags like `pythonSupport`.
- Sets automatically sort options, improving cache re-use.
- An override which updates a CMake flag option will only incur
  (amortized) O(1) cost with a set, as opposed to O(n) cost with an
  (unsorted) list, which would require a full linear search. It's also
  shorter to write: just use `//`.

A few other CMake flag types are supported:
- Setting a value to null will cause its key to be unset via `"-U<name>"`.
- The `generator` key is mapped to the `"-G<value>"` option.
- The `extraArgs` key is an escape hatch; any flags in this list of
  strings are not pre-processed, but concatenated to the generated list.

Because `cmakeFlags` will now be processed by `mkDerivation`,
`overrideAttrs` should be used instead of `overrideDerivation`
when overriding `cmakeFlags`.

TODO: Add example(s)

## Passing `cmakeFlags` to the builder more intelligently

Nix's regular conversion of lists to an environment variable
simply concatenates the contents with spaces,
which breaks if any of the flags themselves contain spaces.
`cmakeFlagsArray` was added as a way to get around this limitation,
but is unsatisfactory to use because items must be appended via bash
in a preConfigure hook.

Instead, pass the list to the builder in a smarter way:
instead of relying on Nix's conversion to a string,
perform our own conversion by escaping double quotes,
double quoting each item, and passing the flags as a Bash array,
which is hydrated via `eval`.

This handles flags with spaces, newlines and other whitespace,
as well as double quotes, faithfully.
We already use `eval` heavily in Nixpkgs builders,
so this does not pose any additional security risks.

Additionally, the use of eval makes it possible to reference build-time
environment variables such as `$out` directly when setting `cmakeFlags`,
instead of needing to set up these flags in `preConfigure`.

Make the list available during preConfigure as a bash array, so any
dynamic modifications to the CMake flags can be done there.

These changes make also `cmakeFlagsArray` redundant,
so remove and replace it in all cases with `cmakeFlags`.

TODO: Add example(s)

## Implementation Mechanics

There is already a WIP PR in Nixpkgs for an earlier version of these changes,
at https://github.com/NixOS/nixpkgs/pull/17886.
Locally I have a version of this patch that implements this updated behavior.
If accepted, there are currently 319 files in Nixpkgs containing `cmakeFlags`.
My local patch already has updates for some of these packages;
if this RFC is accepted I will update the rest.
This is a small enough number to do by hand in a few days.

# Drawbacks
[drawbacks]: #drawbacks

This complicates `mkDerivation` with code used only by a subset of packages,
which will increase evaluation time (TODO: quantify impact)
and decrease modularity due to special casing `cmakeFlags`.
Finding a way around this is one of the unresolved questions.

This causes a fair amount of code churn and may cause regressions.
Careful review and testing, plus potentially a temporary Hydra jobset,
should hopefully minimize any regressions.

# Alternatives
[alternatives]: #alternatives

Keep the existing mechanism, which works (but is awkward).

# Unresolved questions
[unresolved]: #unresolved-questions

I would like to find a way to move
the `cmakeFlags` related code into the CMake-related derivations
so that it is automatically included when `cmake` is in `buildInputs`,
instead of putting this code in `mkDerivation`.
This should remove any evaluation overhead if CMake is not being used
and make for a cleaner implementation.

# Future work
[future]: #future-work

If this is successful, I would hope to see similar approaches taken for
e.g. `configureFlags`, and in general more uses of structured data passing.
