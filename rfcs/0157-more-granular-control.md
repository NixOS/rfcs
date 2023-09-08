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

To grant more granular low-level control over the system. Majorly, to decouple various low-level components of the operating system and make everything "opt-in."
  - This change aims to reduce the disparity observed when using nix inside NixOS and outside NixOS.
  - By making the infrastructure flexible and allowing components to be explicitly chosen, users can adapt to future breaking changes, such as the introduction of pipewire and wayland, even for init systems and bootloaders.


# Motivation
[motivation]: #motivation

One thing perceived negatively about nix is the continuous addition of abstractions aimed at simplifying the overall system.

The problem becomes significant when working with (or swapping) the lower-level components. For instance:

* The bootloader: No successful implementation has been observed using [ZFSBootMenu](https://docs.zfsbootmenu.org) or performing a direct boot with [Unified Kernel Image](https://animeshz.github.io/site/blogs/demystifying-uefi.html#building-a-uki-for-currently-running-desktop-linux) (using gummiboot, for instance).
* The init: Some projects ([not-os](https://github.com/cleverca22/not-os) / [nix-processmgmt](https://github.com/svanderburg/nix-processmgmt)) have attempted to use runit / openrc, but most of those projects do not provide sufficient control over many current services present in nixpkgs.

And the list goes on...

While the current configuration does work for most people, and many are content with the existing solutions, a more granular control system would offer tremendous possibilities for customization and make the infrastructure flexible for future shifts.

Instead of deprecating pulseaudio's `sound.*` in favor of `services.pipewire.*`, we should aim to build a flexible API that persists even when new standards emerge, reducing confusion caused by generic names like "sound" getting deprecated.


# Detailed design
[design]: #detailed-design

**Everything is opt-in!**

First and foremost, during image building (whether it's nixos-rebuild or vm/iso generation), the filesystem should be empty, with no packages or files.

We can then assemble basic components by defining choices such as the bootloader, kernel, initramfs generator, libc, init, privilege escalator and then finally the choice of sound daemon & DE/WM.

Just a note, [dracut (initramfs generator) just got merged](https://github.com/NixOS/nixpkgs/issues/77858), but there are no clear instructions on how to use that, if exposed through options can also be made easy to switch to.

This approach will also facilitate the use of NixOS-modules on non-NixOS nix installations.


# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

Decoupling the system from fixed parts can be done by availing configuration options under the NixOS modules:

```nix
{
  # bootloader.grub.enable = false;
  # bootloader.zfsbootmenu.enable = false;
  bootloader.gummiboot.enable = true;
  init.runit.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Other system configurations can be added here  ...
}
```

This is an example constituting how one can easily replace grub with gummiboot or zfsbootmenu.

By providing this level of granularity, users can precisely control their system components, opting for their preferred choices while excluding unnecessary defaults. This empowers users to create tailored configurations and enhances the flexibility of their NixOS setups.


# Drawbacks
[drawbacks]: #drawbacks

If everything is made opt-in, it may result in a slightly longer initial configuration file, although way more explicit.

# Alternatives
[alternatives]: #alternatives

### What other designs have been considered? What is the impact of not doing this?

Not too sure about alternatives, let's discuss potential alternatives (if there are).

If left unimplemented however, abstraction will keep growing and complexity will continue to add up, and currently chosen low-level components will continue to become an inseparable part of the NixOS.


# Prior art
[prior-art]: #prior-art

### Standalone service / process management

* [reference #1 (article) - Nix based functional organization](https://sandervanderburg.blogspot.com/2019/11/a-nix-based-functional-organization-for.html).

### Hackernews criticisms

* [Nix has two kinds of problems: the language and the interface...](https://news.ycombinator.com/item?id=30058880)
* [I wish someone wrote a GUI for Nix that...](https://news.ycombinator.com/item?id=30058605)
* [I am a NixOS user, but am interested in Guix...](https://news.ycombinator.com/item?id=30058466)


# Unresolved questions
[unresolved]: #unresolved-questions

1. What other parts of the nix can be simplified (with reduction of abstraction)?
1. Will there be anything other than service creation that will be majorly affected by this change? Serive enable/disable API should be unchanged I presume.


# Future work
[future]: #future-work

1. Service unit creation may be majorly affected by the change, may need a module that generalize the api and expands to each of possible service manager types so whatever is current init can work with that.
