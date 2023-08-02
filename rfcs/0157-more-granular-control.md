---
feature: more-granular-control
start-date: 2023-08-02
author: Animesh Sahu
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

To grant more granular low-level control over the system. Majorly:

* `nix-cli`: Introduce direct access to the store and binary cache.
  - This improvement will facilitate easier binary cache setup, upstream caching, and shallow (non-closure) copies.
  - Users will be able to pull specific paths directly from the cache without relying on derivation realisation as an abstraction.

* `nixos`: Decouple various low-level components of the operating system and make everything "opt-in."
  - This change aims to reduce the disparity observed when using nix inside NixOS and outside NixOS.
  - By making the infrastructure flexible and allowing components to be explicitly chosen, users can adapt to future breaking changes, such as the introduction of pipewire and wayland, even for init systems and bootloaders.

* `flakes`: Enforce the use of flakes for scripting operations.
  - Currently, script infrastructure often involves a `script -> nix language -> script` abstraction, which can make it challenging to modify, reuse, or apply fixes to the underlying script. Examples of this include nixos-rebuild, nixos-generate, and home-manager.
  - With the enforcement of flakes, the former `script ->` abstraction will be reduced, and users can directly use a `nix` command to build the script. The activation script `./result/bin/activation-script` can then be executed to complete the task.


# Motivation
[motivation]: #motivation

One thing perceived negatively about nix is the continuous addition of abstractions aimed at simplifying the overall system.

The problem becomes significant when working with (or swapping) the lower-level components. For instance:

