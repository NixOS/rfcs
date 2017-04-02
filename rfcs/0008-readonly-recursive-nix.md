---
feature: readonly-recursive-nix
start-date: 2017-04-02
author: Shea Levy
co-authors: (find a buddy later to help our with the RFC)
related-issues: https://github.com/NixOS/nix/issues/13
---

# Summary
[summary]: #summary

Allow nix builds to perform readonly operations on the subset of the
nix store exposed to them.

# Motivation
[motivation]: #motivation

The primary motivation for this feature is as an incremental step
toward full recursive nix, described in [NixOS/nix#13][nix-issue-13]
and to be fleshed out in its own RFC. However, even without the full
solution this feature would replace the `exportReferencesGraph` nix
feature and make it more general.

# Detailed design
[design]: #detailed-design

There are a number of components to this work:

## StoreViewStore
[store-view-store]: #StoreViewStore

A `nix::Store` implementation that forwards readonly requests to an
underlying `Store` implementation, filtering both requests and
responses to ensure that only paths that should be accessible to the
build are returned (so e.g. `queryAllValidPaths` will only return the
build time requisites of the build, not the full host store).

Alternatively, this can just be a special mode of the nix daemon
rather than a proper store api implementation.

## FdDaemonStore
[fd-daemon-store]: #FdDaemonStore

A `nix::RemoteStore` implementation that opens new connections by
making a request to a datagram-oriented unix domain socket passed into
it as a parameter.

## Build setup
[build-setup]: #build-setup

### Daemon availability

The nix build code must ensure there is some daemon running. If the
current build is a child of a nix-daemon process, it can just reuse
the parent, otherwise it must spawn its own private nix-daemon process.
This can be shared by all builds.

### Connection setup

For each build, the build code should create a socketpair, passing one
socket to the build via `NIX_REMOTE` as appropriate for the
[FdDaemonStore][fd-daemon-store], and reading packets from the other.
When connection requests are received, the build loop should create a
new connection with the daemon, tell the daemon what it needs to know
to set up a [StoreViewStore][store-view-store], and then pass the
client socket through to the build.

Multiple processes in the build may be trying to open connections in
parallel, but as long as each only consumes one response it doesn't
matter if the response is the exact one corresponding to the specific
request made.

# Drawbacks
[drawbacks]: #drawbacks

Increased complexity.

# Alternatives
[alternatives]: #alternatives

The main alternative to full recursive nix is import from derivation,
which currently works but has some significant issues. It is also less
expressive than full recursive nix.

The alternative to readonly recursive nix is just to continue to used
the existing `exportReferencesGraph` mechanism. But not doing this
work means not doing full recursive nix, which blocks quite a number
of valuable use cases, including using nix as a make replacement.

# Unresolved questions
[unresolved]: #unresolved-questions

Whether the [StoreViewStore][store-view-store] should be a proper
store API implementation or just a mode for the nix daemon.

[nix-issue-13]: https://github.com/NixOS/nix/issues/13
