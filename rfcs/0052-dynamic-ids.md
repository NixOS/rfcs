---
feature: dynamic-ids
start-date: 2019-09-05
author: Silvan Mosberger
co-authors:
shepherd-team: Arian van Putten, asymmetric, Eelco Dolstra, Jörg Thalheim, Ryan Mulligan
shepherd-leader: Ryan Mulligan
related-issues: https://github.com/NixOS/nixpkgs/pull/65698
---

# Summary
[summary]: #summary

A lot of NixOS modules are [assigning static uids/gids](https://github.com/NixOS/nixpkgs/blob/044cc701c23ede96355eb1dc997985b4dfac0372/nixos/modules/misc/ids.nix#L36) to their users. This has resulted in less than 90 static ids left in the reserved range from 0 to 400.

This RFC deprecates the practice of doing that and instead suggests to
- If applicable use systemd's `DynamicUser`
- Otherwise let NixOS assign dynamic persistent ids, which happens automatically when `users.users.<name?>.uid`/`users.groups.<name?>.gid` is not set. For users, `users.users.<name?>.isSystemUser` should be set so that only uids under 1000 are used by NixOS services.

Usage of static ids has to be explicitly justified.

Note that this RFC is only about NixOS services in nixpkgs. It doesn't impose any restriction on the end users setting static ids. However note that without a central static uid mapping conflicts can occur, which will result in an error during the system build.

# Motivation
[motivation]: #motivation

We are running out of static ids in the reserved range from 0 to 400. If services continue to reserve ids for themselves this will run out eventually.

In addition, a central list of ids is annoying to maintain and leads to merge conflicts.

# Detailed design
[design]: #detailed-design

## Documentation updates

New best practices for declaring users are to be documented. This includes sections like the following

### Using `DynamicUser` for declaring users

If the service is fit for `DynamicUser`, this is the preferred solution, as it doesn't require any persistent ids. However this only works well for services whose state is self-contained. As soon as the service's data is needed somewhere else, this approach can fall flat. `DynamicUser` also enables a bunch of options restricting the service (see `man systemd.exec` for details), some of which might need to be disabled in order for it to work. Note that `DynamicUser` works even with large amounts of files, since it almost never has to change the underlying uid which would require a `chown` of all files.

An example:

```nix
{
  systemd.services.myservice.serviceConfig.DynamicUser = true;
}
```

### Using ids dynamically allocated by NixOS


By not setting `users.users.<name?>.uid`/`users.groups.<name?>.gid`, NixOS will dynamically allocate ids. For users, `users.users.<name?>.isSystemUser = true` should be set as well such that only ids below 1000 are used. These ids are persistent over the lifetime of a NixOS system, even when services are disabled and enabled again. The generated mapping from names to ids is stored in `/var/lib/nixos/uid-map`/`/var/lib/nixos/gid-map`, so if this directory is backed up, the mappings will persist too when restoring.

An example:

```nix
{
  users = {
    users.myservice = {
      description = "My service user";
      group = "myservice";
      isSystemUser = true;
    };
    groups.myservice = {};
  };
}
```

### Ensuring correct directory permissions for services

Services must be able to access their directories.
- The easiest way to achieve this is to use `systemd.services.<name?>.serviceConfig.StateDirectory = "myservice"`, which ensures that `/var/lib/myservice` belongs to the services user. See `man systemd.exec` for info on this and the related directives `CacheDirectory`, `LogsDirectory` and `ConfigurationDirectory`.
- `systemd.tmpfiles.rules = [ "Z '/var/lib/myservice' - myuser mygroup - -" ]` can also be used, with the disadvantage that it will only run at system activation and not when the service starts. It also recursively fixes the permissions every time, meaning it can lead to considerable slowdown with many files.
- An alternative is to assign `serviceConfig.ExecStartPre = "+${pkgs.writeScript "myservice-prestart" "..."}"` with a script to fix the permissions, where the `+` makes the script run with full root permissions as documented in `man systemd.service`.

## Enlarge the reserved range of system users/groups

How uid/gid ranges are decided: If `isSystemUser = false`, dynamic uids are allocated in the range `UID_MIN` to `UID_MAX`, while with `isSystemUser = true`, it's `SYS_UID_MIN` to `SYS_UID_MAX`. In contrast, gids are always allocated in the range `SYS_GID_MIN` to `SYS_GID_MAX`. See [#65698](https://github.com/NixOS/nixpkgs/pull/65698) for implementation details.

Since the new recommendation is to use `isSystemUser` for system users and to not set static ids, the available ids now have the range `SYS_UID_MIN` to `SYS_UID_MAX` and `SYS_GID_MIN` to `SYS_GID_MAX`, defined in [shadow.nix](https://github.com/NixOS/nixpkgs/blob/044cc701c23ede96355eb1dc997985b4dfac0372/nixos/modules/programs/shadow.nix#L13-L21), both of which currently span from 400 to 499. This means a NixOS system could only have 100 different services using dynamically allocated ids over its lifetime. Since this is not very much, this range will be changed to span from 400 to 999, reserving an additional 500 ids for system users/groups. The range from 500 to 999 is currently not reserved for anything.

Therefore the number of different services using dynamic ids that can be enabled on a single NixOS system is 600. In comparison with static ids, the number of *enabled* services on a system grows much more slowly than the number of total *existing* services in NixOS (each of which would need one of the 400 static ids).

The implementation of this is in PR [#65698](https://github.com/NixOS/nixpkgs/pull/65698).

## Changing user declarations

Are there any problems when moving between different user declarations? Note that `StateDirectory` has to be used with `DynamicUser` if state is needed, we'll ignore `ReadWritePaths` because it's inferior.

| From \ To | `DynamicUser` | dynamic NixOS ids | static NixOS ids |
| --- | --- | --- | --- |
| `DynamicUser` | - | unproblematic because `StateDirectory` was used | unproblematic because `StateDirectory` was used |
| dynamic NixOS ids | unproblematic because `StateDirectory` needs to be used | - | needs manual `/var/lib/nixos/{g,u}id-map` change if different id |
| static NixOS ids | unproblematic because `StateDirectory` needs to be used | unproblematic | - |

In addition, a transition from `isSystemUser = false` to `isSystemUser = true` can't be done automatically, the `/var/lib/nixos/uid-map` file needs to be adjusted manually for that. However without doing so, NixOS will happily continue to use the previously assigned uid without problems. This means changing this value is unproblematic.

Note that changing all current NixOS services to use dynamic ids is [future work][future].

# Drawbacks
[drawbacks]: #drawbacks

If data is restored from a backup without restoring `/var/lib/nixos` and the service doesn't [ensure correct directory permissions](#ensuring-correct-directory-permissions-for-services), then the service can fail to start. This can happen When copying data from a different machine. This is fixable by either manually changing `/var/lib/nixos/{u,g}id-map` to map the name to the old id, by recursively `chown`ing the restored data to the new id, or by making the NixOS service fix permissions itself.

# Alternatives
[alternatives]: #alternatives

- Increase the range of static ids up to 999, adding another 600 static ids. While this would solve the problem of running out of static ids temporarily, over time this range will fill up again, at which point this alternative can't be used again.
- Use a big range above `UID_MAX`/`GID_MAX`=29999, perhaps from 30000 to 40000. This would be enough static ids for a long time, but having to maintain a static mapping in nixpkgs will still be annoying. Also this violates the convention of system users being below 1000.

Not doing anything is not an option as the currently used range is finite.

# Unresolved questions
[unresolved]: #unresolved-questions

# Future work
[future]: #future-work

- All unnecessary static ids can over time be removed from the [central listing](https://github.com/NixOS/nixpkgs/blob/044cc701c23ede96355eb1dc997985b4dfac0372/nixos/modules/misc/ids.nix#L36), replacing them with `DynamicUser` where applicable and/or dynamic ids allocated by NixOS.
- `SYS_UID_MIN` could be lowered to 6 as per [this](https://github.com/systemd/systemd/blob/f4ea7552c109942b49cc1a3c37e959716fb8c453/doc/UIDS-GIDS.md#summary)
