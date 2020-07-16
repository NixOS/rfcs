---
feature: nixos_hardware
start-date: 2020-06-20
author: Jörg Thalheim (@Mic92)
co-authors: Profpatch (@Profpatsch)
shepherd-team: @samueldr, @garbas, @edolstra, @Kloenk
shepherd-leader: @Kloenk
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

We are currently having a separate repository to providing NixOS profiles for hardware specific extensions at [nixos-hardware](https://github.com/NixOS/nixos-hardware). This RFC proposes to merge this repository (4000 LOCs/350 commits) and add support for detecting hardware in `nixos-generate-config`.


# Motivation
[motivation]: #motivation

[Nixos-hardware](https://github.com/NixOS/nixos-hardware) relies on specific packages/kernel versions being present in nixpkgs. There is currently no way of preventing nixos-hardware breakages when doing changes in nixpkgs itself. The current best practice is to make sure it does not break with nixpkgs master, which makes less usable for stable users/newcomers. Since it is in an external repository we also cannot integrate  it in [nixos-generate-config](https://github.com/NixOS/nixos-hardware/issues/49) like we do for some other environments like vm nixos profiles because this would require information from the very same repository.

Additionally, some support for hardware is already in nixpkgs (for example [for raspberrypi 3 and 4 images](https://github.com/NixOS/nixpkgs/issues/63720)), but we cannot move them nixos-hardware to not break existing users.

Proper integration in nixpkgs would increase discoverability even just through grep, and enable us to have much more tight tooling around building different kinds of NixOS artifacts, like VMs and images, which would benefit tools like [`nixos-generators`](https://github.com/nix-community/nixos-generators).

# Detailed design
[design]: #detailed-design

In [PR #91167](https://github.com/NixOS/nixpkgs/pull/91167) there is on-going work on how this will be integrated into nixpkgs. In a nutshell it will be a merge of the [nixos-hardware](https://github.com/NixOS/nixos-hardware)'s git history into nixpkgs.

In a follow up PR we would add `nixos-generate-config` support
to add profiles based on the result of dmidecode.


# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

The profiles will be imported like existing profiles:

```nix
{
  imports = [
     <nixpkgs/nixos/hardware/lenovo/thinkpad/t440s>
  ];
}
```


# Licensing

The authors believe that [the `nixos-hardware` license](https://github.com/NixOS/nixos-hardware/blob/master/COPYING)
is CC0, and thus changing it to nixpkgs’ MIT should be possible.

In case it is not legally possible, we will ping all contributors
(which is feasible looking at the github statistics) and remove
their contributions if they don’t agree with the license change.

# Drawbacks
[drawbacks]: #drawbacks

* nixpkgs increases by some 4000 lines of code and 350 commits.
* The hardware definitions might be expected to work flawlessly.

# Alternatives
[alternatives]: #alternatives

Alternatively we can keep nixos-hardware as a separate repository.

There have been only a handful of contributors in a few years,
which has a few possible explanations:


* People write all their hardware definitions manually
* People use nixos-hardware but don’t contribute back
* People just don’t know about nixos-hardware (because it’s not discoverable by grepping through nixpkgs)
* It’s too complicated or too much effort to use/contribute to nixos-hardware, because it’s not in nixpkgs

# Unresolved questions
[unresolved]: #unresolved-questions

1. How to include the hardware configurations without using `<nixpkgs>`?

   Using`pkgs.path` in module `import`s leads to an infinite recursion.
   We could have a mechanism similar to `modulesPath` to work around that. 
   In the beginning, we can just tell people to use `<nixpkgs/nixos/hardware>`. The latter is how nixos-hardware
   imports profiles right now.

2. How to integrate it into hydra/ofborg
   
   We cannot test the workings of the hardware of course,
   but we can add the image builds (or VM builds) to our hydra
   to have better integration than before (before there was no integration).
   
   Some images can only be built on `aarch64`, but that’s what hydra is already set up for.
   As a basic minimum we can ensure evaluation of all nixos profiles.


# Future work
[future]: #future-work

* Make nixos/nixpkgs best-in-class for generating images and isos for embedded systems and cloud platforms.
* Enable full cross-compilation support for generating artifacts for hardware with different architecture, which is common with embedded systems.
* Provide a more solid basis for third-party efforts like [Mobile NixOS](https://github.com/NixOS/mobile-nixos).
