---
feature: declarative-filesystem-layouts
start-date: 2023-01-11
author: l0b0
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: https://github.com/NixOS/nixpkgs/issues/209988 (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

One of the hardest parts of setting up a NixOS (or any Linux) system from scratch is setting up the filesystems. Deciding how big each partition needs to be, making sure it's UEFI compliant, whether to use LUKS inside LVM or LVM inside LUKS, remembering to set a partition bootable, etc. It would be fantastic to have a declarative way to deal with this. Features which come to mind include:

- Integrates with the GUI installer. Point the installer to a `configuration.nix` with a disk layout somewhere, and it does all the necessary setup, asking for things like passphrases where necessary.
- A tool to extract the Nix configuration from currently mounted file systems, expanding on what `nixos-generate-config` already does.
- Optionally some way to apply the relevant part of a `configuration.nix` file to a system manually, like [disko](https://github.com/nix-community/disko).

# Motivation
[motivation]: #motivation

Why are we doing this? What use cases does it support? What is the expected
outcome?

# Detailed design
[design]: #detailed-design

This is the core, normative part of the RFC. Explain the design in enough
detail for somebody familiar with the ecosystem to understand, and implement.
This should get into specifics and corner-cases. Yet, this section should also
be terse, avoiding redundancy even at the cost of clarity.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

This section illustrates the detailed design. This section should clarify all
confusion the reader has from the previous sections. It is especially important
to counterbalance the desired terseness of the detailed design; if you feel
your detailed design is rudely short, consider making this section longer
instead.

# Drawbacks
[drawbacks]: #drawbacks

Why should we *not* do this?

# Alternatives
[alternatives]: #alternatives

What other designs have been considered? What is the impact of not doing this?

# Unresolved questions
[unresolved]: #unresolved-questions

What parts of the design are still TBD or unknowns?

# Future work
[future]: #future-work

What future work, if any, would be implied or impacted by this feature
without being directly part of the work?


# Summary
[summary]: #summary
