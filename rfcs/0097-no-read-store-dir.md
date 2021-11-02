---
feature: nix-store-perms
start-date: 2021-07-04
author: Las Safin
co-authors:
shepherd-team: @kevincox @7c6f434c @edolstra
shepherd-leader: @edolstra
related-issues:
---

# Summary
[summary]: #summary

- NixOS should have a module for configuring the permissions set for `/nix/store` on boot.
- Nix should not enforce the permissions used for `/nix/store`.
- The default permissions if the store doesn't exist should be 1735 when the store is made by Nix or the NixOS installer.
  This means that the nixbld group can't `ls` the directory.

# Motivation
[motivation]: #motivation

Right now you can't set the permissions for `/nix/store`, since they'll be overwritten
by Nix anytime you use `nix`.

We want to `chmod g-r /nix/store`, because the `nixbld` group doesn't actually
need to read the directory. It only needs to be able to write and "execute" it.
This, however, should be optional, since the user should be able to do what they want.

Some users might also want to do things like `chmod o-r /nix/store`, which
gives you the interesting property that you can not access paths you do not
already know of.
Do note that given that all processes can by default read `/proc/cmdline`,
`/run/current-system`, and many other places, they can still read your
system's closure, which makes it an insufficient solution for security in many cases.
This, however, is also entirely optional and is not the default in any way.

# Detailed design
[design]: #detailed-design

Where we previously would enforce the permissions, we now need to
only set them if there is no directory in the first place.
The same applies for `/nix/store/trash` and `/nix/store/.links`.

Specifically, we need to modify the following places (not exhaustive):
- [nixpkgs/nixos/modules/system/boot/stage-2-init.sh](https://github.com/NixOS/nixpkgs/blob/8284fc30c84ea47e63209d1a892aca1dfcd6bdf3/nixos/modules/system/boot/stage-2-init.sh#L62)
- [nix/scripts/install-multi-user.sh](https://github.com/NixOS/nix/blob/cf1d4299a8fa8906f62271dcd878018cef84cc30/scripts/install-multi-user.sh#L577)
- [nix/src/libstore/globals.hh](https://github.com/NixOS/nix/blob/ba8b39c13003c8ddafb6bec308997e09b9851c46/src/libstore/globals.hh#L278)
- [nix/src/libstore/build/local-derivation-goal.cc](https://github.com/NixOS/nix/blob/6182ae689826554d915b4ed72e07f7978dc1d13c/src/libstore/build/local-derivation-goal.cc#L641)
- [nix/src/libstore/local-store.cc](https://github.com/NixOS/nix/blob/0a535dd5ac93576f7152d786464e330ae3d46b50/src/libstore/local-store.cc#L181)

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

You should be able to do something like the following:
```nix
nix.store-perms = "xxxx";
```

# Drawbacks
[drawbacks]: #drawbacks

If a user on a non-NixOS platform mistakenly sets the permissions for `/nix/store` to
something else, it won't be reverted by Nix automatically.

# Alternatives
[alternatives]: #alternatives

You could not do this and keep it as it is.

# Unresolved questions
[unresolved]: #unresolved-questions

There doesn't seem to be any.

# Future work
[future]: #future-work

In the future we likely want to reduce the default permissions for `/nix/store` as much as possible.
