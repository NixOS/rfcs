---
feature: flakes
start-date: 2019-06-25
author: Eelco Dolstra
co-authors: TBD
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

This RFC proposes a mechanism to package Nix expressions into
composable entities called "flakes". Flakes allow hermetic,
reproducible evaluation of multi-repository Nix projects; impose a
discoverable, standard structure on Nix projects; and replace previous
mechanisms such as Nix channels and the Nix search path.

# TLDR

* A prototype implementation is available in Nixpkgs: `nix run
  nixpkgs.nixFlakes`.

* Flakes replace channels. For example,

      # nix run nixpkgs:hello -c hello

  fetches the latest version of [the `nixpkgs`
  flake](https://github.com/edolstra/nixpkgs/blob/release-19.03/flake.nix)
  from GitHub and builds its `hello` package. Similarly, Nix itself is
  a flake, so you can get the latest version as follows:

      # nix run nix

* Flakes are looked up in a
  [registry](https://raw.githubusercontent.com/NixOS/flake-registry/master/flake-registry.json)
  that maps identifiers such as `nixpkgs` to actual locations such as
  `github:edolstra/nixpkgs/release-19.03`. You can use such locations
  ("flake references") directly in the `nix` command:

  ```
  # nix build github:NixOS/patchelf
  ```

* For a reproducible result, you can also use a specific revision:

  ```
  # nix build nixpkgs/a0e1f50e6f72e5037d71a0b65c67cf0605349a06:hello
  ```

* To get information about a flake:

  ```
  # nix flake info nixpkgs
  Description:   A collection of packages for the Nix package manager
  Revision:      a0e1f50e6f72e5037d71a0b65c67cf0605349a06
  ...
  ```

* In addition to the global registry, there is a per-user
  registry. This can be used to pin flakes to the current version:
  ```
  # nix flake pin nixpkgs
  ```
  or to a specific version:
  ```
  # nix flake add nixpkgs github:edolstra/nixpkgs/a0e1f50e6f72e5037d71a0b65c67cf0605349a06
  ```

* Flakes can have dependencies on other flakes. For example, [the
  `patchelf`
  flake](https://github.com/NixOS/patchelf/blob/master/flake.nix)
  depends on the `nixpkgs` flake. To ensure reproducibility,
  dependencies are pinned to specific versions using a *lock file*
  (e.g. [for
  patchelf](https://github.com/NixOS/patchelf/blob/master/flake.lock)). Lock
  files are generated automatically.

* Flakes are evaluated in pure mode, meaning they can't access
  anything other than their own source or declared dependencies. This
  allows `nix` to cache evaluation results.

* The `nix` command is flake-based. For example,
  ```
  # nix build
  ```
  builds the flake in the current directory.

# Motivation
[motivation]: #motivation

Flakes are motivated by a number of serious shortcomings in Nix:

* While Nix pioneered reproducible builds, sadly, Nix expressions are
  not nearly as reproducible as Nix builds. Nix expressions can access
  arbitrary files (such as `~/.config/nixpkgs/config.nix`),
  environment variables, and Git repositories. This means for instance
  that it is hard to ensure reproducible evaluation of NixOS or NixOps
  configurations.

* Nix projects lake discoverability and a standard structure. For
  example, it's just convention that a repository has a `release.nix`
  for Hydra jobs and a `default.nix` for packages.

* There is no standard way to compose Nix projects. Typical ways are
  to rely on the Nix search path (e.g. `import <nixpkgs>`) or to use
  `fetchGit` or `fetchTarball`. The former has poor reproducibility,
  while the latter is bad UX because of the need to manually update
  Git hashes to update dependencies.

* `nix-channel` needs a replacement: channels are hard to create,
  users cannot easily pin specific versions of channels, channels
  interact in *ad hoc* ways with the Nix search path, and so on.

The flakes mechanism seeks to address all these problems. It can be
seen as a "Cargo/NPM/... for Nix" except that it's built into Nix
rather than a separate tool.

# Detailed design
[design]: #detailed-design

## Flakes

A flake is a Git repository that contains a file named `flake.nix` in
the root directory. (In the future, there might be other types of
flakes, such as Mercurial repositories or tarballs.) `flake.nix`
specifies some metadata about the flake such as dependencies, as well
as its *outputs* (the Nix values such as packages or NixOS modules
provided by the flake).

As an example, below is the `flake.nix` of
[`dwarffs`](https://github.com/edolstra/dwarffs). It depends on the
Nixpkgs flake and provides a package (i.e. an installable derivation)
and a NixOS module.

```
{
  name = "dwarffs";

  epoch = 201906;

  description = "A filesystem that fetches DWARF debug info from the Internet on demand";

  inputs = [ "nixpkgs" ];

  outputs = inputs: rec {
    packages.dwarffs =
      with import inputs.nixpkgs { system = "x86_64-linux"; };

      stdenv.mkDerivation {
        name = "dwarffs-0.1.${lib.substring 0 8 inputs.self.lastModified}";

        buildInputs = [ fuse nix nlohmann_json boost ];

        NIX_CFLAGS_COMPILE = "-I ${nix.dev}/include/nix -include ${nix.dev}/include/nix/config.h -D_FILE_OFFSET_BITS=64";

        src = inputs.self;

        installPhase =
          ''
            mkdir -p $out/bin $out/lib/systemd/system

            cp dwarffs $out/bin/
            ln -s dwarffs $out/bin/mount.fuse.dwarffs

            cp ${./run-dwarffs.mount} $out/lib/systemd/system/run-dwarffs.mount
            cp ${./run-dwarffs.automount} $out/lib/systemd/system/run-dwarffs.automount
          '';
      };

    nixosModules.dwarffs = import ./module.nix inputs;

    defaultPackage = packages.dwarffs;

    checks.build = packages.dwarffs;
  };
}
```

A flake has the following attributes:

* `epoch`: A number that specifies the version of the flake
  syntax/semantics to be used. This allows the interpretation of
  flakes to change in the future. It also enables some evolution of
  the Nix language; for example, the Nix files in the flake could be
  parsed using a syntax determined by the epoch. The only currently
  allowed value is `201906`. Nix rejects flakes with an unsupported
  epoch.

* `name`: A identifier for the flake, used to reference it from
  `inputs`. (E.g. the `nixpkgs` in `inputs.nixpkgs` refers to the
  identifier of the Nixpkgs flake.)

* `description`: A short description of the flake.

* `inputs`: The dependencies of the flake, as a list of flake
  references (described below).

* `outputs`: A function that, given an attribute set containing the
  outputs of each of the inputs, yields the Nix values provided by
  this flake. A number of outputs have a special meaning, as discussed
  below.

## Well-known outputs

A number of outputs have a specific meaning to Nix or other tools like
Hydra. Currently, these are:

* `packages`: A set of derivations used as a default by most `nix`
  commands. For example, `nix run nixpkgs:hello` uses the
  `packages.hello` attribute of the `nixpkgs` flake. It cannot contain
  any non-derivation attributes. This also means it cannot be a nested
  set! (The rationale is that supporting nested sets requires Nix to
  evaluate each attribute in the set, just to discover which packages
  are provided.)

* `defaultPackage`: A derivations used as a default by most `nix`
  commands if no attribute is specified. For example, `nix run
  dwarffs` uses the `defaultPackage` attribute of the `dwarffs` flake.

* `checks`: A non-nested set of derivations built by the `nix flake
  check` command, or by Hydra if a flake does not have a `hydraJobs`
  attribute.

* `hydraJobs`: A nested set of derivations built by Hydra.

* `devShell`: A derivation that defines the shell environment used by
  `nix dev-shell` if no specific attribute is given. If it does not
  exist, then `nix dev-shell` will use `defaultPackage`.

* `apps`: A set of app definitions used by the `nix app` command. For
  example, `nix app blender-bin:blender_2_79` uses the
  `apps.blender_2_79` output of the `blender-bin` flake.

* `defaultApp`: A app definition used by the `nix app` command when no
  specific attribute is given. For example, `nix app blender-bin` uses
  the `defaultApp` output of the `blender-bin` flake.

TODO: NixOS-related outputs such as `nixosModules` and `nixosSystems`.

## Flake references

Flake references are a vaguely URL-like syntax to specify which flake
to use. This is used on the command line (e.g. in `nix build
nixpkgs:hello`, `nixpkgs` is a flake reference), and in the list of
flake dependencies in `flake.nix` (e.g. in `inputs = [ "nixpkgs" ];`).

Currently the following types of flake references are supported:

* Git repositories. These have the form

      (http|https|ssh|git|file):(//<server>)?<path>(\?<params>)?

  with the constraint that <path> must end with `.git` for non-`file`
  repositories. <params> are a list of key/value pairs in URI query
  parameter syntax. The following parameters are supported:

  * `ref`: The branch or tag to fetch. The default is `master`.
  * `rev`: The Git commit hash to fetch. Note that this commit must be
    an ancestor of `ref`, since Nix doesn't clone the entire
    repository, only the specified `ref` (and the Git protocol doesn't
    allow fetching a `rev` without a known `ref`).
  * `dir`: The subdirectory of the repository in which `flake.nix` is
    located. This parameter enables having multiple flakes in a
    repository. The default is the root directory.

  For example, the following are valid Git flake references:

  * `https://example.org/my/repo.git`
  * `https://example.org/my/repo.git?dir=flake1`
  * `ssh://git@github.com:NixOS/nix.git?ref=v1.2.3`
  * `git://github.com/edolstra/dwarffs.git?ref=unstable&rev=e486d8d40e626a20e06d792db8cc5ac5aba9a5b4`
  * `file:///home/my-user/some-repo/some-repo.git`

* Local paths. These have the form

      <path>(\?<params)?

  where `<path>` must refer to (a subdirectory of) a Git repository.
  These differ from `file://` flake references in a few ways:

  * They refer to the working tree (unless an explicit `rev` or `ref`
    is specified), so evaluation can access dirty files. (Dirty files
    are files that are tracked by git but have uncommitted changes.)

  * The `dir` parameter is automatically derived. For example, if
    `/foo/bar` is a Git repository, then the flake reference
    `/foo/bar/flake` is equivalent to `/foo/bar?dir=flake`.

* GitHub repositories. These are downloaded as tarball archives,
  rather than through Git. This is often much faster and uses less
  disk space since it doesn't require fetching the entire history of
  the repository. On the other hand, it doesn't allow incremental
  fetching (but full downloads are often faster than incremental
  fetches!). The syntax is:

      github:<owner>/<repo>(/<rev-or-ref>)?(\?<params>)?

  `<rev-or-ref>` specifies the name of a branch or tag (`ref`), or a
  commit hash (`rev`). Note that unlike GitHub, Git allows fetching by
  commit hash without specifying a branch or tag.

  The only supported parameter is `dir` (see above).

  Some examples:

  * `github:edolstra/dwarffs`
  * `github:edolstra/dwarffs/unstable`
  * `github:edolstra/dwarffs/d3f2baba8f425779026c6ec04021b2e927f61e31`

* Indirections through the flake registry. These have the form

      <flake-id>(/<rev-or-ref>(/rev)?)?

  These perform a lookup of `<flake-id>` in the flake registry. The
  specified `rev` and/or `ref` are then merged with the entry in the
  registry. (See below.) For example, `nixpkgs` and
  `nixpkgs/release-19.03` are indirect flake references.

In the future, we should also add tarball flake references
(e.g. `https://example.org/nixpkgs.tar.xz`). It would also be
straight-forward to add flake references to Mercurial repositories
since Nix already has Mercurial support.

## Flake registries

Flake registries map symbolic flake identifiers (e.g. `nixpkgs`) to
"direct" flake references (i.e. any type of flake reference that's not
an indirection). This is a convenience to users, allowing them to do

    nix run nixpkgs:hello

rather than

    nix run github:NixOS/nixpkgs:hello

There are multiple registries:

* The global registry
  https://raw.githubusercontent.com/NixOS/flake-registry/master/flake-registry.json. (This
  location can be overriden via the `flake-registry` option.) Nix
  automatically fetches this registry periodically. The check interval
  is determined by the `tarball-ttl` option.

* The local registry `~/.config/nix/registry.json`.

* Registry entries specified on the command line.

A registry is a JSON file that looks like this:

```
{
    "version": 1,
    "flakes": {
        "nixpkgs": {
            "uri": "github:NixOS/nixpkgs"
        },
        ...
    }
}
```

With this registry, flake references resolve as follows:

* `nixpkgs` -> `github:NixOS/nixpkgs`
* `nixpkgs/release-19.03` -> `github:NixOS/nixpkgs/release-19.03`
* `nixpkgs/f1c995e694685d6dfb877f6428d3e050d30e253c` -> `github:NixOS/nixpkgs/f1c995e694685d6dfb877f6428d3e050d30e253c`

The registries are searched in reverse order. Thus the local registry
overrides the global registry, and the command line takes precedence
over the local and global registries.

## `nix` command line interface

I propose to make flakes the primary way to specify packages in the
`nix` command line interface. Note that the `nix` UI is still marked
as experimental, so we have some freedom to make incompatible
changes. The legacy commands (`nix-build`, `nix-shell`, `nix-env` and
`nix-instantiate`) should not be changed to avoid breakage.

Most `nix` subcommands work on a list of arguments called
"installables" by lack of a better term. For example,

    # nix run nixpkgs:hello dwarffs:dwarffs

takes two flake-based installables. The general form is:

    <flake-ref>:<attr-path>

Examples of installables:

* `nixpkgs:packages.hello`
* `nixpkgs:hello` - short for `nixpkgs:packages.hello`
* `nixpkgs/release-19.03:hello` - overrides the Git branch to use
* `github:NixOS/nixpkgs/4a7047c6e93e8480eb4ca7fd1fd5a2aa457d9082:hello` -
  specifies the exact Git revision to use
* `dwarffs` - short for `dwarffs:defaultPackage`
* `nix:hydraJobs.build.x86_64-darwin`
* `.:hydraJobs.build.x86_64-darwin` - refers to the flake in the
  current directory (which can be a dirty Git tree)
* `.` - short for `.:defaultPackage`

If no argument is given, the default is `.`; thus,

    # nix build

is equivalent to

    # nix build .:defaultPackage

For backwards compatibility, it's possible to use non-flake Nix
expressions using `-f`, e.g. `nix build -f foo.nix foo.bar`.

## Lock files and reproducible evaluation

Dependencies specified in `flake.nix` are typically "unlocked": they
are specified as flake references that don't specify an exact revision
(e.g. `nixpkgs` rather than
`github:NixOS/nixpkgs/4a7047c6e93e8480eb4ca7fd1fd5a2aa457d9082`). To
ensure reproducibility, Nix will automatically generate and use a
*lock file* called `flake.lock` in the flake's directory. The lock
file contains a tree of mappings from the flake references specified
in `flake.nix` to direct flake references that contain revisions.

For example, the inputs
```
inputs =
  [ "nixpkgs"
    github:edolstra/import-cargo
  ];
```
might result in the following lock file:
```
{
    "version": 2,
    "inputs": {
        "github:edolstra/import-cargo": {
            "id": "import-cargo",
            "inputs": {},
            "narHash": "sha256-mxwKMDFOrhjrBQhIWwwm8mmEugyx/oVlvBH1CKxchlw=",
            "uri": "github:edolstra/import-cargo/c33e13881386931038d46a7aca4c9561144d582e"
        },
        "nixpkgs": {
            "id": "nixpkgs",
            "inputs": {},
            "narHash": "sha256-p7UqhvhwS5MZfqUbLbFm+nfG/SMJrgpNXxWpRMFif8c=",
            "uri": "github:NixOS/nixpkgs/4a7047c6e93e8480eb4ca7fd1fd5a2aa457d9082"
        }
    }
}
```

Thus, when we build this flake, the input `nixpkgs` is mapped to
`github:edolstra/import-cargo/c33e13881386931038d46a7aca4c9561144d582e`. Nix
will also check that the content hash of the input is equal to the one
recorded in the lock file. This check is superfluous for Git
repositories (since the commit hash serves a similar purpose), but for
GitHub archives, we cannot directly check that the contents match the
commit hash.

Note that lock files are only used at top-level: the `flake.lock` files
in dependencies (if they exist) are ignored.

Nix automatically creates a `flake.lock` file when you build a local
repository (e.g. `nix build /path/to/repo`). It will also update the
lock file if inputs are added or removed. You can pass
`--recreate-lock-file` to force Nix to recreate the lock file from
scratch (and thus check for the latest version of each input).

Lock files are not sufficient by themselves to ensure reproducible
evaluation. It is also necessary to prevent certain impurities. In
particular, the `nix` command now defaults to evaluating in "pure"
mode, which means that the following are disallowed:

* Access to files outside of the top-level flake, its inputs, or paths
  fetched using `fetchTarball`, `fetchGit` and so on with a commit
  hash or content hash. In particular this means that Nixpkgs will not
  be able to use `~/.config/nixpkgs` anymore.

* Access to the environment. This means that `builtins.getEnv "<var>"`
  always returns an empty string.

* Access to the system type (`builtins.currentSystem`).

* Access to the current time (`builtins.currentTime`).

* Use of the Nix search path (`<...>`); composition must be done
  through flake inputs or `fetchX` builtins.

Pure mode can be disabled by passing `--impure` on the command line.

## Evaluation caching

The fact that evaluation is now hermetic allows `nix` to cache flake
attributes. For example (doing `nix build` on an already present
package):

    $ time nix build nixpkgs:firefox
    real    0m1.497s

    $ time nix build nixpkgs:firefox
    real    0m0.052s

The evaluation cache is kept in `~/.cache/nix/eval-cache-v1.sqlite`,
which has entries like

    INSERT INTO Attributes VALUES(
      X'92a907d4efe933af2a46959b082cdff176aa5bfeb47a98fabd234809a67ab195',
      'packages.firefox',
      1,
      '/nix/store/pbalzf8x19hckr8cwdv62rd6g0lqgc38-firefox-67.0.drv /nix/store/g6q0gx0v6xvdnizp8lrcw7c4gdkzana0-firefox-67.0 out');

where the hash `92a9...` is a fingerprint over the flake store path
and the contents of its lockfile. Because flakes are evaluated in pure
mode, this uniquely identifies the evaluation result.

Currently caching is only done for top-level attributes (e.g. for
`packages.firefox` in the command above). In the future, we could also
add other evaluated values to the cache (e.g. `packages.stdenv`) to
speed up subsequent evaluations of other top-level attributes.

## Flake-related commands

The command `nix flake` has various subcommands for managing
flakes. These are:

* `nix flake list`: Show all flakes in the global and local registry.

* `nix flake add <from-flake-ref> <to-flake-ref>`: Add an entry to the
  local registry. (Recall that this overrides the global registry.)
  For examples,

      # nix flake add nixpkgs github:my-repo/my-nixpkgs

  redirects `nixpkgs` to a different repository. Similarly,

      # nix flake add nixpkgs github:NixOS/nixpkgs/444f22ca892a873f76acd88d5d55bdc24ed08757

  pins `nixpkgs` to a specific revision.

  Note that registries only have an effect on flake references used on
  the command line or when lock files are generated or updated.

* `nix flake remove <flake-ref>`: Remove an entry from the local
  registry.

* `nix flake pin <flake-ref>`: Compute a locked flake reference and
  add it to the local registry. For example:

      # nix flake pin nixpkgs

  will add an mapping like `nixpkgs` ->
  `github:NixOS/nixpkgs/444f22ca892a873f76acd88d5d55bdc24ed08757` to
  the local registry.

* `nix flake init`: Create a skeleton `flake.nix` in the current
  directory.

* `nix flake update`: Recreate the lock file from scratch.

* `nix flake check`: Do some checks on the flake (e.g. check that all
  `packages` are really packages), then build the `checks`
  derivations. For example, `nix flake check patchelf` fetches the
  `patchelf` flake, evaluates it and builds it.

* `nix flake clone`: Do a `git clone` to obtain the source of the
  specified flake, e.g. `nix flake clone dwarffs` will yield a clone
  of the `dwarffs` repository.

## Offline use

Since flakes replace channels, we have to make sure that they support
offline use at least as well. Channels only require network access
when you do `nix-channel --update`. By contrast, the `nix` command
will periodically fetch the latest version of the global registry and
of the top-level flake (e.g. `nix build nixpkgs:hello` may cause it to
fetch a new version of Nixpkgs). To make sure things work offline, we
do the following:

* It's not a failure if we can't fetch the registry.

* It's not a failure if we can't fetch the latest version of a
  flake. (For example, `fetchGit` no longer fails if we already have
  the specified repository and `ref`.)

* Fetched flakes are registered as garbage collector roots, so running
  the garbage collector while on an airplane will not ruin your day.

* There is an option `--no-net` to explicitly prevent updating the
  registry or doing other things that need the network (such as
  substituting). This is the default if there are no configured
  non-loopback network interfaces.

# Drawbacks
[drawbacks]: #drawbacks

Pure evaluation breaks certain workflows. In particular, it breaks the
use of the Nixpkgs configuration file. Similarly, there are people who
rely on `$NIX_PATH` to pass configuration data to NixOps
configurations.

# Alternatives
[alternatives]: #alternatives

For composition of multi-repository projects, the main alternative is
to continue on with explicit `fetchGit` / `fetchTarball` calls to pull
in other repositories. However, since there is no explicit listing of
dependencies, this does not provide automatic updating (i.e. there is
no equivalent of `nix flake update`).

Instead of a `flake.nix`, flakes could store their metadata in a
simpler format such as JSON or TOML. This avoids the Turing tarpit
where getting flake metadata requires the execution of an arbitrarily
complex, possibly non-terminating program.

# Unresolved questions
[unresolved]: #unresolved-questions

* How to handle the system type? Currently `x86_64-linux` is
  hard-coded everywhere.

* How to do Nixpkgs overlays? In principle, overlays would just be a
  kind of flake output.

* More in general, how to handle flake arguments? This must be done in
  a way that maintains hermetic evaluation and evaluation caching.

* What are the criteria for inclusion in the global flake registry?

* Hammer out the details of NixOS/NixOps support for flakes.

* Currently, if flake dependencies (repositories or branches) get
  deleted, rebuilding the flake may fail. (This is similar to
  `fetchurl` referencing a stale URL.) We need a command to gather all
  flake dependencies and copy them somewhere else (possibly vendor
  them into the repository of the calling flake).

# Future work
[future]: #future-work

* The "epoch" feature enables future Nix changes, including language
  changes. For example, changing the parsing of multiline strings
  (https://github.com/NixOS/nix/pull/2490) could be conditional on the
  flake's epoch.

* Currently flake outputs are untyped; we only have some conventions
  about what they should be (e.g. `packages` should be an attribute
  set of derivations). For discoverability, it would be nice if
  outputs were typed. Maybe this could be done via the Nix
  configurations concept
  (https://gist.github.com/edolstra/29ce9d8ea399b703a7023073b0dbc00d).

* Automatically generate documentation from flakes. This partially
  depends on the previous item.

# Acknowledgements

Funding for the development of the flakes prototype was provided by
[Target Corporation](https://www.target.com/).
