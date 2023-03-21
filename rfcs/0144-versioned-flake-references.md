---
feature: versioned-flake-references
start-date: 2023-03-19
author: figsoda
co-authors: None
shepherd-team: None
shepherd-leader: None
related-issues: None
---

# Summary
[summary]: #summary

Flake references can have a special placeholder that will specify the version
requirement of the flake, which `nix flake update` can use to update the pin to
the latest version compatible with the version specification. A new Nix
command, `nix flake upgrade` will upgrade the version requirement in
`flake.nix` to the latest possible version without regard to compatibility.

# Motivation
[motivation]: #motivation

This will allow Nix libraries to be versioned without requiring their users
to manually update them. Some package managers (e.g. cargo) for more
conventional programming languages have this functionality built-in, allowing
library authors to introduce breaking changes in a communicatable way that will
not break their downstream dependents's code.

# Detailed design
[design]: #detailed-design

## Syntax
Version placeholders will be in `{}`, with a list of version requirements
separated by `,` (commas), e.g. `{^1.0,<3}` will expand to a version that
specifies the version requirements `^1.0` and `<3`

Version requirements consists of a comparator and version. The version does not
have to be a valid version defiined by the versioning scheme, `1` and `1.0` are
also valid versions for version requirements. The comparator has to be one of
the following options:
- `^` compatible (as defined by the versioning scheme)
- `<` less than
- `<=` less than or equal to
- `>` greater than
- `>=` greater than or equal to
- `=` equal to

A version placeholder with no version requirements will match all valid
versions defined by the versioning scheme.

## Versioning scheme
The versions will follow [semantic versioning] (semver). The tags have to
follow semver, `1.0` and `1.0.0.0` will not match the placeholder `{=1.0}` as
it is not a valid version defined by semver. Build identifiers will not be
taken into consideration when calculating version requirements, and the latest
tag will be selected if multiple tags have the same precedence defined by
semver.

## Upgrading
A new Nix command, `nix flake upgrade`, will edit `flake.nix` and upgrade all
the version placeholders in the inputs. A new flag, `--upgrade-input` will
upgrade only the specified flake input. Only version placeholders that contain
exactly one version requirement which the comparator is either `^` or `=` will
be upgraded. All other version placeholders will be left unchanged.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

Here are the git tags of a hypothetical Nix flake "github:foo/bar":
- v0.1.0
- v0.1.1
- v0.2.0
- v1.0.0
- v1.0.1
- v1.1.0
- v2.0.0
- unrelated

Flake reference | The tag it points to | The `upgrade`ed flake reference
-|-|-
`github:foo/bar/v{^1}` | `v1.1.0` | `github:foo/bar/v{^2}`
`github:foo/bar/v{=1.0}` | `v1.0.1` | `github:foo/bar/v{=2.0}`
`github:foo/bar/v{^1.0}` | `v1.1.0` | `github:foo/bar/v{^2.0}`
`github:foo/bar/v{=1.0.0}` | `v1.0.0` | `github:foo/bar/v{=2.0.0}`
`github:foo/bar/v{^1.0.0}` | `v1.1.0` | `github:foo/bar/v{^2.0.0}`
`github:foo/bar/v{^0.1.0}` | `v0.1.1` | `github:foo/bar/v{^2.0.0}`
`github:foo/bar/v{<2}` | `v1.1.0` | `github:foo/bar/v{<2}` (no change)
`github:foo/bar/v{>1.0}` | `v2.0.0` | `github:foo/bar/v{>1.0}` (no change)
`github:foo/bar/v{^1,<1.1}` | `v1.0.1` | `github:foo/bar/v{^1,<1.1}` (no change)
`github:foo/bar/v{}` | `v2.0.0` | `github:foo/bar/v{}` (no change)

# Drawbacks
[drawbacks]: #drawbacks

- This is impossible with some types of flake references, such as `path`s and
  tarballs, which will make the flake interface less consistent.
- This adds extra complexity to `nix flake update`.
- The difference between `update` and `upgrade` might cause confusion.

# Alternatives
[alternatives]: #alternatives

- Using a different syntax for the placeholders
- Using a version scheme other than semantic versioning
- Adding flags to `nix flake update` instead of creating a new `upgrade` command
- Not having an `upgrade` command or a `--upgrade-input` flag
- Not adding the feature, manually update the flake references

# Unresolved questions
[unresolved]: #unresolved-questions

- How will this work in query parameters?
- Should only tags be used, or should branches also be considered?
- Should whitespace be allowed in the version placeholders?

# Future work
[future]: #future-work

[semantic versioning]: https://semver.org/
