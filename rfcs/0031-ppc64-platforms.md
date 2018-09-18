---
feature: ppc64-platforms
start-date: 2018-08-23
author: CrystalGamma
co-authors: (find a buddy later to help out with the RFC)
related-issues: https://github.com/NixOS/nixpkgs/pull/45340 https://github.com/NixOS/nixpkgs/pull/45472 https://github.com/NixOS/nixpkgs/pull/45474 https://github.com/NixOS/nixpkgs/pull/45475
---

# Summary
[summary]: #summary

Bring support for ppc64 platforms, initially especially ppc64le, to nixpkgs/NixOS.

# Motivation
[motivation]: #motivation

NixOS/nixpkgs has long prided itself to be a general-purpose OS/package repository, allowing its packages to be used across a broad range of systems, and providing more packages than ever.

With alternative architectures such as OpenPOWER and RISC-V gaining traction, now is the time to add support for those architectures.
Specifically motivating this request is the OpenPOWER, or powerpc64le, architecture—and its embodiment in the POWER series of microprocessors from IBM.
Fully open source commercially available systems have recently become widely available for this platform and there are active Nix users who desire support.

# Detailed design
[design]: #detailed-design

The purpose of this RFC is to create consensus for general acceptance of ppc64(le) related pull requests (as long as they are technically reasonable).
A general commitment for contributions to not break ppc64(le) is not necessary as long as the architecture stays in only niche use.
This especially means that building a Continuous Integration infrastructure for ppc64le is not required in the near future.

Bringing support for ppc64(le) platforms will be done as follows:

The first step for implementing support is extending lib/ to recognize powerpc64(le) as a CPU architecture and allowing bootstrap files for the architecture to be (cross-)built and a stdenv based on those bootstrap files to be built.
This has already been merged in [nixpkgs#45340](https://github.com/NixOS/nixpkgs/pull/45340).

The author of this RFC is already running a NixOS-based system on his POWER9-based computer, so for a basic system without graphical interface, only a handful of packages are known to require changes to build a working system:

* mesa: currently assumes that any non-ARM system is x86. Requires restructuring the driver selection, but to the author's knowledge (since no actual graphical software was tested yet) it should not require any changes to the actual build description. ([nixpkgs#45474](https://github.com/NixOS/nixpkgs/pull/45474))
* strace: also assumes that any non-ARM system is x86 and so tries to use the m32 personality. Requires checking the available machine personalities for all non-x86 architectures. ([nixpkgs#45472](https://github.com/NixOS/nixpkgs/pull/45472), already merged)
* TeX Live: builds LuaJIT as part of mfluajit, which doesn't work because LuaJIT doesn't support 64-bit Power architectures yet; seems to be possible to disable on that platform without too much impact. ([nixpkgs#45475](https://github.com/NixOS/nixpkgs/pull/45475))
* Bootloader tooling:
    * the internal option *system.boot.loader.kernelFile* is currently set to the kernelTarget attribute of the host platform definition.
      PowerPC kernels however use `zImage` as build target, yet produce a `vmlinux` file.
      A one-line change would allow the option to default to the host platform definition's kernelFile attribute, if set.
    * A typical bootloader for OpenPOWER systems is Petitboot. It can read a variety of bootloader configuration files, including those of GRUB 2 and SYSLINUX.
      Using GRUB, even with *boot.loader.grub.device* = "nodev", as it is, implies building GRUB for the host architecture, which fails for ppc64le (currently because it requires soft-float).

      However, the generic-extlinux-compatible bootloader module can be modified to provide options to store the configuration files in a path that Petitboot will consider and use absolute paths starting from the filesystem root, so that Petitboot can load the kernel/initrd images.

Beyond a headless system, the biggest obstacle for ppc64(le) support seems to be Rust, because a lot of desktop software has it as a (direct or transitive) build dependency.
In particular, a lot of GNOME software has a dependency on librsvg (which has parts written in Rust) via their documentation tools.
The author of this RFC plans to create a way to build bootstrapping binaries for Rust on ppc64le (either via cross-building from x86 or from source via mrustc).

Some packages, like OpenBLAS, will need target descriptions for these platforms, but many don't require changes to the actual build process.

Support for Big Endian ppc64 might require changes in a few packages, though the majority of changes are assumed to be upstreamable (see [Unresolved Questions][unresolved]).

# Drawbacks
[drawbacks]: #drawbacks

Supporting another architecture might introduce additional maintenance overhead for nixpkgs.
Generally this is restricted to packages that ship (JIT or AOT) compilers or do some feature selection based on architectures.

If a new Rust bootstrap is created for ppc64le, as long as it isn't adopted for the other platforms, it will be a second rustc bootstrap that may cause maintenance effort.

If a build infrastructure of ppc64le systems should be established, it will cause maintenance effort as well as costs for either procurement of hardware, or use of public cloud services (e. g. IntegriCloud), unless an organisation is willing to sponsor build machines. 

# Alternatives
[alternatives]: #alternatives

For ppc64(le) in general:

* keep the already-merged stdenv/bootstrapping code, maintain package changes as an overlay
* revert stdenv/bootstrapping support, maintain ppc64le as a nixpkgs fork
* not have ppc64le support in any NixOS-based distribution (barely an alternative)

# Unresolved questions
[unresolved]: #unresolved-questions

Should the nixpkgs/NixOS project host bootstrap files for ppc64le?

Should Big Endian be in-scope for this RFC?

# Future work
[future]: #future-work

If Big Endian support on ppc64 is decided to be out of scope for this RFC, it might be of interest for a future project.
