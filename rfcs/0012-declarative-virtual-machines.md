---
feature: declarative-virtual-machines
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
[issues-with-containers]: #issues-with-containers

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

In addition, containers have seen many high-importance issues and there are ways
to escape them (see CVE-2016-5195 or CVE-2017-6074 for recent ones in the linux
kernel, unfortunately systemd seems not to keep a record of what CVEs were fixed
in their NEWS file). This is normal, as the attack surface of a container is
much larger than the one of an emulator, even when considering virtio drivers.

## Use case

The use case this RFC puts forward is the one of someone for whom security is
more important than speed (pushing for VMs instead of containerization), but who
want the same ease of use as with containers.

## Expected outcome

This RFC describes a prospective NixOS module for running VMs. Thus, the main
design point is that a `vms.` module should be made available to NixOS users.
It should allow to declaratively define virtual machines, including their
configuration.

# Detailed design
[design]: #detailed-design

The VM module is architectured in the following way:
 * The root filesystem is written on a qcow2 image
 * The store is stored on the host, for easy upgrade handling (see [Disk
   management](#disk-management))
 * Each VM is run as a (set of) systemd service, and can be rebooted using
   `systemctl restart vm-${name}.service`
 * `qemu` fetches the kernel and initrd directly from the guests' store
 * Networking is done with all the VMs in a bridge internal to the server (see
   [Networking](#networking))

Details follow.

## Basic configuration

The user should be able to configure various aspects of the VMs running,
especially disk, memory and vcpu usages.

### Proposed option set

The following options are proposed:

```nix
{
  vms = {
    path = "/path/to/dir"; # Path into which to store persistent data (disk
                           # images and per-vm store)
    rpath = "/runtime/dir"; # Path for temporary non-user-facing low-size data,
                            # like IPC sockets

    machines.${name} = {
      diskSize = 10240; # Size (in MiB) of the disk image excluding shared paths
                        # and store
      memorySize = 1024; # Size (in MiB) of the RAM allocated to the VM
      vcpus = 1; # Number of virtual CPUs the VM will see
    };
  };
}
```

## Disk management
[disk-management]: #disk-management

The VM must have its own disk image, yet must also have shared access to folders
on the host, if the configuration dictates it so.

The store is a special case, as it has to be written by the host, in order to
handle both initial VM creation and upgrades, and read by the guest. As a
consequence, the easy way of doing it is to bind it as a virtfs between the host
and the guest. The host writes new packages on it, and the guest is able to
execute them.

The aim is to be able to trigger an update without rebooting the guest, by
having the host write the additional packages to the guest's nix store and call
the `switch-to-configuration` script on the guest in some way. However, this is
not included in the current RFC, for the sake of simplicity: for now, upgrading
is done by pointing qemu at the new configuration (by writing the new systemd
service), and rebooting the VM (by restarting the systemd service).

In order to do this, a possible way to do so is to mount:
 * `/` as a filesystem on a qcow2 image
 * `/nix/store` as a virtfs onto a directory on the host, in order to easily
   handle setup and upgrades from the host
 * Shared folders as virtfs' between the host and the guest

### Proposed option set

The following options are proposed:

```nix
{
  vms.machines.${name}.shared = { "/guest/directory" = "/host/directory"; };
  # Pairs of directories from the host to make available to the guest
}
```

## Networking
[networking]: #networking

The networking system should be as simple to configure as possible, while
staying complete featurewise.

A solution to do so is to put all the guests and the host on the same bridge,
and to enforce IP source addresses using `ebtables`. Then, firewalling can be
done in `INPUT` on each individual VM, and they can both talk to each other (if
the configuration of their firewall allows it) and be isolated if need be.

While not perfect securitywise, it has the advantage of being convenient to use
as well as intuitive, and should be enough even for most paranoid users.

For reproducibility, the IP addresses assigned to each VM should be static. For
convenience, the user should not have to actually configure them by hand, and
have an easy way to access it in nix for eg. other VMs' configuration.

Finally, the user should have a domain name for each VM as well as the host, so
that easy communication can be performed between VMs.

Also, see the [unresolved questions](#unresolved-questions) for additional
potential networking-related configuration, like port or ip forwarding.

### Proposed option set

The following options are proposed:

```nix
{
  vms = {
    bridge = "br-vm"; # Name of the VM bridge
    ip4 = {
      address = "172.16.0.1"; # Start address of the IPv4 subnet in the bridge
      prefixLength = 12; # Prefix length
    };
    ip6 = { /* Same here */ };

    addHostNames = true; # Whether to add the VMs in /etc/hosts of each other,
                         # under the vm-${name}.localhost name and
                         # host.localhost

    machines.${name} = {
      ip4 = "172.16.0.2"; # IPv4 address of the VM, should be auto-filled with
                          # an IP not used anywhere else in the subnet defined
                          # on the host if not set, so that user code can use
                          # vms.machines.${name}.ip4 in the firewall
      ip6 = "..."; # Same here
      mac = "..."; # Should be auto-filled with no collision
    };
  };
}
```

## Security

For security reasons, the qemu daemons should not be run as root. As a
consequence, issues may arise with shared paths that may be owned by root on the
host.

In order to make things work more smoothly, qemu's virtfs should be put in
`proxy` mode, which allows a tiny priviledge broker to run and give access to
the shared directories to the unpriviledged qemu process.

## Nix support
[nix-support]: #nix-support

Nix doesn't have to be supported inside the VMs: the guests' configuration is
managed by the host anyway. As a consequence, nix support would be limited to
handling things like `nix-shell` usage. While (very) useful, this adds
significant complexity in the setup. It is possible to do so, but it requires
quite a number of other automatic things we don't necessarily want (like
`allowInternet`). As a consequence, it is not included in this RFC, and may come
in a later RFC.

# Drawbacks
[drawbacks]: #drawbacks

This adds quite a bit of complexity, even though it is contained inside a single
module. It would also add a few nix functions to nixpkgs' library, as
auto-generation of IPs is something pretty generic and reusable.

This proposal would mostly require being maintained over time, even though
qemu's interface is pretty stable.

# Alternatives
[alternatives]: #alternatives

The only current alternative is to use containers, which are [not a tool for the
same job](#issues-with-containers). The impact for not doing this would be that
VMs cannot be spawned as easily as they could, and people will most likely just
not use VMs, or use the (unfit for this task, as there is the additional
consideration that the host is a NixOS) nixops tool.

# Unresolved questions
[unresolved]: #unresolved-questions

 * Should we add options like `containers`' `forwardPorts`, or `allowInternet`
   (that would do the NATing part, as well as forwarding resolv.conf from host
   to guest)? Or allow to filter internet only to some ports? (eg. a mail vm
   only allowed to open connections to the outside on tcp/25 and the nix cache)
 * If so, should we add a `forwardAddress` to forward a complete IP to a VM?
   Should we handle multiple IPs on the host cleanly?
 * How to handle the case of adding a new VM that takes the IP of a previous
   already-running VM? (VM IP assignment has to be written in nix, as nix code
   like other VMs' firewall has to access it) Using a hash of the VM name to
   define the IP for each VM, so that IPs don't change? (that implies writing
   the hashing function in nix, so...)
 * Should [nix support](#nix-support) be supported and triggered based on a
   per-VM option? If so, should it automatically set up some kind of NATing
   restricted to the nix cache?
 * Should the host be able to set a channel for a VM different from the one it
   is following? If so, should all the packages from the VM be installed based
   on this channel? How to do this, given the configuration is evaluated inside
   the host and not inside the guest?
 * Is VM IP auto-assignment too much for this first RFC, should it be removed?
 * Should we handle VMs having multiple disks attached? If so, with what
   options?
