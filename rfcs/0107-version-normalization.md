---
feature: nixpkgs_version_normalization
start-date: 2021-09-24
author: Anderson Torres
co-authors:
shepherd-team:
shepherd-leader:
related-issues:
---

# Summary
[summary]: #summary

Normalize the `version` attribute used in Nixpkgs' expresions.

# Motivation
[motivation]: #motivation

Nowadays, the most commonly used format for the `pname` and `version` attributes
along the Nixpkgs' expressions is:

- For stable releases:
  - `pname` reflects the software name;
  - `version` reflects the released version.
- For unstable releases:
  - `pname` reflects the software name;
  - `version` is a string following the format `unstable-YYYY-MM-DD`, where
    `YYYY-MM-DD` denotes the date when the code was released.

This is a simple and easy-to-understand format. Nonetheless, there are some
problems with it.

First, it does not map very well with the Nix function
`builtins.parseDrvName`:

```example
# expected: { name = "mpv"; version = "0.35.15"; }
nix-repl> builtins.parseDrvName "mpv-0.35.15"
builtins.parseDrvName "mpv-0.35.15"
{ name = "mpv"; version = "0.35.15"; }

# expected: { name = "mpv"; version = "unstable-2021-05-03"; }
nix-repl> builtins.parseDrvName "mpv-unstable-2021-05-03"
builtins.parseDrvName "mpv-unstable-2021-05-03"
{ name = "mpv-unstable"; version = "2021-05-03"; }
```

It happens because the `version` attribute in the set returned by
`builtins.parseDrvName` always starts with a digit. It happens by a deliberate
design decision, and as such it should not be regarded as a "bug"; therefore, we
should strive to follow it, neither circumventing nor ignoring it.

Further, the `version` attribute should be crafted to satisfy the expected
upgrading semantics stated in the manual pages, as effectively implemented by
`builtins.compareVersions` -- even when the raw version of the original program
does not meet this expectation.

