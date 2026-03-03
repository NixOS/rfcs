---
feature: sandbox-nix-evaluator
start-date: 2026-03-03
author: bgl gwyng
co-authors:
shepherd-team:
shepherd-leader:
related-issues:
  - https://github.com/NixOS/rfcs/pull/68
  - https://github.com/NixOS/rfcs/pull/8
  - https://github.com/NixOS/rfcs/pull/17
  - https://github.com/NixOS/nix/issues/12607
---

# Summary
[summary]: #summary

Run the Nix evaluator — and any alternative frontend — inside the same sandbox used for builds, with a mounted Nix daemon socket as the sole interface to the store. This inverts the current relationship: instead of an unsandboxed evaluator invoking sandboxed builds, an evaluator runs inside a sandbox and requests store operations through the daemon.

# Motivation
[motivation]: #motivation

Today, when Nix builds a derivation, it creates a sandbox (Linux namespaces, macOS sandbox-exec), places the builder inside, and mounts a daemon socket so the build can request store operations. The evaluator, by contrast, runs **outside any sandbox**. In multi-user mode it already communicates with the store through the daemon socket — but the evaluator process itself is unconstrained: it has full network access, can read the entire filesystem, and is not isolated in any way.

This asymmetry gives the Nix language a privileged position:

- `nix build`, `nix develop`, `nix flake` — all CLI entry points invoke the Nix evaluator. There is no sanctioned path to the store that does not go through the Nix language.
- The evaluator's purity is a language-level property, not an OS-enforced one. Even in multi-user mode where store operations go through the daemon, nothing prevents the evaluator from performing arbitrary I/O during evaluation. We *trust* the evaluator not to do this; we don't *enforce* it.
- Alternative frontends (GNU Guix's Guile, or any hypothetical Python/Rust/Go-based package tool) cannot participate as equals. Guix had to rebuild its entire package set from scratch. There is no "just speak the store protocol" option.

The solution is straightforward: apply the same sandboxing we already use for builds to evaluation. The daemon socket mechanism already exists. The sandbox infrastructure already exists. We simply need to put the evaluator on the same side of the sandbox boundary as the builder.

# Detailed design
[design]: #detailed-design

## The inversion

Currently (multi-user mode):

```
Nix Evaluator (unsandboxed)
  |
  |-- talks to daemon for store operations
  |-- but: has full network access
  |-- but: can read entire filesystem
  |-- but: purity enforced only by language semantics
  |
  \--> daemon creates sandbox for build
         \-- builder runs inside sandbox
         \-- daemon socket mounted for store access
```

Proposed:

```
Nix Daemon (manages store, creates sandboxes)
  |
  \--> creates sandbox for evaluation
         |-- evaluator runs inside sandbox
         |-- daemon socket mounted (same mechanism as builds)
         |-- no network access
         |-- filesystem restricted to source inputs
         |-- purity enforced by OS, not by language
         |
         \--> requests build through daemon socket
                \-- daemon creates nested sandbox for build
```

The key insight: Nix already sandboxes builds and provides daemon socket access inside the sandbox. This RFC applies the same pattern to evaluation. The evaluator becomes just another sandboxed process that talks to the daemon, identical in privilege level to a builder.

## What changes for the evaluator

In multi-user mode, the evaluator already uses the daemon protocol for store operations. What changes is the **execution environment**: the evaluator process is now confined to a sandbox with no network access and restricted filesystem access. `builtins.fetchurl` and `builtins.path` continue to go through the daemon — but now this is the *only* way to perform I/O, enforced by the sandbox rather than by language semantics.

## What changes for alternative frontends

Nothing special. Any program that can speak the daemon protocol through a Unix socket can produce derivations. A Python script, a Rust binary, a Guile program — all run inside the same sandbox with the same daemon socket. The Nix language becomes one frontend among many, distinguished only by the size of its ecosystem (nixpkgs), not by architectural privilege.

## What happens to IFD and Recursive Nix

They stop being special cases. IFD is currently "evaluation pauses, triggers a build, resumes with the result" — a special code path. Under this proposal, the evaluator simply sends a build request through the daemon socket and reads back the output path. This is an ordinary protocol interaction, the same thing builders already do with Recursive Nix. The distinction between "evaluation-time store access" and "build-time store access" disappears because both go through the same socket in the same kind of sandbox.

## Trust model

Currently, the evaluator's purity is trusted but not enforced. Even in multi-user mode, the daemon constrains *what the evaluator can do to the store*, but not *what the evaluator can do outside the store* (read files, access the network, observe system state). Under this proposal, the sandbox constrains all of the evaluator's capabilities. The kernel enforces isolation; the daemon validates store operations. The combination is a strictly stronger guarantee than language-level purity alone.

## Migration path

1. **Stabilize the daemon protocol.** Document and version it as a public interface. (Nix 2.32 has begun this work with the derivation JSON format.)
2. **Decouple the evaluator from libstore.** The Nix project is already exploring this ([NixOS/nix#12607](https://github.com/NixOS/nix/issues/12607)): separating the "language proper" from store-dependent primops, so the evaluator can operate purely through the daemon protocol.
3. **Sandbox the evaluator.** Run the evaluator in a sandbox with only a daemon socket and source inputs. Validate against nixpkgs.
4. **Publish client libraries.** With a stable protocol, provide libraries in Rust, Python, etc. for building alternative frontends.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

A user runs `nix build nixpkgs#hello`. The CLI asks the daemon to spawn a sandboxed evaluation. The evaluator starts inside the sandbox, reads the flake, evaluates the Nix expression, and sends derivation registrations through the daemon socket. When the evaluator finishes, the daemon builds the resulting derivations in their own sandboxes as usual. From the user's perspective, nothing changes.

A developer writes a Python-based package generator. It runs in the same kind of sandbox, sends derivations as JSON through the daemon socket, and requests builds. It has exactly the same store access as the Nix evaluator — no more, no less.

# Drawbacks
[drawbacks]: #drawbacks

- **Performance.** Sandboxing the evaluator adds overhead for sandbox creation and teardown. In single-user mode, where the evaluator currently accesses the store directly (bypassing the daemon), switching to daemon-mediated access would add per-call latency. In multi-user mode the daemon path is already used, so the additional cost is only the sandbox itself.
- **Bootstrapping.** The evaluator binary may reside in the store. The daemon must make it available inside the sandbox before evaluation starts, similar to how it provisions builders.
- **Protocol commitment.** A stable daemon protocol is a long-term maintenance burden.
- **Community.** This deliberately levels the Nix language's special status, which may face resistance.

# Alternatives
[alternatives]: #alternatives

- **Do nothing.** The Nix language retains its privileged position. Alternative frontends remain second-class.
- **Stable derivation API without sandboxing.** Expose a JSON-based derivation submission endpoint but don't sandbox frontends. This enables alternative languages but doesn't simplify the trust model — each frontend must provide its own purity guarantees.
- **Guix approach.** Build a parallel ecosystem with a different frontend language. This has been done; it works but duplicates enormous effort and fragments the package base.

# Prior art
[prior-art]: #prior-art

- [**RFC #68 — Minimal Daemon**](https://github.com/NixOS/rfcs/pull/68): Proposed modularizing the daemon for better separation. The author mentioned sharing libnixstore with Guix. Closed for lack of interest, but the motivation overlaps with this RFC.
- [**RFC #8 — Readonly Recursive Nix**](https://github.com/NixOS/rfcs/pull/8): Proposed mounting a daemon socket inside build sandboxes — the exact mechanism this RFC generalizes to evaluation. Scoped to builds only.
- [**RFC #17 — Intensional Store**](https://github.com/NixOS/rfcs/pull/17): Proposed restructuring the store itself. Orthogonal but compatible with this proposal.
- [**NixOS/nix#12607**](https://github.com/NixOS/nix/issues/12607): Proposes decoupling the evaluator from libstore, separating the "language proper" from store-dependent primops. A complementary effort that would make sandboxed evaluation easier to implement.
- **Nix 2.32** (October 2025): Began stabilizing the derivation JSON format, removing store directory dependencies from serialized paths. A prerequisite step toward language-agnostic derivation handling.
- **GNU Guix**: Demonstrated that the store concept is language-portable but the ecosystem is not. Had to rebuild its entire package set because there was no language-agnostic store interface to reuse.

# Unresolved questions
[unresolved]: #unresolved-questions

- What is the stable wire format for the daemon protocol? The current protocol is under-documented and has no stability guarantees.
- What is the quantitative performance impact of sandboxing the evaluator, particularly on large evaluations like nixpkgs?
- How should the daemon handle fetch operations (URLs, git repos) on behalf of sandboxed frontends?
- How should source inputs (flake sources, local paths) be provisioned inside the evaluation sandbox?

# Future work
[future-work]: #future-work

- Official daemon protocol client libraries in multiple languages.
- A formal, versioned derivation interchange schema (building on Nix 2.32's JSON work).
- Mechanisms for cross-frontend package dependencies (e.g., a Python-defined package depending on a Nix-defined one).
