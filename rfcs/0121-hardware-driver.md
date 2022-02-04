---
feature: Use a more canonical name for hardware driver path and modules
start-date: 2022-02-03
author: @jonringer
co-authors:
shepherd-team:
shepherd-leader:
related-issues: https://github.com/NixOS/nixpkgs/issues/141803
---

# Summary
[summary]: #summary

Currently, NixOS mounts video drivers under the path `/run/opengl-driver/`,
but should be mounted under a more generic '/run/hardware-drivers/` path.
The usage of opengl explicitly may have been an accurate name given the time
in which NixOS was first created; however, graphic drivers alone include much
more than just userland graphics libraries so this usages is now misaligned with
current paradigms. The misalignment with this path and the related Nixpkgs
utilities are a misnomer in most contexts, and contributes to Nixpkgs' 
"weirdness budget".

# Motivation
[motivation]: #motivation

Video drivers ship many hardware acceleration libraries these days: vulkan,
opengl, opencl, video encoding, cuda, and many other userland libraries are
installed. Having all of these libraries placed under a single "opengl" header
is odd for many contributors, especially newcomers. This awkwardness is
compounded with other specialized hardware such as fpgas, tpus, and asics
where their function isn't related to graphics, however, also need to make
use of a "known good" path in which the related userland libraries will be mounted.

To remedy this misalignment, a new convention around placing those libraries
should be used, preferably `/run/hardware-drivers/`.

# Detailed design
[design]: #detailed-design

Most of the implementation of the current paradigms will continue, as there
will always be a need for some "impurity" around hardware based libraries.
The significant changes will be around naming conventions used within
Nixpkgs and NixOS.

Deprecate and move existing `/run/opengl-drivers/` logic:
- Rename `hardware.opengl` options to `hardware.drivers`
- Rename `pkgs.addOpenGLRunpath` shell hook to `addHardwareRunpath`
  - Alias `addOpenGLRunpath` to `addHardwareRunpath` for compatibility
- Update nixpkgs references of `/run/opengl-driver/` to point to `/run/hardware-drivers/`
- Update `mesa.driverLink` to point to `/run/opengl-drivers/lib`

For compatibility with existing nixpkgs packages, `/run/opengel-drivers{,-32}/` will
be a symbolic link to `/run/hardware-drivers/`. This will likely be
an indefinite change, or else older packages will not work on NixOS. Also,
we need to ensure compatibility with out-of-tree code which may have been built around
the opengl paths, such as [nixGL](https://github.com/guibou/nixGL).

# Drawbacks
[drawbacks]: #drawbacks

Technical churn. Doesn't provide any new or added benefit, other than
correcting a stale misnomer.

# Alternatives
[alternatives]: #alternatives

Continue to use `/run/opengl-driver` in it's current state.

# Unresolved questions
[unresolved]: #unresolved-questions

Is there a better name for the path, nixos module options, and nixpkgs hook?

This is also an opportunity to revisit the `hardware.opengl` module. Some
potential improvements could be:
- Move `hardware.opengl.package` + `hardware.opengl.extraPackages` to a single `hardware.drivers.packages`
  - The current paradigm seems to be a compromise of `package` existing, but needed to adapt for other hardware acceleration libraries.
  - Enable option can default to `hardware.drivers.packages != []` ?

# Future work
[future]: #future-work

- Execute the actions outlined in the detailed design
- Update release notes
- Update documentation which mentions older usages of the shell hook or nixos options.

