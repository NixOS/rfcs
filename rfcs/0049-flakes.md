---
feature: flakes
start-date: 2019-07-09
author: Eelco Dolstra
co-authors: TBD
shepherd-team: Domen Kožar, Alyssa Ross, Shea Levy, John Ericson
shepherd-leader: Domen Kožar
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

This RFC proposes a mechanism to package Nix expressions into
composable entities called "flakes". Flakes allow hermetic,
reproducible evaluation of multi-repository Nix projects; impose a
discoverable, standard structure on Nix projects; and replace previous
mechanisms such as Nix channels and the Nix search path.

# Motivation
[motivation]: #motivation

Flakes are motivated by a number of serious shortcomings in Nix:

* While Nix pioneered reproducible builds, sadly, Nix expressions are
  not nearly as reproducible as Nix builds. Nix expressions can access
  arbitrary files (such as `~/.config/nixpkgs/config.nix`),
  environment variables, and Git repositories. This means for instance
  that it is hard to ensure reproducible evaluation of NixOS or NixOps
  configurations.

* Nix projects lack discoverability and a standard structure. For
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

The flakes mechanism seeks to address all these problems. This RFC,
however, only describes the format and semantics of flakes; it doesn't
describe changes to the `nix` command to support flakes.

# Detailed design
[design]: #detailed-design

## Flakes

A flake is a directory that contains a file named `flake.nix` in the
root directory. `flake.nix` specifies some metadata about the flake
such as dependencies (called *inputs*), as well as its *outputs* (the
Nix values such as packages or NixOS modules provided by the flake).

As an example, below is the `flake.nix` of
[`dwarffs`](https://github.com/edolstra/dwarffs) (a FUSE filesystem
for automatically fetching DWARF debug symbols by ELF build ID). It
depends on the Nixpkgs flake and provides a package (i.e. an
installable derivation) and a NixOS module.

```
{
  edition = 201911;

  description = "A filesystem that fetches DWARF debug info from the Internet on demand";

  outputs = { self, nixpkgs }: rec {
    packages.x86_64-linux.dwarffs =
      with nixpkgs.packages.x86_64-linux;
      with nixpkgs.builders;
      with nixpkgs.lib;

      stdenv.mkDerivation {
        name = "dwarffs-0.1.${substring 0 8 self.lastModified}";

        buildInputs = [ fuse nix nlohmann_json boost ];

        NIX_CFLAGS_COMPILE = "-I ${nix.dev}/include/nix -include ${nix.dev}/include/nix/config.h -D_FILE_OFFSET_BITS=64";

        src = self;

        installPhase =
          ''
            mkdir -p $out/bin $out/lib/systemd/system

            cp dwarffs $out/bin/
            ln -s dwarffs $out/bin/mount.fuse.dwarffs

            cp ${./run-dwarffs.mount} $out/lib/systemd/system/run-dwarffs.mount
            cp ${./run-dwarffs.automount} $out/lib/systemd/system/run-dwarffs.automount
          '';
      };

    nixosModules.dwarffs = ...;

    defaultPackage.x86_64-linux = packages.x86_64-linux.dwarffs;

    checks.build = packages.x86_64-linux.dwarffs;
  };
}
```

A flake has the following attributes:

* `edition`: A number that specifies the version of the flake
  syntax/semantics to be used. This allows the interpretation of
  flakes to change in the future. It also enables some evolution of
  the Nix language; for example, the Nix files in the flake could be
  parsed using a syntax determined by the edition. The only currently
  allowed value is `201911`. Nix rejects flakes with an unsupported
  edition.

* `description`: A short description of the flake.

* `inputs`: An attrset specifying the dependencies of the flake
  (described below).

