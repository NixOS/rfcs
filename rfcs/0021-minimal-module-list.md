---
feature: minimal-module-list
start-date: 2018-01-12
author: Eelco Dolstra
co-authors: (find a buddy later to help our with the RFC)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Evaluating a NixOS configuration is getting ever slower due to the
reliance on a global list of modules unconditionally included by every
configuration. The proposal is to switch from the use of `enable`
options to explicit inclusion of needed modules.

# Motivation
[motivation]: #motivation

NixOS evaluation is getting slower with every release, as can be seen
here:

* https://hydra.nixos.org/job/nixpkgs/trunk/metrics/metric/nixos.smallContainer.time
* https://hydra.nixos.org/job/nixpkgs/trunk/metrics/metric/nixos.lapp.time
* https://hydra.nixos.org/job/nixpkgs/trunk/metrics/metric/nixos.kde.time

Evaluator memory use grows similarly, e.g.

* https://hydra.nixos.org/job/nixpkgs/trunk/metrics/metric/nixos.smallContainer.allocations

This increase in resource consumption is particularly problematic for
NixOps networks consisting of many machines.

The main reason for the increase is the growth in the number of NixOS
modules, from 497 in `module-list.nix` in NixOS 15.09 to 739 in
17.09. The module system needs to evaluate every module, even though
most modules are not needed for a particular configuration.

The proposal is to require most modules to be included explicitly in a
system configuration. That is, rather than writing e.g.

    hardware.pulseaudio.enable = true;

you write

    imports = [ <nixpkgs/nixos/modules/config/pulseaudio.nix> ];

For example, here is the time and memory consumption for evaluating a
50-machine NixOps network:

| Nixpkgs                     | Time (s) | RSS (MiB) |
| --------------------------- | -------- | --------- |
| 17.09                       | 73.7     | 6470      |
| 17.09 minimal               | 19.5     | 2577      |
| 17.09 minimal + memoisation | 12.5     | 1532      |

The "minimal" configuration replaces `module-list.nix` with a [smaller
list](https://pastebin.com/GSHS8q67). (This list can be reduced a bit
further by eliminating some unnecessary module dependencies,
e.g.`hardware/opengl.nix` and `services/networking/dnsmasq.nix` are
unnecessary. On the other hand, some modules that are not needed to
evaluate the configuration but that are needed to get a workable
system are probably missing.)  "Memoisation" refers to using the
[memoisation
primop](https://github.com/NixOS/nix/commit/0395b9b94af56bb814810a32d680c606614b29e0)
to eliminate repeated evaluations of Nixpkgs; it does not prevent
repeated evaluations of the NixOS module system.

# Detailed design
[design]: #detailed-design

* Replace `module-list.nix` with a minimal set of modules, i.e. a
  bare minimal NixOS system.

* Get rid of unnecessary implicit module dependencies (but see
  below). In particular, `pam.nix` and `nsswitch.nix` need to be
  modularized. For example, options related to Kerberos should be
  moved out of `pam.nix`.

* `xserver.nix` should not import all display/window/desktop manager
  modules.

* For compatibility, we can provide a `all-modules.nix` that imports
  all modules.

* Most `enable` options defaults should be changed to `true`, so that
  including a module activates it automatically. (But see below.)

* The manual needs to show what module needs to be imported to enable
  something. Or options should be listed per-module.

...

# Drawbacks
[drawbacks]: #drawbacks

...

# Alternatives
[alternatives]: #alternatives

The alternative is to continue with the current approach of including
every module in `module-list.nix`. However, it's clear that this
approach does not scale. Performance improvements to the evaluator can
only delay the module apocalypse.

# Unresolved questions
[unresolved]: #unresolved-questions

Many modules have unnecessary implicit module dependencies, where one
module defines an option declared in another. For example,
`network-interfaces.nix` sets `virtualisation.vswitch`, requiring
`virtualisation/openvswitch.nix` to be included even when
`networking.vswitches = {}`. It's not clear what the best way is to
deal with these. The option `networking.vswitches` could be moved to
`virtualisation/openvswitch.nix`. Another approach is to provide
modules with a mechanism to define options that may not have a
declaration (in which case they would be ignored, rather than trigger
an error).

Should `enable` options default to `true`? This may not be desirable
if one module imports another because it has an optional dependency on
the latter's functionality.

It might be nice to have a `<modules>` namespace in the Nix search
path consisting of all modules available in the search path. This
would make configurations agnostic as to the location of a module. For
instance, instead of

    imports = [ (builtins.fetchgit https://github.com/edolstra/dwarffs + "/modules/dwarffs.nix") ];

you would write

    imports = [ <modules/dwarffs.nix> ];

where Nix would be invokes as

    nix-build ... -I https://github.com/edolstra/dwarffs

# Future work
[future]: #future-work

...
