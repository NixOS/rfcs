---
feature: toml-flakes
start-date: 2025-12-07
author: Robert Hensing (@roberth)
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Make flakes easier to use, automate and learn.

Introduce `flake.toml` as the new leading file for flakes,
separating input specifications from output definitions.
The `flake.toml` file contains declarative metadata and input declarations,
while `flake.nix` focuses on output definitions.

Fixes [#4945 What language is flake.nix written in?](https://github.com/NixOS/nix/issues/4945)

# Motivation
[motivation]: #motivation

Currently, flakes combine two distinct concerns in a single `flake.nix` file:
declaring dependencies (inputs) and implementing functionality (outputs).
This creates several problems:

1. **User uncertainty**: The current structure creates confusion about what language features are available
   and when evaluation restrictions apply,
   because inputs and outputs are mixed in the same file, and inputs are not allowed to be arbitrary Nix expressions.
   See [issue #4945](https://github.com/NixOS/nix/issues/4945).
   Note that while the question was originally asked in a partly rhetorical manner,
   it is still a valid question,
   a variation of which pops into new users' minds.
   Some learning is always required,
   but this is an unnecessary bump in the curve.

2. **Limited automation**: Programmatically editing flake inputs requires Nix AST manipulation,
   which is complex and error-prone compared to editing structured data formats.

By moving input specifications to a simpler format,
we enable better tooling,
reduce user confusion about evaluation restrictions,
and create a clearer separation of concerns between dependency declarations and output implementations.

# Detailed design
[design]: #detailed-design

## File structure

`flake.toml` becomes the leading file,
containing input sources and follows relationships.
It complies with the [Nix JSON guideline](https://nix.dev/manual/nix/latest/development/json-guideline.html) (modulo `null`).

`flake.nix` remains and defines outputs.

## Choice of TOML

See also the [alternatives] section.

A nice aspect of TOML is that its non-nested syntax aligns with part of a definition of _declarative systems_, having a set of _independent statements_.

It has a wide ecosystem of libraries for parsing, as well as good number of libraries that support round tripping edits.

## Relationship to existing files

- `flake.lock` remains unchanged
- `flake.nix` remains and defines outputs, and as a legacy format for the `inputs` and other metadata.

## Compatibility

The design should support reading legacy `flake.nix` files that contain inline input specifications.

The following negative space is changed and may require a few projects to adapt if they already use these:
- A file named `flake.toml` will shadow `flake.nix` in file discovery

Flakes that do not have a `flake.toml` file remain compatible.

A TOML flake can not be evaluated by older implementations of Nix.

Other than those constraints, TOML and traditional flakes can be used and migrated back and forth without compatibility problems, as their usages in the CLI or as an `inputs` dependency do not change.

Validation and adoption can start in flakes with fewer users, such as those without reverse dependencies.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

## Current flake.nix

```nix
{
  description = "A simple example flake exporting GNU hello for x86_64-linux";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages.${system}.default = pkgs.hello;
    };
}
```

## Proposed structure, simple example

**flake.toml**:
```toml
description = "A simple example flake exporting GNU hello for x86_64-linux"

[inputs.nixpkgs]
url = "github:NixOS/nixpkgs/nixos-unstable"
```

**flake.nix**:
```nix
{
  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages.${system}.default = pkgs.hello;
    };
}
```

**flake.lock** remains unchanged.

## Proposed structure with follows

**flake.toml**:
```toml
description = "Example with follows relationships"

[inputs.nixpkgs]
url = "github:NixOS/nixpkgs/nixos-unstable"

[inputs.flake-parts]
url = "github:hercules-ci/flake-parts"

[inputs.flake-parts.inputs.nixpkgs-lib]
follows = "nixpkgs"
```

**flake.nix**:
```nix
{
  outputs = { self, nixpkgs, flake-parts }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      perSystem = { pkgs, ... }: {
        packages.default = pkgs.hello;
      };
    };
}
```

**flake.lock** remains unchanged.

The exact schema shown above is illustrative.
The final design will follow the Nix JSON guideline for extensibility,
using records at appropriate levels and `null` for optional values.

# Drawbacks
[drawbacks]: #drawbacks

- Introduces another file format into the Nix ecosystem
- Migration cost for existing flakes
- Potential confusion during transition period with two ways to specify inputs
- Requires tooling updates across the ecosystem

# Alternatives
[alternatives]: #alternatives

## Keep current structure

Maintain the status quo including drawbacks described in the [motivation].

## Pure Nix with better tooling

Improve Nix AST manipulation tools instead of introducing a new format.
Does not solve user uncertainty.

## Use JSONC

JSONC is somewhat more aligned with the Nix language, including the presence of `null`,
and the approximate syntax for objects/attrsets, while still allowing comments.

## Use YAML

YAML is widely supported but is despised among many for such things as [the Norway Problem](https://hitchdev.com/strictyaml/why/implicit-typing-removed/).

It is hard to parse correctly,
which poses a significant risk for an ecosystem with a major goal of supporting reproducibility,
as even an innocuous whitespace fix in parser output can cause a rift
where binary caches aren't shared between Nix versions and old expressions produce new outcomes.

# Prior art
[prior-art]: #prior-art

## Experimental `configs` commit by Eelco

[1dc3f53](https://github.com/NixOS/nix/commit/1dc3f5355a3786cab37a4de98ca46a859e015d89), part of stable branch [`configs`](https://github.com/NixOS/nix/compare/configs) implemented a `flake.toml` file.
It incorporated a "poor man's module system" into Nix where it would be of very limited functionality,
while it ossifies due the consequences in Nix of [Hyrum's law](https://www.hyrumslaw.com/) and the second order effects of reproducibility.

## Flake entrypoints RFC

A companion RFC proposes a flake entrypoint mechanism that allows frameworks to handle output generation.
Combined with TOML flakes,
this provides the bigger picture of removing custom Nix code from flake metadata altogether,
allowing frameworks to handle both input processing and output generation declaratively.

The entrypoint mechanism can be implemented independently of TOML,
but the two features work well together.

## devenv

The devenv tool uses a separate configuration format for specifying dependencies
and generating Nix configurations,
demonstrating that declarative input specifications can work well in practice.

## Other language ecosystems

Most package managers separate dependency declarations from implementation code (`Cargo.toml`, `requirements.txt`, and to a fair degree `package.json`).
This proposal brings Nix flakes closer to that common pattern.

# Unresolved questions
[unresolved]: #unresolved-questions

- What outcomes result from a prototype of this feature?
- Schema validation for the inputs file
- How follows relationships are expressed in TOML

# Future work
[future]: #future-work

- Evaluate TOML round-tripping libraries

# Credit

Having been part of the Nix team,
I suspect that I've learned some of these ideas from the team, especially Eelco,
who has experimented in this direction.

Also another thank you to username-generic for asking the question in a recent [discourse thread](https://discourse.nixos.org/t/outlining-the-differences-between-flakes-and-nix-configs/72996/7),
and together with TLATER for making me realise I should just go ahead and write this RFC.