* `outputs`: A function that, given an attribute set containing the
  outputs of each of the input flakes keyed by their identifier,
  yields the Nix values provided by this flake. Thus, in the example
  above, `inputs.nixpkgs` contains the result of the call to the
  `outputs` function of the `nixpkgs` flake, and
  `inputs.nixpkgs.packages.fuse` refers to the `packages.fuse` output
  attribute of `nixpkgs`.

  In addition to the outputs of each input, each input in `inputs`
  also contains some metadata about the inputs. These are:

  * `outPath`: The path in the Nix store of the flake's source
    tree. This means that you could import Nixpkgs in a more
    legacy-ish way by writing

        with import inputs.nixpkgs { system = "x86_64-linux"; };

    since `nixpkgs` still contains a `/default.nix`. In this case we
    bypass its outputs entirely and only use the flake mechanism to
    get its source tree.

  * `rev`: The commit hash of the flake's repository, if applicable.

  * `revCount`: The number of ancestors of the revision `rev`. This is
    not available for `github` repositories (see below), since they're
    fetched as tarballs rather than as Git repositories.

  * `lastModified`: The commit time of the revision `rev`, in the
    format `%Y%m%d%H%M%S` (e.g. `20181231100934`). Unlike `revCount`,
    this is available for both Git and GitHub repositories, so it's
    useful for generating (hopefully) monotonically increasing version
    strings.

  * `narHash`: The SHA-256 (in SRI format) of the NAR serialization of
    the flake's source tree.

  The value returned by the `outputs` function must be an attribute
  set. The attributes can have arbitrary values; however, some tools
  may require specific attributes to have a specific value (e.g. the
  `nix` command may expect the value of `packages.x86_64-linux` to be
  an attribute set of derivations built for the `x86_64-linux`
  platform).

## Flake inputs

The attribute `inputs` specifies the dependencies of a flake. These
specify the location of the dependency, or a symbolic flake identifier
that is looked up in a registry or in a command-line flag. For
example, the following specifies a dependency on the Nixpkgs and Hydra
repositories:

    # A GitHub repository.
    inputs.import-cargo = {
      type = "github";
      owner = "edolstra";
      repo = "import-cargo";
    };

    # An indirection through the flake registry.
    inputs.nixpkgs.id = "nixpkgs";

Each input is fetched, evaluated and passed to the `outputs` function
as a set of attributes with the same name as the corresponding
input. The special input named `self` refers to the outputs and source
tree of *this* flake. Thus, a typical `outputs` function looks like
this:

    outputs = { self, nixpkgs, import-cargo }: {
      ... outputs ...
    };

It is also possible to omit inputs entirely and *only* list them as
expected function arguments in `outputs`. Thus,

    outputs = { self, nixpkgs }: ...;

without an `inputs.nixpkgs` attribute will simply look up `nixpkgs` in
the flake registry.

Repositories that don't contain a `flake.nix` can also be used as
inputs, by setting the input's `flake` attribute to `false`:

    inputs.grcov = {
      type = "github";
      owner = "mozilla";
      repo = "grcov";
      flake = false;
    };

    outputs = { self, nixpkgs, grcov }: {
      packages.x86_64-linux.grcov = stdenv.mkDerivation {
        src = grcov;
        ...
      };
    };

The following input types are specified at present:

* `git`: A Git repository or dirty local working tree.

* `github`: A more efficient scheme to fetch repositories from GitHub
  as tarballs. These have slightly different semantics from `git`
  (in particular, the `revCount` attribute is not available).

* `tarball`: A `.tar.{gz,xz,bz2}` file.

* `path`: A directory in the file system. This generally should be
  avoided in favor of `git` inputs, since `path` inputs have no
  concept of revisions (only a content hash) or tracked files
  (anything in the source directory is copied).

* `hg`: A Mercurial repository.

Transivitive inputs can be overriden from a `flake.nix` file. For
example, the following overrides the `nixpkgs` input of the `nixops`
input:

    inputs.nixops.inputs.nixpkgs = {
      type = "github";
      owner = "my-org";
      repo = "nixpkgs";
    };

It is also possible to "inherit" an input from another input. This is
useful to minimize flake dependencies. For example, the following sets
the `nixpkgs` input of the top-level flake to be equal to the
`nixpkgs` input of the `dwarffs` input of the top-level flake:

    inputs.nixops.follows = "dwarffs/nixpkgs";

The value of the `follows` attribute is a `/`-separated sequence of
input names denoting the path of inputs to be followed from the root
flake.

Overrides and `follows` can be combined, e.g.

    inputs.nixops.inputs.nixpkgs.follows = "dwarffs/nixpkgs";

