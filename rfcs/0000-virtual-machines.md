---
feature: virtual-machines
start-date: 2017-04-02
author: Ekleog
co-authors: Nadrieril
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

This RFC describes a way to declaratively add virtual machines to NixOS
machines, in a way similar to the current `containers` module.

# Motivation
[motivation]: #motivation

## Issues with containers

The `containers` module is useful, but is only namespace-level virtualisation.
As a natural consequence, it blocks kernel-level virtualisation, thus limiting
the security benefits.

Moreover, the nix store is shared with the host, which means secrets potentially
put there by the host (and with [issue 8](https://github.com/NixOS/nix/issues/8)
these can easily come unannounced) are readable from the guest.

Worse, even assuming [issue 8](https://github.com/NixOS/nix/issues/8) is solved,
the guest is still able to get the host's configuration by reading it from the
store. This information leak is precious to an attacker trying to attack the
host system.

## Use case

The use case this RFC puts forward is the one of someone for whom security is
more important than speed (pushing for VMs instead of containerization), but who
want the same ease of use as with containers.

## Expected outcome

TODO: What does this exactly encompass? How to make this not overlap with
[detailed design](#detailed-design)?

# Detailed design
[design]: #detailed-design

This is the bulk of the RFC. Explain the design in enough detail for somebody
familiar with the ecosystem to understand, and implement.  This should get
into specifics and corner-cases, and include examples of how the feature is
used.

# Drawbacks
[drawbacks]: #drawbacks

Why should we *not* do this?

# Alternatives
[alternatives]: #alternatives

What other designs have been considered? What is the impact of not doing this?

# Unresolved questions
[unresolved]: #unresolved-questions

What parts of the design are still TBD or unknowns?
