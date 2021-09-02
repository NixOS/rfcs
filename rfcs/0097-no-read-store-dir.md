---
feature: no-read-store-dir
start-date: 2021-07-04
author: Las Safin
co-authors:
shepherd-team: @kevincox @7c6f434c @edolstra
shepherd-leader: @kevincox
related-issues:
---

# Summary
[summary]: #summary

Set the permissions for `/nix/store`, `/nix/store/.links` and `/nix/store/trash` to 1771 instead of 1775, disabling reading the directory for other users.

# Motivation
[motivation]: #motivation

This is a simple change that acts as an extra layer of security by making
it harder to access store paths that programs don't need to access.

For a directory, being able to execute without being able to read it means
that you can access paths inside the directory, if and only if you know the path beforehand,
since you can not list the directory entries.

In our case, with this change, all users that are not root and are not part of nixbld,
will only be able to directly access paths inside `/nix/store` which they already know,
i.e. the hash and the name.
If you run some program that does not have access to the nix daemon under such
a user, it will not be able to search the store for built system configurations,
but will instead have to find the path to one through e.g. `/nix/var/nix/profiles/system` (if accessible).

For tight sandboxes under NixOS, where only the store paths needed are mounted,
this is not very important, since they can already only access the ones they need,
however, this feature is useful for making sandboxes that have access to the entirety
of `/nix/store`, where you want to be sure that any store path encountered inside the sandbox
can be accessed. This will often happen when you want a quick sandbox with bubblewrap where
it's too much of a pain to manually find all store paths you need.
This type of sandbox can still be secure, granted that you are careful not to "leak" store paths
into the sandbox, which is not trivial but not impossible either. Specifics are discussed in [Drawbacks](#drawbacks).

NB: While this change is simple, it is not possible for end-users to do without changing Nix, since at the moment any
`nix` command will reset the permissions back to 1775.

# Detailed design
[design]: #detailed-design

Set the 1775
in [nixpkgs/nixos/modules/system/boot/stage-2-init.sh](https://github.com/NixOS/nixpkgs/blob/8284fc30c84ea47e63209d1a892aca1dfcd6bdf3/nixos/modules/system/boot/stage-2-init.sh#L62),
in [nix/scripts/install-multi-user.sh](https://github.com/NixOS/nix/blob/cf1d4299a8fa8906f62271dcd878018cef84cc30/scripts/install-multi-user.sh#L577),
in [nix/src/libstore/globals.hh](https://github.com/NixOS/nix/blob/ba8b39c13003c8ddafb6bec308997e09b9851c46/src/libstore/globals.hh#L278),
in [nix/src/libstore/build/local-derivation-goal.cc](https://github.com/NixOS/nix/blob/6182ae689826554d915b4ed72e07f7978dc1d13c/src/libstore/build/local-derivation-goal.cc#L641), and
in [nix/src/libstore/local-store.cc](https://github.com/NixOS/nix/blob/0a535dd5ac93576f7152d786464e330ae3d46b50/src/libstore/local-store.cc#L181)
to 1771.

`/nix/store/trash` and `/nix/store/.links` will also have to have their read bit removed, resulting in 0751.

Various parts of NixOS also ought have their permissions fixed, which is beneficial with and without this change.
Specifically, the permissions for these things ought to be looked at again:
- `/proc/cmdline`
- `/proc/sys`
- `/proc/config.gz`
- The other `/proc/*` stuff
- `dmesg`
- The nix daemon

Sandboxes should preferably not have access to the above in any case.

Nothing else has to be done likely, since setting the store permissions to `1771` manually doesn't break
anything other than what is mentioned in this document (though it is undone if you run a `nix` command).

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

Losing the read (r) bit means that you can't list the files inside the store.
The execute (x) bit allows us to `cd` to it and also access paths inside the store.

E.g. `ls "$(readlink /nix/var/nix/profiles/system)"` will still work, since this is a directory
inside the store, and not the store itself, but an unprivileged user can't `ls /nix/store` to find the system configuration.

# Drawbacks
[drawbacks]: #drawbacks

It might be a slight annoyance since shell completion won't work in the `/nix/store` anymore, e.g.
if you have some hash 48914, you wouldn't be able to type `/nix/store/48914<tab>` to get the full path anymore.
This is likely the biggest drawback.

External tooling that does a traversal of the nix store (`find`, `du -s`, `ncdu`) would need `sudo` or explicitly given permissions.

A sandboxed program could still have some idea of how the host machine is used by checking each store path that Hydra has ever built,
then it could estimate whether the host machine has e.g. Tor on it.

Attempting to have security comparable to bind-mounting each necessary store path inside a sandbox is not easy,
since you need to be careful not to leak paths to the sandbox through global state, for example `/proc/cmdline`.
There is no easy way to know whether some path is readable from inside the sandbox, since the problem is
essentially proving that the sandbox doesn't have access to some secret that in this case is the store path itself.
Since Unix software has not traditionally treated paths as secrets, this is a bit problematic if you're
trying to make sure your sandbox can't access some path. We also can not know how future kernel interfaces and such
will be, and they will likely not have the same considerations for "paths as secrets" as us.
Essentially, you have to consider the store paths as encodings of their contents wrt. sandboxes.

The above points about sandboxed programs are not negative effects of changing the permissions of /nix/store and such,
but rather considerations for making use of this change in the context of sandboxes.

# Alternatives
[alternatives]: #alternatives

If Nix was made to not reset the permissions of /nix/store back to 1775, users who want this change could
do it themselves by simply putting this into their configuration.nix:
```nix
{
  system.activationScripts.chmod-store.text = ''
    ${pkgs.util-linux}/bin/unshare -m ${pkgs.bash}/bin/sh -c '${pkgs.util-linux}/bin/mount -o remount,rw /nix/store ; ${pkgs.coreutils}/bin/chmod 1771 /nix/store ; ...'
  '';
}
```

Traditional sandboxing could be seen as an alternative to this, however, they are not mutually exclusive,
since this change is fundamentally just changing some permissions.
Improving the permissions for /nix/store will not decrease security for traditional sandboxes.

# Unresolved questions
[unresolved]: #unresolved-questions

There doesn't seem to be any.

# Future work
[future]: #future-work

Future work includes fixing the permissions of global state in NixOS, notably access to the nix daemon, much of the kernel API, such as `/proc`.