sets the `nixpkgs` input of `nixops` to be the same as the `nixpkgs`
input of `dwarffs`. It is worth noting, however, that it is generally
not useful to eliminate transitive `nixpkgs` flake inputs in this
way. Most flakes provide their functionality through Nixpkgs overlays
or NixOS modules, which are composed into the top-level flake's
`nixpkgs` input; so their own `nixpkgs` input is usually irrelevant.

## Lock files

Inputs specified in `flake.nix` are typically "unlocked" in that they
don't specify an exact revision. To ensure reproducibility, Nix will
automatically generate and use a *lock file* called `flake.lock` in
the flake's directory. The lock file contains a graph structure
isomorphic to the graph of dependencies of the root flake. Each node
in the graph (except the root node) maps the (usually) unlocked input
specifications in `flake.nix` to locked input specifications. Each
node also contains some metadata, such as the dependencies (outgoing
edges) of the node.

For example, if `flake.nix` has the inputs in the example above, then
the resulting lock file might be:
```
{
  "version": 5,
  "root": "n1",
  "nodes": {
    "n1": {
      "inputs": {
        "nixpkgs": "n2",
        "import-cargo": "n3",
        "grcov": "n4"
      }
    },
    "n2": {
      "info": {
        "lastModified": 1580555482,
        "narHash": "sha256-OnpEWzNxF/AU4KlqBXM2s5PWvfI5/BS6xQrPvkF5tO8="
      },
      "inputs": {},
      "locked": {
        "owner": "edolstra",
        "repo": "nixpkgs",
        "rev": "7f8d4b088e2df7fdb6b513bc2d6941f1d422a013",
        "type": "github"
      },
      "original": {
        "id": "nixpkgs",
        "type": "indirect"
      }
    },
    "n3": {
      "info": {
        "lastModified": 1567183309,
        "narHash": "sha256-wIXWOpX9rRjK5NDsL6WzuuBJl2R0kUCnlpZUrASykSc="
      },
      "inputs": {},
      "locked": {
        "owner": "edolstra",
        "repo": "import-cargo",
        "rev": "8abf7b3a8cbe1c8a885391f826357a74d382a422",
        "type": "github"
      },
      "original": {
        "owner": "edolstra",
        "repo": "import-cargo",
        "type": "github"
      }
    },
    "n4": {
      "info": {
        "lastModified": 1580729070,
        "narHash": "sha256-235uMxYlHxJ5y92EXZWAYEsEb6mm+b069GAd+BOIOxI="
      },
      "inputs": {},
      "locked": {
        "owner": "mozilla",
        "repo": "grcov",
        "rev": "989a84bb29e95e392589c4e73c29189fd69a1d4e",
        "type": "github"
      },
      "original": {
        "owner": "mozilla",
        "repo": "grcov",
        "type": "github"
      },
      "flake": false
    }
  }
}
```

This graph has 4 nodes: the root flake, and its 3 dependencies. The
nodes have arbitrary labels (e.g. `n1`). The label of the root node of
the graph is specified by the `root` attribute. Nodes contain the
following fields:

* `info`: Metadata about the source tree. This always includes
  `narHash`. It also includes input type-specific attributes such as
  the `lastModified` or `revCount`. The main reason for these
  attributes is to allow flake inputs to be substituted from a binary
  cache: `narHash` allows the store path to be computed, while the
  other attributes are necessary because they provide information not
  stored in the store path.

* `inputs`: The dependencies of this node, as a mapping from input
  names (e.g. `nixpkgs`) to node labels (e.g. `n2`).

* `original`: The original input specification from `flake.lock`, as a
  set of `builtins.fetchTree` arguments.

* `locked`: The locked input specification, as a set of
  `builtins.fetchTree` arguments. Thus, in the example above, when we
  build this flake, the input `nixpkgs` is mapped to revision
  `7f8d4b088e2df7fdb6b513bc2d6941f1d422a013` of the `edolstra/nixpkgs`
  repository on GitHub.

* `flake`: A Boolean denoting whether this is a flake or non-flake
  dependency. Corresponds to the `flake` attribute in the `inputs`
  attribute in `flake.nix`.