Besides, Nixpkgs should provide a consistent interface to external package
monitoring services like [Repology](https://repology.org/).

This document describes a format suitable to fix these issues, while keeping it
understandable and striving for simplicity.

# Detailed design
[design]: #detailed-design

## Terminology

_Disclaimer_: whereas some of the terms enumerated below are borrowed from
[pkgsrc guide](https://www.netbsd.org/docs/pkgsrc/) plus a bit of terminology
employed by git, this document aims to be general, not being overly attached to
them.

- Program denotes the piece of software to be fetched and processed via Nixpkgs.
  - This term makes no distinction about the immediate or intended uses of the
    program; it can range from non-interactive programs to full GUI
    applications, even including filesets intended as input to other programs
    (such as firmwares and fonts).
- Team denotes the maintainers of the program.
  - This term makes no distinction among the various models of organization of a
    team; it ranges from a solitary programmer to a business company - and
    everything inbetween.
- Source denotes the origin of the program.
  - This term makes no distinction among precompiled, binary-only or high-level
    code distributions.
- Snapshot denotes the source of the program taken at a point of the time.
  - Labeled snapshot denotes any snapshot explicitly labeled by its team.
  - Unlabeled snapshot denotes any snapshot not explicitly labeled by its team.
- Release denotes any distributed snapshot, as defined by its team.
- Branch denotes a logical sequence of snapshots, as identified by the program's
  team;
  - Usually these branches are denoted by names such as `stable`, `master`,
    `unstable`, `trunk`, `experimental`, `staging`, `X.Y` (where `X` and
    `Y` are numbers) etc.

## Design

- For a labeled snapshot:
  - `version` should be constituted of the version of the snapshot, as defined
    by the program team, without any alphabetical characters (e.g. "v", "rel")
    prepending it.
    - Alphabetical characters following the first numerical character of version
      (as defined above) should be maintained, except optionally those clearly
      used as separators, in which case they are replaced by dots (emulating a
      typical dot-separated version).

- For an unlabeled snapshot:
  - `version` should be constituted of a concatenation of the elements below in
    this order:
      - the version of the latest previous labeled snapshot (on the same branch,
        when applicable), according to the rules defined before for labeled
        snapshots;
        - If the project never released a labeled snapshot, `0.pre` should be
          used as default.
     - the string `+date=YYYY-MM-DD`, where `YYYY-MM-DD` denotes the date
       the mentioned unlabeled snapshot was distributed.

- Some atypical programs have special considerations:
  - Linux kernel modules:
    - Besides the rules established above for typical snapshots (whether labeled
      or unlabeled), `version` shoud have appended `+linux=XX.XX.XX`, where
      `XX.XX.XX` is the corresponding Linux kernel version used to build the
      aforementioned module.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

Some useful examples:

- Bochs is a typical Sourceforge-hosted project; its labeled snapshots can be
  fetched from tarballs obtained via URLs like
  <https://sourceforge.net/projects/bochs/files/bochs/2.6.11/>

  For this example, we have `pname = "bochs"; version = "2.6.11";`.

- MPV is a typical Github-hosted program; its labeled snapshots can be fetched
  from tarballs obtained via URLs like
  <https://github.com/mpv-player/mpv/releases/tag/v0.33.1>.

  For this example, we get rid of the `"v"` prepended to the version tag: `pname
  = "mpv"; version = "0.33.1";`.

- SDL2 is hosted on Github; its latest labeled version can be downloaded from
  <https://github.com/libsdl-org/SDL/releases/tag/release-2.0.14>. Therefore we
  have `pname = "SDL2"; version = "2.0.14";`.

  _However_, this labeled version was released December 21, 2020, while the
  latest change was done in May 28, 2021.

  Therefore, for this particular unlabeled releases of SDL2, we have `pname =
  "SDL2"; version = "2.0.14+date=2021-05-28";`.

- Cardboard is a typical Gitlab-hosted program. It has no labeled release yet,
  therefore we use `0.pre` as default dummy stable version; further, the latest
  commit was made on May 10, 2021.

  Therefore, for this particular commit have `pname = "cardboard"; version =
  "0.pre+date=2021-05-21";`.

- Python is a famous programming language and interpreter. Before the
  deprecation of its 2.x series in 2020, Python had two release branches,
  popularly known as 'Python 2' and 'Python 3'. Indeed this peculiar situation
  reflected in many package management teams, especially Nixpkgs, that employed
  `python2` and `python3` as `pname`s for these particular programs.

  As an exercise of imagination, suppose the scenarios described below:

  Python 2.6 was released 2008-10-01; an unlabeled snapshot of Python 2 branch
  released at 2008-12-04 would have `version="2.6+date=2008-12-04"`.

  At the same time, Python 3.0 was released 2008-12-03; an unlabeled snapshot of
  Python 3 branch released at 2008-12-04 would have
  `version="3.0+date=2008-12-04"`.

- The Linux drivers for Realtek rtl8192eu can be fetched from a Github page,
  <https://github.com/Mange/rtl8192eu-linux-driver>. It has no labeled release;
  the latest code is from May 12, 2021. Supposing e.g. it was built for Linux
  kernel version 5.10.01, we therefore have `pname = "rtl8192eu"; version =
  "0.pre+date=2021-05-12+linux=5.10.01";`.

# Drawbacks
[drawbacks]: #drawbacks

The main drawback is the conversion of the already existent expressions which
does not follow the format proposed here, possibly requiring manual intervention
and code review, especially for machine-generated expressions (such as Lua,
Emacs Lisp or Node library sets).
  
Nonetheless, this task is easily sprintable, can be done incrementally, and is
amenable to automation.

# Alternatives
[alternatives]: #alternatives

The alternative is doing nothing. The impact of it is keeping the Nixpkgs
codebase incompatible with `builtins.parseDrvName` and
`builtins.compareVersions`, confusing, inconsistent and discoverable.

# Unresolved questions
[unresolved]: #unresolved-questions

- Allow some degree of freedom and extensibility for handling deviations, such
  different, non-standard naming schemes or unusual releasing schedules
  eventually employed by many teams.

  - Regarding this, discuss about making `version` a data structure or abstract
    datatype.

- Interactions between `pname` and `version`, like multi-branch releases and
  configuration options.

- Legacy issues and integration with future implementations of Nix and Nixpkgs,
  epecially the Flakes framework.

- Integration and interfacing with package databases like Repology.

# Future work
[future]: #future-work

- Update expressions that do not follow this proposal.

- Update manuals and related documentation in order to reflect this proposal for
  future expressions.
