---
feature: no-read-store-dir
start-date: 2021-07-04
author: Las Safin
co-authors:
shepherd-team:
shepherd-leader:
related-issues:
---

# Summary
[summary]: #summary

Set the permissions for /nix/store, /nix/store/.links and /nix/store/trash to 1771 instead of 1775, disabling reading the directory for other users.

# Motivation
[motivation]: #motivation

This means that you can not trivially see all the paths in the nix store, e.g. `ls` won't work
on /nix/store without sudo unless you're in the nixbld group.

Almost everything in NixOS needs access to /nix/store, thus when sandboxing anything under NixOS,
if you want to have a secure sandbox that can't access your NixOS configuration,
initrd secrets (unless your bootloader has support for it), all the programs you've built,
and possibly also your important secrets if you (unfortunately) had to put them in the store,
you will need to restrict what store paths the sandbox can read.

By simply removing the ability to read /nix/store (but not execute), programs will only be able
to access the store paths *which they already know the hash and name of*.
In this case, even if a sandbox has access to the entire store, they will not be able to access any path they do
not already know, and thus not be able to read any content they do not already know the hash of
(for non-content-addressed paths, it would be a function of the derivation however).
Essentially, knowing the hash will mean knowing the data.

For non-sandboxed programs, much will not change if they can still read /run/current-system, /nix/var,
etc., thus this change is only important for sandboxes where you can remove such information leaks.
It isn't a big improvement by itself, but it is a small incremental hardening with few drawbacks that allows for better security in combination with sandboxes.

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

/nix/store/trash and /nix/store/.links will also have to have their read bit removed, resulting in 0751.

Currently, /proc/cmdline provides the path to the current system configuration, which is counter-productive in this case.
This would be fixed by simply setting the permissions to 0440, since the permissions are universal to all pid namespaces.
Fixing the permissions for other files in /proc would likely also be a good idea, regardless of this RFC and regardless
of sandboxing, e.g. it doesn't make sense to expose /proc/config.gz to the entire world even if it doesn't expose any secrets.

Nothing else has to be done likely, since setting the store permissions to `1771` manually doesn't break
anything other than what is mentioned in this document (though it is undone if you run a `nix` command).

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

Losing the read (r) bit means that you can't list the files inside the store.
The execute (x) bit allows us to `cd` to it and also access paths inside the store.

E.g. `ls "$(readlink /nix/var/nix/profiles/system)"` will still work, since this is a directory
inside the store, and not the store itself, but an unprivileged user can't `ls /nix/store` to find the system configuration.

Note: A sandboxed program could still have some idea of how the host machine is used by checking each store path that Hydra has ever built,
then it could estimate whether the host machine has e.g. Tor on it.

# Drawbacks
[drawbacks]: #drawbacks

It might be a slight annoyance since shell completion won't work in the /nix/store anymore, e.g.
if you have some hash 48914, you can't type `/nix/store/48914<tab>` to get the full path anymore.

External tooling that does a traversal of the nix store (`find`, `du -s`, `ncdu`) would need `sudo` or explicitly given permissions.

# Alternatives
[alternatives]: #alternatives

If Nix was made to not reset the permissions of /nix/store back to 1775, users who want this change could
do it themselves by simply putting this into their configuration.nix:
```nix
{
  system.activationScripts.chmod-store.text = ''
    ${pkgs.util-linux}/bin/unshare -m ${pkgs.bash}/bin/sh -c '${pkgs.util-linux}/bin/mount -o remount,rw /nix/store ; ${pkgs.coreutils}/bin/chmod 1771 /nix/store'
  '';
}
```


There is also currently the [systemd-confinement.nix](https://github.com/NixOS/nixpkgs/blob/93c9e5854d87b8e7eeafda2ead4b375d75500c80/nixos/modules/security/systemd-confinement.nix) module in NixOS, which makes use of systemd functionality
that is functionally equivalent to what bubblewrap does, to make sure only the necessary store paths are mounted.

This is obviously limited to systemd services, for non-systemd-services I had [this script](https://github.com/L-as/nix-misc/blob/e844a03ebf4cad4fc8eca0e52306788b70c2a60d/claybox.rb)
that just wraps around bubblewrap, but 1) isn't convenient since you need to provide the derivation outputs you want to include and not the attributes for those derivations,
and 2) it can get [quite slow](https://github.com/containers/bubblewrap/issues/384) once you have sufficiently many store paths you want to include. This could be fixed
by fixing bubblewrap, but it does not seem to be [making progress](https://github.com/containers/bubblewrap/pull/385).

Both of the above alternatives in addition have the problem that they can not be made aware of new store paths.
In the case of the design specified in this document, you could pass a store path to a running sandboxed program and they
would be able to access it normally.
In addition, you would also be able to e.g. execute a setuid program from inside the sandbox that then has access to paths
that the executer didn't, since the executed setuid program could read paths from a file with strict read permissions.

# Unresolved questions
[unresolved]: #unresolved-questions

There doesn't seem to be any.

# Future work
[future]: #future-work

There doesn't seem to be any.
