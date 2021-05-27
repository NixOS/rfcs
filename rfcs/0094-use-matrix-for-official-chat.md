---
feature: use-matrix-for-official-chat
start-date: 2020-05-19
author: Ryan Mulligan
shepherd-team: @grahamc, @joepie91, @andir, @mweinelt
shepherd-leader: @grahamc
---

# Summary
[summary]: #summary

Switch from IRC ([Freenode](https://freenode.net/)) to
[Matrix](https://matrix.org/)
([#community:nixos.org][1]) as
our official community chat.

# Motivation
[motivation]: #motivation

The current official community chat host, Freenode, has lost its
leadership and its future is uncertain. Many Free Software communities
are abandoning it, so its network effects may be negative instead of
positive.

There are currently 1796 members of the Unofficial NixOS Discord
channel (244 weekly visitors, 95 weekly communicators). Some of them
might be convinced by the more modern features available on Matrix to
move their conversations there.

# Detailed design
[design]: #detailed-design

Update the [NixOS.org community
page](https://nixos.org/community/index.html) to point to our Matrix
Space ([#community:nixos.org][1]) that has already been created which you
can join by visting the [invite
link][1].

Update any other places that point to Freenode to point to Matrix
instead.

Port any bots that might be necessary such as:

* nix-channel-monitor
* github PR events
* karma bot
* eval bot
* factoids bot

# Drawbacks
[drawbacks]: #drawbacks

People are used to Freenode and it might be harder for people to use
Matrix, which requires more complex clients.

# Alternatives
[alternatives]: #alternatives

1. Do nothing
2. Switch to another IRC network

[1]: https://matrix.to/#/#community:nixos.org
