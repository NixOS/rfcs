---
feature: use-matrix-for-official-chat
start-date: 2020-05-19
author: @ryantm and others
shepherd-team: @grahamc, @joepie91, @andir, @mweinelt
shepherd-leader: @grahamc
---

# Summary
[summary]: #summary

Switch from IRC ([Freenode](https://freenode.net/)) to [Matrix](https://matrix.org/) ([#community:nixos.org][1]) as our official community chat.

# Motivation
[motivation]: #motivation

The former official community chat host, Freenode, has collapsed. Many Free Software communities have abandoned it, so its network effects have become negative instead of positive.

There have also been long-running usability and accessibility issues with IRC as a platform, for the general public. This is further supported by the existence of a large (1000+ users) unofficial NixOS community on Discord. The NixOS community as a whole would benefit from moving to a more broadly accessible platform with modern features.

While there are quite a few options in this area (for example Discord and Slack), using an open platform is quite important for a FOSS project like NixOS, and Matrix stands out here&mdash;it is federated, has a very active community and development process, *and* also provides modern features and polished clients.

While the move to Matrix has de facto already taken place, as a necessary response to the imminent collapse of Freenode, this RFC is intended to evaluate and formalize the decision, and ensure that community concerns around the move are addressed.

# Implementation
[implementation]: #implementation

We will use [Matrix](https://matrix.org) as our official and primary chat platform.

The NixOS Foundation will operate a Matrix homeserver on the `nixos.org` namespace.

A collection of rooms will be listed under the [#community:nixos.org][1] Space.

Any other places that point to IRC will be updated to point to Matrix instead.

Any convenience features such as bots and monitoring will be ported to Matrix as needed.

The official Matrix rooms will be configured such that their history is publicly visible, unless there are strong reasons not to do so. Additionally, Matrix allows for third parties to set up a search-engine-indexable public log viewer.

## Bridging Matrix and IRC

Repeated interest was expressed in a bridge between Matrix and IRC. This RFC does not address the implementation details of bridging, but considers bridging to be a near-future goal, and proposes that a new RFC be drafted to work out the details.

In any case, to avoid a mismatch in cultural norms stemming from having two connected platforms, the Matrix side would be the 'primary side' of the bridge, with the IRC side serving as an access mechanism for those unwilling or unable to use a Matrix client. This means that, for example, Matrix-specific features may be used in the NixOS community even if those bridge awkwardly to IRC, and that all community moderators should be on the Matrix side.

# Drawbacks
[drawbacks]: #drawbacks

* Long-term IRC users might find it difficult to get used to a different chat platform and client. However, we consider the aforementioned benefits to outweigh this drawback.
* Participating in the conversations requires an account on a homeserver.

# Alternatives
[alternatives]: #alternatives

1. Switch to another IRC network like [Libera Chat][2]
    - This would not address the aforementioned usability and accessibility concerns.
2. Switch to a proprietary chat system like Discord or Slack
    - Being proprietary, this would fit NixOS poorly as a FOSS project, provide very little control over the community space, and pose accessibility issues.
3. Switch to an open-core or open-source system like Zulip, Rocketchat, or Mattermost
    - This would require people to create a dedicated account for NixOS, as they are more-or-less isolated systems; whereas many community members are already using Matrix, and can use their existing (federated) account.

[1]: https://matrix.to/#/#community:nixos.org
[2]: https://libera.chat/
