---
feature: redistribute-redistributable
start-date: 2024-12-15
author: Ekleog
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: https://github.com/NixOS/nixpkgs/issues/83884
---

# Summary
[summary]: #summary

Make Hydra build and provide all redistributable software.

# Motivation
[motivation]: #motivation

Currently, Hydra builds only free software and unfree redistributable firmware.
This means that unfree redistributable software needs to be rebuilt by all the users.
For example, using MongoDB on a Raspberry Pi 4 (aarch64, which otherwise has access to hydra's cache) takes literally days and huge amounts of swap.

Hydra could provide builds for unfree redistributable firmware, at minimal added costs.
This would make life much better for users of such software.
Especially when the software is still source-available even without being free software, like MongoDB.

# Detailed design
[design]: #detailed-design

Hydra will build all packages with licenses for which `redistributable = true`.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

With this change, Hydra will start building, among others:
- CUDA
- DragonflyDB
- MongoDB
- Nomad
- NVIDIA drivers
- Outline
- SurrealDB
- TeamSpeak
- Terraform
- Unrar
- Vagrant

Hydra will keep not building, among others:
- CompCert
- DataBricks
- Elasticsearch
- GeoGebra
- Widevine CDM

# Drawbacks
[drawbacks]: #drawbacks

The only previously listed drawback is that NixOS could end up including unfree software in the ISO image without noticing.
However, as there is already unfree firmware, this fight is already half-lost.

Also, adding unfree software to the ISO image would still require a NixOS maintainer to actually add it there.
The only benefit we currently get out of not building unfree redistributable software, is that the hydra builds for the ISO would fail if someone were to make a mistake.

# Alternatives
[alternatives]: #alternatives

### Having Hydra actually only build FOSS derivations, not even unfree redistributable firmware

This would likely break many installation scenarios, but would bring us to a consistent ethical standpoint, though it's not mine.

### Keeping the statu quo

This results in very long builds for lots of software, as exhibited by the number of years people have been complaining about it.

### Implementing this RFC

See above for the details

### Implementing this RFC, plus adding a check on Hydra to validate no unfree software enters the ISO image

This would likely be harder to implement.
It could be a job override, that would make hydra allow unfree redistributable software for all jobs except for the ISO image, which would only allow unfree redistributable firmware.

The drawback of this alternative is that it would be more effort to implement, especially as manpower around Hydra is very scarce and limited.
However, it would solve the only previously listed drawback.

### Building all software, including unfree non-redistributable software

This is quite obviously illegal, and thus not an option.

# Prior art
[prior-art]: #prior-art

According to [this discussion](https://github.com/NixOS/nixpkgs/issues/83433), the current statu quo dates back to the 20.03 release meeting.
More than four years have passed, and it is likely worth rekindling this discussion, especially now that we actually have a Steering Committee.

Recent exchanges have been happening in [this issue](https://github.com/NixOS/nixpkgs/issues/83884).

# Unresolved questions
[unresolved]: #unresolved-questions

None.

# Future work
[future]: #future-work

If this RFC lands as-is, future work could be around adding the check on hydra listed in the alternatives section.
This would validate that no unfree redistributable software enters the ISO image.
