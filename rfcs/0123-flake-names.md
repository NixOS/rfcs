---
feature: flake-names
start-date: 2022-03-12
author: Anselm Schüler
co-authors: None
shepherd-team: None
shepherd-leader: None
related-issues: None
---

# Summary
[summary]: #summary

Flakes can declare the field `name`.  
It represents the name of the flake.  
The derivations for a flake are no longer called `source`, but use the flake name.

# Motivation
[motivation]: #motivation

Flake-centric workflows often end up with a lot of derivations named “source”, and it’s difficult to navigate this.
Also, the discoverability and usability of flakes needs to be improved. Current commands mostly show technical information. This would be a step in the right direction.

# Detailed design
[design]: #detailed-design

A new supported property for flakes is introduced, `name`.  
Running `nix flake metadata` on a flake that declares this field displays it at the top.  
The derivation that contains the flake’s content is called `flake-source-${name}` or, if a short revision identifier is available, `flake-source-${name}-${shortRev}`.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

None

# Drawbacks
[drawbacks]: #drawbacks

This may cause clutter and additional maintenance.

# Alternatives
[alternatives]: #alternatives

Flake names could be handled entirely through outside means, with things like the global registry merely pointing to flakes under names.

# Unresolved questions
[unresolved]: #unresolved-questions

The name scheme could be changed. `flake-source-${name}-${shortRev}` could be too long.

# Future work
[future]: #future-work

Flake discoverability and usability needs to be improved.
