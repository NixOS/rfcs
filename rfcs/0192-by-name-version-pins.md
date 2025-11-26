---
feature: by-name-version-pins
start-date: 2025-11-25
author: Quantenzitrone
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: https://github.com/NixOS/nixpkgs/pull/464396
---

# Summary
[summary]: #summary

Add an additional file `pins.nix` to the `pkgs/by-name` structure that allows
overriding/pinning versions of package dependencies.

# Motivation
[motivation]: #motivation

> Why are we doing this?

- The `pkgs/by-name` structure doesn't have support for overriding packages yet
  leading to a lot of remaining entries in `pkgs/top-level/all-packages.nix`.
- Packages with dependency version pins often get neglected and stay on the old
  version for a long time, even though it already supports the new version. By
  having dependency version pins in a defined location with a defined structure,
  package update bots or scripts could check if the package works without the
  pin and remove it automatically on update.

> What use cases does it support?

- Pinning dependency versions of packages.

> What is the expected outcome?

- Less confusion if dependency pins should go into `all-packages.nix` or be
  inlined in the `package.nix`.
- Less maintenance burden due to possible automation of pin removal.

# Detailed design
[design]: #detailed-design

In addition to `pkgs/by-name/{shard}/{pname}/package.nix` there can also be
`pkgs/by-name/{shard}/{pname}/pins.nix`. This file will have the following structure:

```nix
{
  package-a_version,
  package-b_version,
  # ...
}:
{
  package-a = package-a_version;
  package-b = package-b_version;
  # ...
}
```

- Every attrName in the resulting attribute set has to be a valid package
  attribute name.
- Every attrValue should be the pinned version of the respectice attrName
  package, this is however hard to check I think.
- Every attrName has to be a functionArg of the `package.nix`.

I think you know where this is going.

Packages with a `pin.nix` will have the versions of dependencies pinned
accordingly. This can be easily achieved with:

```nix
if lib.pathExists (packageDirectory + "/pins.nix") then
  let
    pins = lib.removeAttrs (callPackage (packageDirectory + "/pins.nix") { }) [
      "override"
      "overrideDerivation"
    ];
  in
  callPackage (packageDirectory + "/package.nix") pins
else
  callPackage (packageDirectory + "/package.nix") { }
```

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

# Drawbacks
[drawbacks]: #drawbacks

Probably longer eval time, this has to be tested however.

# Alternatives
[alternatives]: #alternatives

- Keep the current situation: version pins are either in `all-packages.nix` or
  directly in the `package.nix`.
- Some more generalized `overrides.nix` without the strict requirements.
- Your suggestion here.

# Prior art
[prior-art]: #prior-art

- [RFC 140](https://github.com/NixOS/rfcs/blob/master/rfcs/0140-simple-package-paths.md)
  lists the problem this RFC is trying to solve under "Future work".

# Unresolved questions
[unresolved]: #unresolved-questions

# Future work
[future]: #future-work

- pinning versions of packages, e.g. having ffmpeg_7 as a subattribute of ffmpeg
  (not dependency pinning, what this rfc is about)
