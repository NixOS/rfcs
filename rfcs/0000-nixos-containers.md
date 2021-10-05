---
feature: NixOS Container rewrite
start-date: 2021-02-14
author: Maximilian Bosch <maximilian@mbosch.me>
co-authors: n/a
shepherd-team: n/a
shepherd-leader: n/a
related-issues: #69414, #67265, #67232, #67336
---

# Summary
[summary]: #summary

This document suggests a full replacement of the
[`nixos-container`](https://nixos.org/manual/nixos/stable/#ch-containers) subsystem of NixOS with
a new implementation on
[`systemd-nspawn(5)`](https://man7.org/linux/man-pages/man5/systemd.nspawn.5.html) and incorporates
[`systemd-networkd(8)`](https://man7.org/linux/man-pages/man8/systemd-networkd.service.8.html) for
the networking stack rather than imperative networking while providing a reasonable upgrade path
for existing installations.

# Motivation
[motivation]: #motivation

The `nixos-container` feature originally appeared in `nixpkgs` in
[2013](https://github.com/nixos/nixpkgs/commit/9ee30cd9b51c46cea7193993d006bb4301588001), at a time where `systemd` support was relatively new to NixOS.

Back then, `systemd-nspawn` was
[only designed as a development tool for systemd developers](https://lwn.net/Articles/572957/) and NixOS
didn't [support networkd](https://github.com/NixOS/nixpkgs/commit/59f512ef7d2137586330f2cabffc41a70f4f0346).
Due to those circumstances the entire feature was implemented
in a fairly ad-hoc way. One of the most notable issues is the broken uplink during boot
of a container:

* Containers will be started in a template unit named [`container@.service`](https://www.freedesktop.org/software/systemd/man/systemd.unit.html#Description). This
  service [configures the network interfaces after the container has started](https://github.com/NixOS/nixpkgs/blob/2f96b9a7b4c083edf79374ceb9d61b5816648276/nixos/modules/virtualisation/nixos-containers.nix#L178-L229).

* This means that even though the `network-online.target` is reached, no uplink is available
  until the container is fully booted.

  The implication is that a lot of services won't work as-is when installed into a container.
  For instance, [oneshot](https://www.freedesktop.org/software/systemd/man/systemd.service.html#Type=) services
  such as `nextcloud-setup.service` will hang if a database in e.g. a local network is used. Other
  examples are `rspamd` or `clamav`.

Additionally, we currently maintain a Perl script called `nixos-container.pl` which serves
as the CLI frontend for the feature. This is not only an additional maintenance burden for us, but largely duplicates functionality already provided by [`machinectl(1)`](https://www.freedesktop.org/software/systemd/man/machinectl.html).

The main reason why `machinectl` cannot be used as a complete replacement are
[imperative containers](https://nixos.org/manual/nixos/stable/index.html#sec-imperative-containers)
and state getting lost after the `container@<container-name>.service` unit
has stopped since `.nspawn` units aren't used.

In the following section the design of a replacement is proposed with these goals:

* Use [`networkd`](https://www.freedesktop.org/software/systemd/man/systemd.network.html) as the networking stack since `systemd-nspawn` is part of the same project and
  thus both components are designed to work together and issues like no uplink until the container is fully booted will be fixed.

* Provide a useful base to easily use `systemd-nspawn` features:
  * When using actual `.nspawn` units defined with Nix expressions, it will be trivial
    to define and override configuration per-container (in contrast to listing flags
    passed to the CLI interface as it's the case in the old module).
  * With this design, it won't be necessary to implement adjustments for advanced features
    such as [MACVLAN interfaces](https://backreference.org/2014/03/20/some-notes-on-macvlanmacvtap/)
    since administrators can directly use the upstream configuration format. The current module
    supports `MACVLAN` interfaces for instance, but not `IPVLAN`.
  * Another side effect is that existing knowledge about this configuration can be re-used.

* Provide a reasonable upgrade path for existing installations. Even though this RFC suggests
  deprecating the existing `nixos-container` subsystem, this measure is purely optional. However,
  for this to happen, a smooth migration path must be provided.

# Detailed design
[design]: #detailed-design

## Bootstrapping

To be fully consistent with upstream `systemd`, the template unit
[`systemd-nspawn@.service`](https://github.com/systemd/systemd/blob/v247/units/systemd-nspawn@.service.in) will be used.

The approach how a container is bootstrapped won't change and will thus consist of the
following steps (executed via a custom `ExecStartPre=`-script):

* Create an empty directory in `/var/lib/machines` named like the container-name.
* `systemd-nspawn` only expects `/etc/os-release`, `/etc/machine-id` and `/var` to exist
  inside, however with no content.
* To get a running NixOS inside, `/nix/store` and its state (`/nix/var/nix/db`,
  `/nix/var/nix/daemon-socket`) are bind-mounted into it. As an `init` process,
  the [stage-2 script](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/system/boot/stage-2-init.sh)
  is started which eventually `exec(2)`s into `systemd` and ensures that everything
  is correctly set up.
* The option `boot.isContainer = true;` will be automatically set for new containers as well.
  This is necessary to
  * avoid bogus `modprobe` calls since `nspawn` doesn't have its own kernel.
  * as option to skip building a `stage-1` boot script when building a NixOS system for
    the container.

This init-script can be built by evaluating a NixOS config against `<nixpkgs/nixos/lib/eval-config.nix>`.

Support for existing tarballs to be imported with `machinectl pull-tar` is explicitly out of
scope in this RFC.

## Network

The following section provides an overview of how to configure networking for containers and
how this will be implemented. A proposal how the API of the NixOS module could look like will
be demonstrated in the [next chapter](#examples-and-interactions).

### "public" networking

This is the most trivial networking mode. It is taken if the `PrivateNetwork`-option of the
`.nspawn`-unit is set to `no`. In this case, the container has full access to the host's network,
otherwise the container will run in its own namespace.

### Default Mode

If nothing else is specified, the [default settings of `systemd-nspawn`](https://github.com/systemd/systemd/blob/v247/network/80-container-ve.network) will
be used for networking. To briefly summarize, this means:

* A [`veth`](https://man7.org/linux/man-pages/man4/veth.4.html) interface-pair will be created,
  one "host-side" interface and a container interface inside its own namespace.
* A dynamically allocated prefix of `0.0.0.0/28` (or `0.0.0.0/24` for virtual zones) will be used
  as address pool to distribute IPv4 addresses via DHCP to containers.

Additionally, basic IPv6 support was implemented:

* By specifying `::/64`, a [RFC4193 ULA prefix](https://tools.ietf.org/html/rfc4193) will be
  allocated to the host-side interface.
* With [`radvd`](https://github.com/radvd-project/radvd), containers can assign themselves addresses from this address prefix by utilizing
  [RFC4862 SLAAC](https://tools.ietf.org/html/rfc4862)

This is necessary since `systemd-networkd` doesn't support router advertisements with
dynamically allocated prefixes.

Hosts will be available on the current system via the
[`mymachines` `nss` module](https://www.freedesktop.org/software/systemd/man/nss-myhostname.html),
which is already taken care of by `systemd-networkd`. This means that container names can be resolved to addresses like DNS names, i.e. `ping containername` works.

### Static networking

It's also possible to assign an arbitrary number of IPv4 and IPv6 addresses statically. This
is internally implemented by using the `Address=` setting of [`systemd.network(5)`](https://www.freedesktop.org/software/systemd/man/systemd.network.html).

An example of how this can be done is shown in the [next chapter](#examples-and-interactions).

### DNS

The current implementation uses [`networking.useHostResolvConf`](https://search.nixos.org/options?channel=20.09&show=networking.useHostResolvConf&from=0&size=50&sort=relevance&query=networking.useHostResolvConf)
to configure DNS via `/etc/resolv.conf` in the container. This option will be **deprecated** as
`systemd` can take care of it:

* If `networkd` is enabled via NixOS, [`systemd-resolved`](https://www.freedesktop.org/software/systemd/man/systemd-resolved.service.html) is enabled as well.
  * By default, DNS for `resolved` will be configured via DHCP which is enabled in the [Default Mode](#default-mode) by default.
  * With only [Static networking](#static-networking) enabled, it is necessary to configure
    configure DNS servers for resolved statically which can be done by setting e.g. DNS
    servers via a `.network`-unit for the `host0` interface.
* The behavior of `networking.useHostResolvConf` can be implemented with pure `systemd`
  by setting the `ResolvConf`-setting for the container's `.nspawn`-unit.

## Migration plan

All features from the old implementation are still supported, however several abstractions
(such as `networking.useHostResolvConf` or `containers.<name>.macvlans`) are dropped and have
to be implemented by specifying unit options for `systemd` in the NixOS module system.

The state directory in `/var/lib/containers/<name>` is also usable by `systemd-nspawn` directly.
Thus, the following steps are necessary:

* Port existing container options to the new module (documentation describing how this can be
  done for each feature **has** to be written before this is considered ready).
* Most of the NixOS configuration can be easily reused except for the following differences:
  * `networkd` is used inside the container rather than scripted networking. This means that
    NixOS's networking configuration may require adjustment. However the basic `networking.interfaces` interface
    is also supported by the `networkd` stack. More notable is that `eth0` inside the container is
    named `host0` by default.
  * As soon as the config is ready to deploy, the state directory in `/var/lib/containers` has to
    be copied to `/var/lib/machines`.
  * Deploy & reboot.
  * See also https://github.com/Ma27/nixpkgs/blob/networkd-containers/nixos/tests/container-migration.nix as POC.

## Imperative management

`systemd` differentiates between "privileged" & "unprivileged" settings. Each privileged (also
called "trusted") `nspawn` unit lives in `/etc/systemd/nspawn`. Since unprivileged container's
don't allow bind-mounts, these will be out of scope. Additionally, this means that
`/etc/systemd/nspawn` has to be writable for administrative users and can't be a symlink to
a store path anymore.

The new implementation is written in Python since it's expected to be more accessible than Perl
and thus more folks are willing to maintain this code (just as it was the case after porting
the VM test driver from Perl to Python).

The following features won't be available anymore in the new script:

* Start/Stop operations, logging into containers: this can be entirely done via [`machinectl(1)`](https://www.freedesktop.org/software/systemd/man/machinectl.html).
* No configuration will be made via CLI flags. Instead, the option set from the
  NixOS module will be used to declare not only the container's configuration, but also
  networking. This approach is inspired by [erikarvsted/extra-container](https://github.com/erikarvstedt/extra-container).

But still, not all features from declarative containers are implemented here, for instance:

* One has to explicitly specify whether to restart/reload a container when updating the config.
  This is done on purpose to avoid duplicating the logic from `switch-to-configuration.pl` here.
* IPv6 prefix delegation is turned off because `radvd`'s configuration is declaratively specified
  when building the host's NixOS.

Examples are in the next chapter.

## Config activation

By default, NixOS has to decide how to activate configuration changes for a container to avoid
e.g. unnecessary reboots, but `reload`s aren't necessarily sufficient either because e.g.
new bind mounts require a reboot. The host's `switch-to-configuration.pl` implements it like
this:

* `systemctl reload systemd-nspawn@container-name.service` runs `switch-to-configuration test`
  inside the container `container-name` using `nsenter`.
* When activating a new config on the host, the following things happen:
  * If the setting `Parameter=` in the container's `.nspawn`-unit is the only thing that has changed,
    a `reload` will be done. This parameter contains the `init`-script for the container's NixOS
    and only changes if the container's NixOS config changes.
  * If anything else changes, `systemd-nspawn@container-name.service` will be scheduled for a restart
    which effectively reboots the container.
* This behavior can be turned off completely which means that the container where this is turned
  off won't be touched at all on `switch-to-configuration`. Additionally, it's possible to always
  force a `reload` or `restart`. See [Examples & Interactions](#examples-and-interactions) for
  details.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

### Basics

A container with a private IPv4 & IPv6 address can be configured like this:

``` nix
{
  nixos.containers.instances.demo = {
    network = {};
    config = { pkgs, ... }: {
      environment.etc."foo".text = "bar";
    };
  };
}
```

It's reachable from locally like this thanks to the `mymachines`-feature of NSS:

```shell
[root@server:~]# ping demo -c1
PING demo(fdd1:98a7:f71:61f0:900e:81ff:fe78:e9d6 (fdd1:98a7:f71:61f0:900e:81ff:fe78:e9d6)) 56 data bytes
64 bytes from fdd1:98a7:f71:61f0:900e:81ff:fe78:e9d6 (fdd1:98a7:f71:61f0:900e:81ff:fe78:e9d6): icmp_seq=1 ttl=64 time=0.292 ms

--- demo ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.214/0.214/0.214/0.000 ms
```

The container can be entirely controlled via `machinectl`:

```shell
$ machinectl reboot demo
$ machinectl shell demo
demo$ ...
```

Optionally, containers can be grouped into a networking zone. Instead of a `veth` pair for each
container, all containers will live in an interface named `vz-<zone>`:

```nix
{
  nixos.containers.zones.demo = {};
  nixos.containers.instances = {
    test1.network.zone = "demo";
    test2.network.zone = "demo";
  };
}
```

IP addresses can be statically assigned to a container as well:

``` nix
{
  nixos.containers.instances.static = {
    network = {
      v4.static.containerPool = [ "10.237.1.3/16" ];
      v6.static.containerPool = [ "2a01:4f9:4b:1659:3aa3:cafe::3/96" ];
    };
    config = {};
  };
}
```

With this change, the containers live in the given subnets and both on the host- and container-side
the network will be properly configured accordingly.

### Advanced Features

MACVLANs are an example for how every unit setting from `networkd` and `nspawn` can be used.
These are helpful to assign multiple virtual interfaces with distinct MAC addresses to a single
physical NIC.

A sub-interface which is actually part of the physical one can be moved into the container's
namespace then:

``` nix
{
  # Config for the physical interface itself with DHCP enabled and associated to a MACVLAN.
  systemd.network.networks."40-eth1" = {
    matchConfig.Name = "eth1";
    networkConfig.DHCP = "yes";
    dhcpConfig.UseDNS = "no";
    networkConfig.MACVLAN = "mv-eth1-host";
    linkConfig.RequiredForOnline = "no";
    address = lib.mkForce [];
    addresses = lib.mkForce [];
  };

  # The host-side sub-interface of the MACVLAN. This means that the host is reachable
  # within the (internal) network at `192.168.2.2`.
  systemd.network.networks."20-mv-eth1-host" = {
    matchConfig.Name = "mv-eth1-host";
    networkConfig.IPForward = "yes";
    dhcpV4Config.ClientIdentifier = "mac";
    address = lib.mkForce [
      "192.168.2.2/24"
    ];
  };
  systemd.network.netdevs."20-mv-eth1-host" = {
    netdevConfig = {
      Name = "mv-eth1-host";
      Kind = "macvlan";
    };
    extraConfig = ''
      [MACVLAN]
      Mode=bridge
    '';
  };

  # Assign a MACVLAN to a container. This is done by pure nspawn.
  systemd.nspawn.vlandemo.networkConfig.MACVLAN = "eth1";
  nixos.containers = {
    instances.vlandemo.config = {
      systemd.network = {
        networks."10-mv-eth1" = {
          matchConfig.Name = "mv-eth1";
          address = [ "192.168.2.5/24" ];
        };
        netdevs."10-mv-eth1" = {
          netdevConfig.Name = "mv-eth1";
          netdevConfig.Kind = "veth";
        };
      };
    };
  };
}
```

### Imperative containers

#### Create a container with a pinned `nixpkgs`

Let the following expression be called `imperative-container.nix`:

```nix
{
  config.nixpkgs = <nixpkgs>;
  config.config = { pkgs, ... }: {
    services.nginx.enable = true;
    networking.firewall.allowedTCPPorts = [ 80 ];
  };

  # This implies that the "default" networking mode (i.e. DHCPv4) is used
  # and not the host's network (which is the default for imperative containers).
  config.network = {};
  config.forwardPorts = [ { hostPort = 8080; containerPort = 80; } ];
}
```

The container can be built like this now:

```
$ nixos-nspawn create imperative ./imperative-container.nix
```

The default page of `nginx` is now reachable like this:

```
$ curl imperative:80 -i
$ curl <IPv4 of the host-side veth interface>:8080 -i
```

#### Modify a container's config imperatively

When `imperative-container.nix` is updated, it can be rebuilt like this:

```
$ nixos-nspawn update imperative --config ./imperative-container.nix
```

By default, it will be **restarted**. This can be overridden via `config.activation.strategy`,
however only `reload`, `restart` and `none` are supported.

Additionally, the way how the container's new config will be activated can be specified
via `--reload` or `--restart` passed to `nixos-nspawn update`.

If declarative containers are attempted to be modified, the script will terminate early with an
error.

#### Manage an imperative container's lifecycle

Reboot/Login/etc can be managed via [`machinectl(1)`](https://www.freedesktop.org/software/systemd/man/machinectl.html):

```
$ machinectl reboot imperative
$ machinectl shell imperative
[root@imperative:~]$ …
```

# Drawbacks
[drawbacks]: #drawbacks

* Explicit dependency on `networkd` (`networking.useNetworkd = true;`) on both the
  host-side and container-side.
  * Since there's a movement to make `systemd-networkd` the default on NixOS, this
    is from the author's PoV not a big problem.

* Need to migrate from existing containers.
  * As demonstrated in [*Migration plan*](#migration-plan), a sane path exists.
  * With a long deprecation time, a rush to migrate can be avoided.
  * This also means that [the container backend](https://github.com/PsyanticY/nixops-container)
    for `nixops` needs to be deprecated.

# Alternatives
[alternatives]: #alternatives


* Implement this feature in e.g. its own (optionally community-maintained) repository:
  * This is problematic due to the changes for [Config activation](#config-activation) that
    required changes in `switch-to-configuration.pl`.
* Keep both the proposed feature and the existing `nixos-container` subsystem in NixOS. In contrast
  to `systemd-nspawn@`, the current container subsystem uses `/var/lib/containers` as state-directory,
  so clashes shouldn't happen:
  * The main concern is increased maintenance workload. Also, with the rather prominent
    name `nixos-container` we shouldn't advertise the old, problematic implementation.
* Do nothing.
  * As shown above, this change leverages the full featureset of `systemd-nspawn` and also
    solves a few existing problems, that are non-trivial to solve when keeping the old
    implementation.
  * Since it's planned to move to `networkd` in the longterm anyways, fundamental changes
    in the container subsystem will be mandatory anyways.

# Unresolved questions
[unresolved]: #unresolved-questions

* None that I'm aware of.

# Future work
[future]: #future-work

* Write documentation for the new module.
* Get the PR into a mergeable state.

