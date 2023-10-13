---
feature: nim-library-lockfiles
start-date: 2023-10-13
author: Emery Hemingway @ehmry
co-authors:
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: https://github.com/NixOS/nixpkgs/pull/260405
---

# Summary
[summary]: #summary

Build the Nim programs in Nixpkgs with libraries selected by lockfiles and remove libraries from the `nimPackages` set. Migrate the Nim packages that remain to correspond to the [simple-package-paths](./0140-simple-package-paths.md) standard.

Nim is a minority language in Nixpkgs but having a small package set makes it ideal as an example of best-practice for other languages.

# Motivation
[motivation]: #motivation

Nim is a language without intermediate compilation artifacts such as static or shared libraries.
Nim libraries are currently packaged in Nixpkgs as unpacked code archives to facilitate reuse between Nim programs.
Having Nim libraries available avoids the need to write fixed-output-fetches in the package expressions of Nim programs, but updating library packages can break programs.
In practice this means high-priority programs such as [Nitter](https://en.wikipedia.org/wiki/Nitter) can block updates to libraries or cause maintainers to manually write FOD library fetches locally in other packages.

The implicit recommendation that Nim libraries be explicitly packaged makes frustration when packaging Nim programs outside of Nixpkgs because overlays can unpredictably shift the libraries selected by `nimPackages.callPackage`.

Replacing Nim library packages with a library lockfile for each Nim programs avoids cross-package breakage when library dependencies are updated.
It also shifts the labor required to package Nim programs from maintaining a collection of FOD expressions to maintaining tooling that can automatically reason over what dependencies are required for a given program.

# Detailed design
[design]: #detailed-design

- Implement and maintain a tool for generating Nix specific lockfiles using the standard packaging metadata local to Nim programs. At the moment this is the [nim_lk](https://git.sr.ht/~ehmry/nim_lk) tool.

- Commit lockfiles into Nixpkgs.

- Expand lockfiles at evaluation time to collections of fetch expressions using `fetchzip`, `fetchgit`, `fetchhg`, etc.

- Augment libraries selected by lockfiles so that Nim wrapper libraries include additional metadata such as `buildInputs` to include shared libraries from non-Nim packages. This mechanism also support version constraints for blacklisting broken or vulnerable libraries.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

## Old way:
```nix
# <nixpkgs>/pkgs/tools/system/ttop/default.nix
{ lib, nimPackages, fetchFromGitHub }:

nimPackages.buildNimPackage (finalAttrs: {
  pname = "ttop";
  version = "1.2.6";
  nimBinOnly = true;

  src = fetchFromGitHub { /* … */ };

  buildInputs = with nimPackages; [ asciigraph illwill parsetoml zippy ];
})
```

## New way:
```nix
# <nixpkgs>/pkgs/by-name/tt/ttop/package.nix
{ lib, buildNimPackage, fetchFromGitHub }:

buildNimPackage (finalAttrs: {
  pname = "ttop";
  version = "1.2.6";

  src = fetchFromGitHub { /* … */ };

  lockFile = ./lock.json;
    # lock.json must be checked into nixpkgs at
    # <nixpkgs>/pkgs/by-name/tt/ttop/lock.json
})
```

## Example lockfile:
```json
{
  "depends": [
    {
      "method": "fetchurl",
      "path": "/nix/store/70cqa9s36dqnmsf179cn9psj77jhqi1l-source",
      "rev": "a4a1affd45ba90bea24e08733ae2bd02fe058166",
      "sha256": "005ib6im97x9pdbg6p0fy58zpdwdbkpmilxa8nhrrb1hnpjzz90p",
      "url": "https://git.sr.ht/~ehmry/nim_cbor/archive/a4a1affd45ba90bea24e08733ae2bd02fe058166.tar.gz",
      "ref": "20230619",
      "packages": [
        "cbor"
      ],
      "srcDir": "src"
    },
    {
      "method": "fetchurl",
      "path": "/nix/store/ffkxmjmigfs7zhhiiqm0iw2c34smyciy-source",
      "rev": "26d62fdc40feb84c6533956dc11d5ee9ea9b6c09",
      "sha256": "0xpzifjkfp49w76qmaylan8q181bs45anmp46l4bwr3lkrr7bpwh",
      "url": "https://github.com/zevv/npeg/archive/26d62fdc40feb84c6533956dc11d5ee9ea9b6c09.tar.gz",
      "ref": "1.2.1",
      "packages": [
        "npeg"
      ],
      "srcDir": "src"
    }
  ]
}
```

## Example library annotations:
```nix
# <nixpkgs>/pkgs/top-level/nim-annotations.nix
{ lib, getdns, pkg-config, openssl }:

# The following is list of overrides that take three arguments each:
# - lockAttrs: an attrset from a Nim lockfile, use this for making constraints on the locked library
# - finalAttrs: final arguments to the depender package
# - prevAttrs: preceding arguments to the depender package
{
  jester = lockAttrs: finalAttrs:
    { buildInputs ? [ ], ... }: {
      buildInputs = buildInputs ++ [ openssl ];
    };

  getdns = lockAttrs: finalAttrs:
    { nativeBuildInputs ? [ ], buildInputs ? [ ], ... }: {
      nativeBuildInputs = nativeBuildInputs ++ [ pkg-config ];
      buildInputs = buildInputs ++ [ getdns ];
    };

  /* … */
}
```

# Drawbacks
[drawbacks]: #drawbacks

- Lockfiles must be checked into Nixpkgs which would bloat the repository.
- Checks on Nim libraries would not be run (unless implemented in `buildNimPackage`).
- Nim programs would be updated as usual but their dependencies would not. Updating lockfiles would be non-trivial for automated tools such as `r-ryantm/nixpkgs-update`.

# Alternatives
[alternatives]: #alternatives

- Continue to manually curate Nim library packages.
- Generate lockfiles for programs as FODs as seen in `(buildGoModule {…}).vendorHash` or `(buildRustPackage {…}).cargoHash`.
- Automatically generate a package set of Nim programs externally, see the [Nimble flake](https://github.com/nix-community/flake-nimble).

# Prior art
[prior-art]: #prior-art

- Go vendor hash
- Javascript has dependency information in JSON files checked to Nixpkgs.
- Ruby has locked Gemfile and common maintained libraries.
- Rust vendor hash

- [Dream2nix](https://github.com/nix-community/dream2nix) incorporates lockfiles but is outside of the Nixpkgs repo.

# Unresolved questions
[unresolved]: #unresolved-questions

- Fine-grain overrides for libraries selected by lockfiles.
- Running library tests.

# Future work
[future]: #future-work

- Decompression support in Nix for large blobs of JSON?
