---
feature: flake-entrypoint
start-date: 2025-12-08
author: Robert Hensing (@roberth)
co-authors: (to be determined)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Reduce boilerplate in flakes by changing how Nix acquires flake outputs,
allowing frameworks to handle common patterns.
Combined with [RFC 193](https://github.com/NixOS/rfcs/pull/193), this allows all
Nix code to be removed from some flakes.

# Motivation
[motivation]: #motivation

Common flake patterns require repetitive Nix code that could be handled by frameworks if inputs were separated from implementation.

Systems like flake-parts, flake-utils-plus and blueprint already provide abstractions over flake outputs.
This proposal would enable these frameworks to be invoked declaratively,
in a standard way,
without boilerplate.

# Detailed design
[design]: #detailed-design

## Entrypoint selection

Flake output invocation is changed to go through an "entrypoint",
which is the flake that provides a function to help produce the flake output attributes.

If `inputs.entrypoint` exists, Nix uses it as the entrypoint.
Otherwise, Nix uses the built-in entrypoint.

The built-in entrypoint reads `flake.nix` and expects an `outputs` attribute,
maintaining backward compatibility with existing flakes.

## Entrypoint function signature

An entrypoint exposes `outputs.lib.callFlakeEntrypoint`,
which Nix invokes to produce the flake's outputs.

The function receives:

```nix
{
  # The resolved and invoked/dependency-injected flake inputs
  inputs,
  # The parsed flake metadata (currently from flake.nix)
  flakeMeta,
  # The invoked/dependency-injected *result*
  self,
  # The base directory of the flake
  flakeDir,
  # The sourceInfo, where `sourceInfo.outPath` may be `flakeDir` or any
  # parent of it (if applicable; subdirectory flakes)
  sourceInfo,
  # ... is mandatory for forward compatibility
  ...
}:
# Returns standard flake outputs
{
  packages = { ... };
  apps = { ... };
  # etc.
}
```

The `...` parameter is mandatory for forward compatibility.

## flakeMeta schema

The `flakeMeta` parameter contains the flake's metadata,
which is the attribute set from `flake.nix` minus the `outputs` function.

Currently this includes:

```nix
{
  description = "...";  # optional
  nixConfig = { ... };  # optional
  inputs = { ... };     # the input specifications
}
```

When [RFC 193](https://github.com/NixOS/rfcs/pull/193) is implemented,
this data would come from `flake.toml` instead of `flake.nix`.

The entrypoint can use this metadata to inform how it processes the flake,
such as reading the `description` or using `inputs` specifications
to understand the flake's structure.

## Configuration discovery

How entrypoints discover and read their configuration files is framework-specific.
Each entrypoint framework defines its own conventions for configuration.

For example:
- flake-parts might read `flakeModules` from `flake.nix` or `parts.nix`
- `numtide/blueprint` could infer outputs by analyzing the source tree structure
- A hypothetical framework could read `project.toml`

Entrypoints use the provided `flakeDir` parameter to locate files relative to the flake root.

This RFC does not standardize configuration file naming or location,
allowing frameworks flexibility in their design.

## Built-in entrypoint specification

The built-in entrypoint maintains backward compatibility with existing flakes.
When no `inputs.entrypoint` is specified,
Nix uses its current flake evaluation behavior.

Conceptually, this is approximately equivalent to an entrypoint that:
- Reads `flake.nix` from the flake directory
- Evaluates its `outputs` attribute as a function
- Passes the traditional arguments (`self` and the resolved `inputs`)
- Returns the resulting attribute set as the flake's outputs

The actual implementation details of how Nix performs outputs invocation are 
somewhat intricate and some aspects would need to be worked out during prototype development.
The code for this is not provided in this RFC,
but it is derivable by refactoring Nix's `call-flake.nix` in small behavior-preserving steps.

## Compatibility

The following negative space is changed and may require a few projects to adapt if they already use these:
- `inputs.entrypoint` is assigned meaning, changing how flake outputs are formed.

Flakes that do not have `inputs.entrypoint` remain compatible.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

## Current flake.nix

```nix
{
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

## Using framework entrypoint

**flake.nix**:
```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    entrypoint.url = "github:hercules-ci/flake-parts";
    entrypoint.inputs.nixpkgs-lib.follows = "nixpkgs";
  };

  # No outputs function needed - the entrypoint handles it
}
```

**parts.nix** (read by flake-parts entrypoint):
```nix
{ ... }: {
  perSystem = { pkgs }: {
    packages.default = pkgs.hello;
  };
}
```

**Evaluation flow**:
1. Nix sees `inputs.entrypoint` is defined
2. Nix evaluates the flake-parts flake and calls its `outputs.lib.callFlakeEntrypoint`
3. flake-parts receives `flakeDir`, `inputs`, etc. as parameters
4. flake-parts reads `parts.nix` from `flakeDir` (by its own convention)
5. flake-parts processes the module and returns standard flake outputs
6. Those outputs become this flake's outputs

## Implementing an entrypoint

`flake.nix` serves as the base that bootstraps entrypoints.
This example shows what authoring a framework looks like:

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
          # The parsed flake metadata
          flakeMeta,
          # The invoked/dependency-injected *result*
          self,
          # The base directory of flake
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

The built-in entrypoint reads `flake.nix` and expects an `outputs` attribute.
Alternative entrypoints (specified via `inputs.entrypoint`) can implement different conventions.

# Drawbacks
[drawbacks]: #drawbacks

## Breaking change

Projects currently using `inputs.entrypoint` for other purposes would need to rename that input.

This seems unlikely for any given project.

## Adds conceptual complexity

Users need to understand another mechanism beyond the basic `outputs` function,
increasing the learning curve for newcomers to Nix flakes.

## Implicit behavior

The mechanism makes flake evaluation less explicit.
Looking at a `flake.nix` with only `inputs.entrypoint` doesn't immediately show
what outputs will be produced without understanding the entrypoint framework.

However, many hand-written flakes don't make this obvious from reading the code either.

## Mitigatable: Ecosystem fragmentation risk

Multiple competing entrypoint frameworks could emerge,
each with different conventions for configuration and behavior.
This could make it harder for users to understand and switch between different projects.

However, this is already the case.
Entrypoint frameworks can simultaneously implement specific opinions about project conventions,
while agreeing on a common interface for Nix-level extension / composition.

## Non-drawback: Performance overhead

Using an entrypoint adds another flake evaluation to the dependency graph.
Every flake using an entrypoint must evaluate that entrypoint flake first,
which increases evaluation time compared to direct `outputs` functions.

The overhead of the default entrypoint is completely negligible and only paid once per flake.

## Non-drawback: Framework migration cost

Existing frameworks (flake-parts, flake-utils-plus, blueprint) would need to:
- Expose a `lib.callFlakeEntrypoint` function
- Maintain compatibility with their current invocation patterns
- Document and support both usage patterns during transition

However, this is a small effort and they can implement this at their own pace.

## Non-drawback: Debugging difficulty

When an entrypoint fails or produces unexpected outputs,
users must understand both the entrypoint framework's behavior and Nix's invocation mechanism.
Error messages may be less clear than with direct `outputs` functions.

Entrypoints do not make this worse than using a framework in `outputs`.

# Alternatives
[alternatives]: #alternatives

## Keep current structure

Maintain the status quo where frameworks must be manually invoked in each flake's `outputs` function.
This avoids all the drawbacks but continues to require boilerplate in every flake.

## Built-in support for common patterns

Instead of an entrypoint mechanism,
Nix could provide built-in support for common flake patterns
(like per-system iteration or module systems).
This would reduce boilerplate without the indirection layer.

However, this approach would:
- Require extensive design work to identify and standardize patterns
- Make Nix itself more complex and opinionated
- Reduce flexibility for framework authors to innovate
- Still require users to write some Nix code
- Ossify its whole domain due to the combination of Hyrum's law and the desire for reproducibility

## Extend outputs to accept framework function

Allow `outputs` to be set to a framework function directly,
such as `outputs = flake-parts.lib.mkFlake;`.
The framework function would receive similar parameters to `callFlakeEntrypoint`.
However, this would require the input (such as `flake-parts` in this example) to be brought into scope,
requiring that `outputs` is a function, and when `outputs` is a function,
it should probably just be compatible with the status quo semantics for it.
So that puts us back at square one.

This would be less convenient but wouldn't require the `inputs.entrypoint` special case.
However, it still requires writing the function invocation in every flake
and doesn't enable the zero-Nix-code vision when combined with RFC 193.

## Template-based code generation

Use code generation tools (like `nix flake init`) to generate the boilerplate
instead of removing it via abstraction.

This approach keeps flakes explicit but:
- Generated code still needs to be maintained and understood
- Doesn't reduce the amount of code in repositories
- Makes it harder to adopt framework improvements, as it requires regenerating,
  and redoing any changes, flipping the supposed advantage of having the code
  right under your fingers on its head.

## Different entrypoint naming

Instead of `inputs.entrypoint`, use a different name or location
(e.g., `outputs.entrypoint`, `framework`, or a top-level `entrypoint` attribute).

However, `inputs.entrypoint` aligns well with the inputs concept
since the entrypoint is itself a dependency.
The chosen approach keeps the interface and implementation simple.

# Prior art
[prior-art]: #prior-art

## RFC 193 - TOML Flakes

[RFC 193](https://github.com/NixOS/rfcs/pull/193) proposes using `flake.toml` for declarative input specifications.
Combined with the entrypoint mechanism proposed here,
flakes could be derived without *any* custom Nix wiring code,
instead inferring outputs exclusively from the source tree and designated `inputs`.
Expressions could be provided to adjust behavior on an as-needed basis only.

The entrypoint mechanism can be implemented independently of TOML,
but the two features work well together.

## flake-parts, flake-utils-plus and blueprint

Framework systems like flake-parts, flake-utils-plus and blueprint already provide abstractions over flake outputs.
This proposal would enable these frameworks to be specified declaratively,
in a standard way,
without boilerplate.


# Unresolved questions
[unresolved]: #unresolved-questions

- What outcomes result from a prototype of this feature?
- How should errors be reported when an entrypoint fails?
- Should there be a standard way for entrypoints to declare what files they read?

# Future work
[future]: #future-work

- Standardize common entrypoint patterns
- Define metadata fields that entrypoints can use (beyond just inputs)
- Develop tooling for validating entrypoint implementations

# Credit

Having been part of the Nix team,
I suspect that I've learned some of these ideas from the team, especially Eelco.

Thank you to @ruro for raising the good point that the entrypoint mechanism is independent from TOML changes,
enabling this feature to be implemented and discussed separately.
