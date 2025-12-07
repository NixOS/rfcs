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
while `flake.nix` (read by the default entrypoint) or a framework focuses on output definitions.

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

3. **Boilerplate**: Common flake patterns require repetitive Nix code
   that could be handled by frameworks if inputs were separated from implementation.

By moving input specifications to a simpler format,
we enable better tooling,
reduce user confusion about evaluation restrictions,
and create a clearer separation of concerns between dependency declarations and output implementations.

# Detailed design
[design]: #detailed-design

## File structure

`flake.toml` becomes the leading file,
containing input sources, follows relationships, and entrypoint selection.
It complies with the [Nix JSON guideline](https://nix.dev/manual/nix/latest/development/json-guideline.html) (modulo `null`).

Flake output invocation is changed to go through an "entrypoint", which is the flake that provides a function to help produce the flake output attributes based on the source tree of `flake.toml`.
If `flake.toml` has an `entrypoint` field, it must name one of the `inputs` which will serve as the entrypoint.
Otherwise, if an input named `"entrypoint"` exists, it becomes the entrypoint.
Finally if `flake.nix` exists, the entrypoint is the default entrypoint.

`flake.nix` is read by the default entrypoint and defines outputs.

## Choice of TOML

See also the [alternatives] section.

A nice aspect of TOML is that its non-nested syntax aligns with part of a definition of _declarative systems_, having a set of _independent statements_.

It has a wide ecosystem of libraries for parsing, as well as good number of libraries that support round tripping edits.

## Relationship to existing files

- `flake.lock` remains unchanged
- Alternative entrypoints (referenced in `flake.toml`) can read different files
- `flake.nix` remains supported as the default entrypoint, and as a legacy format for the `inputs` and other metadata.

## Compatibility

The design should support reading legacy `flake.nix` files that contain inline input specifications.

The following negative space is changed and may require a few projects to adapt if they already use these:
- A flake input named `entrypoint` is assigned meaning, changing how flake outputs are formed.
- A file named `flake.toml` will shadow `flake.nix` in file discovery

Flakes that do not have any of the above elements remain compatible.

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

**flake.nix** (read by default entrypoint):
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

## Proposed structure, framework entrypoint

**flake.toml**:
```toml
description = "A simple example flake exporting GNU hello for x86_64-linux"

[inputs.nixpkgs]
url = "github:NixOS/nixpkgs/nixos-unstable"

[inputs.entrypoint]
url = "github:hercules-ci/flake-parts"

[inputs.entrypoint.inputs.nixpkgs-lib]
follows = "nixpkgs"
```

**parts.nix** (read by default entrypoint):
```nix
{ ... }: {
  perSystem = { pkgs }: {
    packages.default = pkgs.hello;
  };
}
```

**flake.lock** remains unchanged.

## Entrypoint function

`flake.nix` serves as the base that bootstraps entrypoints.
This example shows what authoring a framework looks like.
An entrypoint is invoked as `<flake outputs>.lib.callFlakeEntrypoint`:

```nix
{
  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages.${system}.default = pkgs.hello;

      # Entrypoints are accessed here
      lib.callFlakeEntrypoint =
        { 
          # The resolved and invoked/dependency-injected flake inputs
          inputs,
          # The parsed flake.toml
          flakeToml,
          # The invoked/dependency-injected *result*
          self,
          # The base directory of flake.toml
          flakeDir,
          # The sourceInfo, where `sourceInfo.outPath` may be `flakeDir` or any
          # parent of it (if applicable; subdirectory flakes)
          sourceInfo,
          # ... is mandatory for forward compatibility
          ...
        }:
        # Imagine some useful expression, returning the usual flake outputs
        {
          packages = { ... };
          apps = { ... };
        };
    };
}
```

The default entrypoint reads `flake.nix` and expects an `outputs` attribute.
Alternative entrypoints (specified in `flake.toml`) can implement different conventions.

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
Does not solve boilerplate.

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

## devenv

The devenv tool uses a separate configuration format for specifying dependencies
and generating Nix configurations,
demonstrating that declarative input specifications can work well in practice.

They have also integrated input declarations and input usage in their application of the module system.
This RFC could be extended or followed up with a metadata feature that generalizes this idea and allows an entrypoint to achieve a similar effect.

```toml
[inputs.entrypoint]
url = "github:cachix/git-hooks.nix"
# forwarded as e.g. `inputUsages.<input>` to entrypoint, so it can import/enable/etc as intended.
usage = [ "flake-parts" ]
```

## flake-parts, flake-utils-plus and blueprint

Framework systems like flake-parts, flake-utils-plus and blueprint already provide abstractions over flake outputs.
This proposal would enable these frameworks to be specified declaratively,
in a standard way,
without boilerplate.

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