The `info`, `original` and `locked` attributes are omitted for the
root node. This is because we cannot record the commit hash or content
hash of the root flake, since modifying `flake.lock` will invalidate
these.

The graph representation of lock files allows circular dependencies
between flakes. For example, here are two flakes that reference each
other:
```
{
  edition = 201909;
  inputs.b = ... location of flake B ...;
  # Tell the 'b' flake not to fetch 'a' again, to ensure its 'a' is
  # *this* 'a'.
  inputs.b.inputs.a.follows = "";
  outputs = { self, b }: {
    foo = 123 + b.bar;
    xyzzy = 1000;
  };
}
```
and
```
{
  edition = 201909;
  inputs.a = ... location of flake A ...;
  inputs.a.inputs.b.follows = "";
  outputs = { self, a }: {
    bar = 456 + a.xyzzy;
  };
}
```

Lock files transitively lock direct as well as indirect
dependencies. That is, if a lock file exists and is up to date, Nix
will not look at the lock files of dependencies. However, lock file
generation itself *does* use the lock files of dependencies by
default.

## Reproducible evaluation

Lock files are not sufficient by themselves to ensure reproducible
evaluation. We also need to disallow certain impurities that the Nix
language previously allowed. In particular, the following are
disallowed in a flake:

* Access to files outside of the top-level flake or its inputs, as
  well as paths fetched using `fetchTarball`, `fetchGit` and so on
  without a commit hash or content hash. In particular this means that
  Nixpkgs will not be able to use `~/.config/nixpkgs` anymore.

* Access to the environment. This means that `builtins.getEnv "<var>"`
  always returns an empty string.

* Access to the system type (`builtins.currentSystem`).

* Access to the current time (`builtins.currentTime`).

* Use of the Nix search path (`<...>`); composition must be done
  through flake inputs or `fetchX` builtins.

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
dependencies, this does not provide automatic updating.

Instead of a `flake.nix`, flakes could store their metadata in a
simpler format such as JSON or TOML. This avoids the Turing tarpit
where getting flake metadata requires the execution of an arbitrarily
complex, possibly non-terminating program.

Flakes could be implemented as an external tool on top of Nix. Indeed,
there is nothing that flakes allow you to do that couldn't previously
be done using `fetchGit`, the `--pure-eval` flag and some shell
scripting. However, implementing flake-like functionality in an
external tool would defeat the goals of this RFC. First, it probably
wouldn't lead to a standard way to structure and compose Nix projects,
since we might well end up with numerous competing
"standards". Second, it would degrade rather than improve the Nix UX,
since users would now have to deal with Nix *and* the flake-like tool
on top of it.

# Unresolved questions
[unresolved]: #unresolved-questions

* Should flakes have arguments (like "system type")? This must be done
  in a way that maintains hermetic evaluation and evaluation caching.

* Currently, if flake dependencies (repositories or branches) get
  deleted upstream, rebuilding the flake may fail. (This is similar to
  `fetchurl` referencing a stale URL.) We need a command to gather all
  flake dependencies and copy them somewhere else (possibly vendor
  them into the repository of the calling flake).

* Maybe flake metadata should be stored in a `flake.json` or
  `flake.toml` file. This would prevent ambiguities when the Nix
  language changes in a future edition.

# Future work
[future]: #future-work

* The "edition" feature enables future Nix changes, including language
  changes. For example, changing the parsing of multiline strings
  (https://github.com/NixOS/nix/pull/2490) could be conditional on the
  flake's edition.

* Currently flake outputs are untyped; we only have some conventions
  about what they should be (e.g. `packages` should be an attribute
  set of derivations). For discoverability, it would be nice if
  outputs were typed. Maybe this could be done via the Nix
  configurations concept
  (https://gist.github.com/edolstra/29ce9d8ea399b703a7023073b0dbc00d).

# Acknowledgments

Funding for the development of the flakes prototype was provided by
[Target Corporation](https://www.target.com/). The flakes project was
inspired/motivated by [Shea Levy's work on
`require.nix`](https://www.youtube.com/watch?v=DHOLjsyXPtM) and
ensuing discussions at NixCon 2018.