* The bootloader: No successful implementation has been observed using [ZFSBootMenu](https://docs.zfsbootmenu.org) or performing a direct boot with [Unified Kernel Image](https://animeshz.github.io/site/blogs/demystifying-uefi.html#building-a-uki-for-currently-running-desktop-linux) (using gummiboot, for instance).
* The init: Some projects ([not-os](https://github.com/cleverca22/not-os) / [nix-processmgmt](https://github.com/svanderburg/nix-processmgmt)) have attempted to use runit / openrc, but most of those projects do not provide sufficient control over many current services present in nixpkgs.

And the list goes on...

Another observation is that there are scripts (`nixos-generate`) that act as an indirection to nix derivation (`nixosConfiguration.config.system.build.isoImage`), which is, in turn, an indirection to yet another shell script. This abstraction can be reduced by utilizing flake outputs.

This also unintentionally hinders the inspectibility and scriptability of the system. For instance, [Void Linux has highly scriptable frontends](https://animeshz.github.io/site/blogs/void-linux.html#why-is-void-so-cool) to illustrate this.

Although most things are straightforward in nix, such as changing a desktop environment with a one-liner, setting up remote builds and upstream cache can be quite challenging. There are several design problems, such as:

* Dependencies are first downloaded on the host, copied over to the remote builder via ssh, and everything is built there. Then the primary object is copied back to the host.
* There's a `builders-use-substitutes` option on both nix commands (which generally doesn't work without being a `trusted-user`) and the config option at global config `/etc/nix/nix.conf`, which somewhat fixes this problem. However, after the build, the builder still needs to serve the whole closure of the build with the host.
* The output from `nix-store --export /nix/store/{drv-or-output-path} > output` is not importable using `nix-store --import < output` unless the dependencies were already present on the host. You can't ask --import to look for dependencies in the binary cache. One could get a list of dependency paths using `nix-store --query --requisites /nix/store/{drv-or-output-path}`, but there's no exposed way to effectively "pull" those paths from the binary cache before running --import. The only way is to copy the whole closure for every derivation or its output (from the remote builder to the host).
* Upstream caching (not caching the packages available in upstream cache such as `https://cache.nixos.org`) requires extra specific 3rd party infrastructure to set up, such as [cachix](https://www.cachix.org) (service) or [attic](https://docs.attic.rs/tutorial.html#pushing) (self-host).

In void (just as a reference), a package that ignores already upstream-dependency is built (in a chroot by default). This output folder can then act as a simple ad-hoc repository mirror with any http server (including `python3 -m http.server -d hostdir/binpkgs` on the host-machine or even github pages after a build from GitHub actions).


# Detailed design
[design]: #detailed-design

While the current configuration does work for most people, and many are content with the existing solutions, a more granular control system would offer tremendous possibilities for customization and make the infrastructure flexible for future shifts.

Instead of deprecating pulseaudio's `sound.*` in favor of `services.pipewire.*`, we should aim to build a flexible API that persists even when new standards emerge, reducing confusion caused by generic names like "sound" being deprecated.

### Everything is opt-in!

First and foremost, during image building (whether it's nixos-rebuild or vm/iso generation), the filesystem should be empty, with no packages or files.

We can then assemble basic components by defining choices such as the bootloader, kernel, initramfs generator [1], libc, init, and then the choice of sound & de/wm.

This approach also facilitates the use of NixOS-modules on non-NixOS nix installations.

<sub>[1]: Recently [dracut merged](https://github.com/NixOS/nixpkgs/issues/77858), but there are no clear instructions on how to use that.</sub>

### Emphasis on flake over shell script wrappers

With the introduction of `nix run` and `nix build`, all current implementations should transition to using these first-party nix commands instead of wrappers like nixos-rebuild, nixos-generate, and home-manager.

Operating everything under flake also opens up various opportunities, such as building the latest nixos iso image with or without plasma/gnome directly from the nixpkgs repository if its derivation is exposed in flake.nix (for example, `nix build nixpkgs#isoInstallerImageWithGnome`).

### CLI improvements

As explained earlier in the motivation section, the binary cache has no direct access, and using `nix-store --import {exported}` does not automatically pull missing dependencies from the binary cache in case the export does not include the whole closure.

Allowing direct binary-cache access, such as querying information and pulling specific paths into the local `/nix/store`, would be a significant enhancement.

### (optional) stdenv improvements

Optionally, we could accompany this with a simpler, low-abstraction alternative to stdenv, or an opt-in C compiler setup.

It is worth noting that `stdenv.mkDerivation` pulls gcc and autotools, but not all builds require these dependencies. Some simple shell scripts and builds in other languages redundantly pull these dependencies as part of the build, even when builtins.derivation provided by nix language could be sufficient.

The automatic header include and ldflag magic provided by stdenv often leads to a "just-works" mentality, causing us to become overly dependent on it.


# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

### Everything is opt-in!

Decoupling the system from fixed parts can be done by availing configuration options under the NixOS modules:

```nix
{
  # bootloader.grub.enable = false;
  bootloader.gummiboot.enable = true;
  init.runit.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.baseFiles = pkgs.baseFiles_latest;
  # Other system configurations can be added here  ...
}
```

This is an example constituting how one can easily replace grub with gummiboot.

By providing this level of granularity, users can precisely control their system components, opting for their preferred choices while excluding unnecessary defaults. This empowers users to create tailored configurations and enhances the flexibility of their NixOS setups.

### Emphasis on flake over shell script wrappers

[nixos-rebuild](https://github.com/NixOS/nixpkgs/blob/master/pkgs/os-specific/linux/nixos-rebuild/nixos-rebuild.sh) is nothing but a complex shell script, that has to be present in the system beforehand, which basically calls `nix-build` under the hood, building a derivation, and then running the built derivation. All the options can be instead defined in nix language, in the flake definition itself, and the output derivation can be built using the nix command directly.

[nixos-generators](https://github.com/nix-community/nixos-generators#using-in-a-flake) has quite recently started adding flake support through which there's no need to install or do anything of it, a simple `nix build` will build the iso/vm images. Making it transparent as well as reducing the extra script installation setup.

### CLI improvements

This is majorly for improving the binary cache user interaction, remote-builders setup, and cache serving.

This is not the exact design required, but something like this will suffice:

```bash
nix-store -r /nix/store/{some.drv}        ## OR: nix build /nix/store/{some.drv}
# pulls/builds whatever is in $(nix show-derivation /nix/store/{some.drv} | jq '.[] | .inputSrcs, .inputDrvs')
# builds and produces output

nix-store --export /nix/store/{somepath} > file

## This is the main point, pull paths from binary cache, if we exactly know it
nix store pull $(nix-store --query --requisites /nix/store/{some.drv})
nix-store --import < file
```

The purpose of remote builder shouldn't be exactly to serve the built file immediately, maybe to store it in some static-storage, and shutdown, the cache serving should be made accessible using stateless http server, which can happen if we can serve a folder through http.

Articles confuse the binary cache with closure copying, such as [this one](https://nix-tutorial.gitlabpages.inria.fr/nix-tutorial/deploying.html), one of top results in Google with "setting up a binary cache nix" query.

Hence there shouldn't be need of third party package in order to serve something, unnecessary complexity & abstractions should be reduced to fit a simple custom http file server to act as binary cache.

```bash
# Something like:
nix store setup > /nix/store/nix-cache-info

python3 -m http.server -d /nix/store
```

An alternative way could be use of a flake to build isolated directory with the filtered store path references only, or even an option to have upstream filtered paths (that are not in https://cache.nixos.org). Something like:

```nix
{
  # ...
  outputs = args: {
    packages.x86_64-linux.my-binary-cache = some-binary-cache-setup-function {
      packages = [ custom-package-1 custom-package-2 ];
      # ...
    };
  };
}

# nix build '.#my-binary-cache'
# python3 -m http.server -d result
```

Again, an indirect result of flake enforcement.

### (optional) stdenv improvements

Build requirement of C/C++ should be opt-in, it isn't generally true that everything requires C/C++ compiler and header/ldflag setup.

```nix
stdenv.mkDerivation {
  includeCoreutils = true;
  includeC = true;
  # ...
}
```

And most of the time usage of the `builtins.derivation` is far from practical, examples shown in Prior Arts section below.


# Drawbacks
[drawbacks]: #drawbacks

If everything is made opt-in, it may result in a slightly longer initial configuration file, although way more explicit.

There are no perceived drawbacks in flake enforcement / nix-cli improvements.


# Alternatives
[alternatives]: #alternatives

### What other designs have been considered? What is the impact of not doing this?

Not too sure about alternatives, let's discuss potential alternatives (if there are).

If left unimplemented however, abstraction will keep growing and complexity will continue to add up.


# Prior art
[prior-art]: #prior-art

### Remote Builds

* [reference #1 (reddit)](https://www.reddit.com/r/NixOS/comments/l5221x/comment/gm9xre8).
* [reference #2 (gist)](https://gist.github.com/danbst/09c3f6cd235ae11ccd03215d4542f7e7).
* [reference #3 (LnL7/nix-docker) - Setting up a docker container as a remote builder](https://github.com/LnL7/nix-docker/tree/master#running-as-a-remote-builder).
* [reference #4 (DeterminateSystems/magic-nix-cache#24)](https://github.com/DeterminateSystems/magic-nix-cache/issues/24).

### Directly using builtins.derivation

* [reference #1 (article) - How nix builds work](https://jvns.ca/blog/2023/03/03/how-do-nix-builds-work-).

### Standalone service / process management

* [reference #1 (article) - Nix based functional organization](https://sandervanderburg.blogspot.com/2019/11/a-nix-based-functional-organization-for.html).

### Hackernews criticisms

* [Nix has two kinds of problems: the language and the interface...](https://news.ycombinator.com/item?id=30058880)
* [I wish someone wrote a GUI for Nix that...](https://news.ycombinator.com/item?id=30058605)
* [I am a NixOS user, but am interested in Guix...](https://news.ycombinator.com/item?id=30058466)


# Unresolved questions
[unresolved]: #unresolved-questions

1. What other parts of the nix can be simplified (with reduction of abstraction)?
1. Will there be anything other than service creation that will be majorly affected by this change? Enable/disable API should be unchanged I presume.


# Future work
[future]: #future-work

1. Document the changes introduced in cli.
1. In case stdenv with minimal requisites is introduced (opt-in C compiler setup), do necessary changes to shell-script or non-C builds from stdenv.
1. Making low-level primitives openly accessible will expand the range of choices available for enhancing nix, for instance on some points of Hackernews criticisms, and make it easy to create remote builders and substituters directly through the nix command-line interface. Third-party implementations like [nixbuild.net](https://nixbuild.net) and [attic](https://github.com/zhaofengli/attic) will no longer be required to reconstruct all specifications from the ground up.
