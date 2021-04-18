---
feature: NixOS Container rewrite
start-date: 2021-02-14
author: Maximilian Bosch <maximilian@mbosch.me>
co-authors: n/a
shepherd-team: n/a
shepherd-leader: n/a
related-issues: #69414, #67265
---

# Summary
[summary]: #summary

This document suggests a full replacement of the
[`nixos-container`](https://nixos.org/manual/nixos/stable/#ch-containers) subsystem of NixOS with
a new implementation which remains to be based on
[`systemd-nspawn(5)`](https://man7.org/linux/man-pages/man5/systemd.nspawn.5.html) and incorporates
[`systemd-networkd(8)`](https://man7.org/linux/man-pages/man8/systemd-networkd.service.8.html) for
the networking stack rather than imperative networking while providing a reasonable upgrade-path
for existing installations.

# Motivation
[motivation]: #motivation

The `nixos-container` feature originally appeared in `nixpkgs` in
[2013](https://github.com/nixos/nixpkgs/commit/9ee30cd9b51c46cea7193993d006bb4301588001)
which happened at a time where `systemd` support was relatively new to NixOS.

Back then, `systemd-nspawn` was
[only designed as a development tool for systemd developers](https://lwn.net/Articles/572957/) and NixOS
didn't [support networkd](https://github.com/NixOS/nixpkgs/commit/59f512ef7d2137586330f2cabffc41a70f4f0346).
Due to those circumstances the entire feature was implemented
in a fairly ad-hoc way. One of the most notable issues is the broken uplink during boot
of a container:

* Containers will be started in a so-called template unit named [`container@.service`](https://www.freedesktop.org/software/systemd/man/systemd.unit.html#Description). This
  service [configures the network interfaces after the container has started](https://github.com/NixOS/nixpkgs/blob/2f96b9a7b4c083edf79374ceb9d61b5816648276/nixos/modules/virtualisation/nixos-containers.nix#L178-L229).

* This means that even though the `network-online.target` is reached, no uplink is available
  until the machine is fully booted.

  The implication is that a lot of services won't work as-is when installed into a container.
  For instance, [oneshot](https://www.freedesktop.org/software/systemd/man/systemd.service.html#Type=)-units
  such as `nextcloud-setup.service` will hang if a database in e.g. a local network is used. Other
  examples are `rspamd` or `clamav`.

Additionally, we currently have to maintain a Perl script called `nixos-container.pl` which serves
as CLI frontend for the feature. This isn't just an additional maintenance burden for us, but largely duplicates functionality already provided by [`machinectl(1)`](https://www.freedesktop.org/software/systemd/man/machinectl.html).

The main reason why `machinectl` cannot be used as replacement are
[imperative containers](https://nixos.org/manual/nixos/stable/index.html#sec-imperative-containers)
and state getting lost after the `container@<container-name>.service` unit
has stopped since `.nspawn` units aren't used.

In the following section the design of a replacement is proposed with these goals:

* Use [`networkd`](https://www.freedesktop.org/software/systemd/man/systemd.network.html) as networking stack since `systemd-nspawn` is part of the same project and
  thus both components are designed to work together.

* Provide a useful base to easily use `systemd-nspawn` features:
  * When using actual `.nspawn` units defined with Nix expressions, it will be trivial
    to define and override configuration per-container (in contrast to listing flags
    passed to the CLI interface as it's the case in the old module).
  * With this design, it won't be necessary to implement adjustments for advanced features
    such as [MACVLAN interfaces](https://backreference.org/2014/03/20/some-notes-on-macvlanmacvtap/)
    since administrators can directly use the upstream configuration format. The current module
    only supports `MACVLAN` interfaces for instance, but e.g. no `IPVLAN`.
  * Another side effect is that existing knowledge about this configuration can be re-used.

* Provide a reasonable upgrade-path for existing installations. Even though this RFC suggests
  deprecating the existing `nixos-container` subsystem, this measure is purely optional. However,
  for this to happen, a smooth migration path must be provided.

# Detailed design
[design]: #detailed-design

## Bootstrapping

### NixOS container from scratch

<!-- erste Stichpunkte können raus, da nicht relevant -->

To start a `systemd-nspawn` machine, a so-called image is required which is located at
its state directory, `/var/lib/machines`. Theoretically it's possible to use e.g. tarballs
of a `rootfs` or any kind of Linux distribution. For instance, an environment of another
`nspawn`-container exported with `machinectl export-tar`.

However, it is also possible to create an image "from scratch" which is for now the only supported
mode - just like it's the case in the current implementation. Basically the following
things need to happen:

* Create an empty directory in `/var/lib/machines` named like the container-name.
* `systemd-nspawn` only expects `/etc/os-release`, `/etc/machine-id` and `/var` to exist
  inside, however with no content.
* To get a running NixOS inside, `/nix/store` and its state (`/nix/var/nix/db`,
  `/nix/var/nix/daemon-socket`) must be bind-mounted into it. As `init`-process
  the [stage-2 script](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/system/boot/stage-2-init.sh)
  must be started which eventually `exec(2)`s into `systemd` and ensures that everything
  is correctly set up.

This init-script can be built by evaluating a NixOS config against `<nixpkgs/nixos/lib/eval-config.nix>`.

<!--
unnötig

### Isolated installation

One of the reasons why NixOS containers are currently missing isolation is that the full host-setup
of Nix (i.e. store and daemon) need to be mounted into the container. An experimental and alternative
approach is to only mount store-paths that are actually needed into the container.

This is feature is opt-in and implemented by analyzing which store paths are needed inside
the container using [`pkgs.closureInfo`](https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/closure-info.nix).

For each store-path a `BindReadOnly=`-entry will be added to the `.nspawn`-unit. (NOTE: this
is experimental and actual performance implications aren't tested yet).-->

## Network

The following section provides an overview of how to configure networking for containers and
how this will be implemented. A proposal how the API of the NixOS module could look like will
be demonstrated in the [next chapter](#examples-and-interactions).

### "public" networking

This is the most trivial networking mode. It is taken if the `PrivateNetwork`-option of the
`.nspawn`-unit is set to `no`. In this case, the container has full access to the host's network,
otherwise the container will run in its own namespace.

### Default Mode

By default, `nspawn` containers have their own private network. This is implemented with either
a [`veth`](https://man7.org/linux/man-pages/man4/veth.4.html) pair or virtual zones.
Both provide a virtual link between the host's and the container's network
namespace. The only difference is that a virtual zone can be used to manage multiple containers
in a single virtual ethernet on the host.

<!-- details, das meiste ist eher systemd doku und kann raus :) -->
[By default](https://github.com/systemd/systemd/blob/main/network/80-container-ve.network), both
assign `0.0.0.0/2{4,8}` to the interface. This is a way to tell `networkd` to assign
a private subnet (by default something from `192.168.0.0/16` or another free slot from e.g.
`10.0.0.0/8`). Via its own DHCP server, addresses can be assigned to containers dynamically.
On the container-side the `host0` interface will be used to communicate with the host.

Unfortunately this approach lacks IPv6 support. For that, our implementation should also
provide [RFC4862 SLAAC](https://tools.ietf.org/html/rfc4862) via [radvd](https://github.com/radvd-project/radvd), a simple implementation of that.

Each virtual ethernet interface on the host-side will have `::/64` as additional address. `networkd`
will automatically assign a free [RFC4193 ULA prefix](https://tools.ietf.org/html/rfc4193) to
the interface and `radvd` will inform the containers of this prefix so they can assign themselves addresses within it.

Hosts will be available on the current system via the
[`mymachines`-feature of `nss`](https://www.freedesktop.org/software/systemd/man/nss-myhostname.html)
which is already taken care of by `systemd-networkd`.

### Static networking

### DNS

## Migration plan

## Advanced Features

## Imperative management

* Netzwerk
* Migration
* Imperative Container
* Ephemeral, unprivileged
* ve-, vz-, MACVLAN
* radvd gegen fehlendes IPv6/Minimalsetup

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

* Explicit dependency on `networkd` (`networking.useNetworkd = true;`) on both the
  host-side and container-side.

* Need to migrate from existing containers at the moment.

# Alternatives
[alternatives]: #alternatives


* Implement this feature in e.g. its own (optionally community-maintained) [flake](https://www.tweag.io/blog/2020-05-25-flakes/):
* Keep both the proposed feature and the existing `nixos-container` subsystem in NixOS. In contrast
  to `systemd-nspawn@`, the current container subsystem uses `/var/lib/containers` as state-directory,
  so clashes shouldn't happen.
* Do nothing.

# Unresolved questions
[unresolved]: #unresolved-questions

* None that I'm aware of.

# Future work
[future]: #future-work

* Write documentation for the new module.
* Get the PR into a mergeable state.

