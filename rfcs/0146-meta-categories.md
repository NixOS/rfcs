---
feature: Decouple filesystem from categorization
start-date: 2023-04-23
author: Anderson Torres
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Deploy a new method of categorization for the packages maintained by Nixpkgs,
not relying on filesystem idiosyncrasies.

# Motivation
[motivation]: #motivation

Currently, Nixpkgs uses the filesystem, or more accurately, the directory tree
layout in order to informally categorize the softwares it packages, as described
in the [Hierarchy](https://nixos.org/manual/nixpkgs/stable/#sec-hierarchy)
section of Nixpkgs manual.

This is a simple, easy to understand and consecrated-by-use method of
categorization, partially employed by many other package managers like GNU Guix
and NetBSD pkgsrc.

However this system of categorization has serious problems:

1. It is bounded by the constraints imposed by the filesystem.

   - Restrictions on filenames, subdirectory tree depth, permissions, inodes,
     quotas, and many other things.
     - Some of these restrictions are not well documented and are found simply
       by "bumping" on them.
     - The restrictions can vary on an implementation basis.
       - Some filesystems have more restrictions or less features than others,
         forcing an uncomfortable lowest common denominator.
       - Some operating systems can impose additional constraints over otherwise
         full-featured filesystems because of backwards compatibility (8 dot
         3,anyone?).

2. It requires a local checkout of the tree.

   Certainly this checkout can be "cached" using some form of `find . >
   /tmp/pkgs-listing.txt`, or more sophisticated solutions like `locate +
   updatedb`. Nonetheless such solutions still require access to a fresh,
   updated copy of the Nixpkgs tree.

3. The creation of a new category - and more generally the manipulation of
   categories - requires an unpleaseant task of renaming and eventually patching
   many seemingly unrelated files.

   - Moving files around Nixpkgs codebase requires updating their forward and
     backward references.
     - Especially in some auxiliary tools like editor plugins, testing suites,
       autoupdate scripts and so on.
   - Rewriting `all-packages.nix` can be error-prone (even using Metapad) and it
     can generate huge, noisy patches.

4. There is no convenient way to use multivalued categorization.

   A piece of software can fulfill many categories; e.g.
   - an educational game
   - a console emulator (vs. a PC emulator)
   - and a special-purpose programming language (say, a smart-contracts one).

   The current one-size-fits-all restriction is artificial, imposes unreasonable
   limitations and results in incomplete and confusing information.

   - No, symlinks or hardlinks are not convenient for this purpose; not all
     environments support them (falling on the "less features than others"
     problem expressed before) and they convey nothing besides confusion - just
     think about writing the corresponding entry in `all-packages.nix`.

5. It puts over the (possibly human) package writer the mental load of where to
   put the files on the filesystem hierarchy, deviating them from the job of
   really writing them.

   - Or just taking the shortest path and throw it on a folder under `misc`.

6. It "locks" the filesystem, preventing its usage for other, more sensible
   purposes.

7. The most important: the categorization is not discoverable via Nix language
   infrastructure.

   Indeed there is no higher level way to query about such categories besides
   the one described in the bullet 2 above.

In light of such a bunch of problems, this RFC proposes a novel alternative to
the above mess: new `meta` attributes.

# Detailed design
[design]: #detailed-design

A new attribute, `meta.categories`, will be included for every Nix expression
living inside Nixpkgs.

This attribute will be a list, whose elements are one of the possible elements
of the `lib.categories` set.

A typical snippet of `lib.categories` will be similar to:

```nix
{
  assembler = {
    name = "Assembler";
    description = ''
      A program that converts text written in assembly language to binary code.
    '';
  };

  compiler = {
    name = "Compiler";
    description = ''
      A program that converts a source from a language to another, usually from
      a higher, human-readable level to a lower, machine level.
    '';
  };

  font = {
    name = "Font";
    description = ''
      A set of files that defines a set of graphically-related glyphs.
    '';
  };

  game = {
    name = "Game";
    description = ''
      A program developed with entertainment in mind.
    '';
  };

  interpreter = {
    name = "Interpreter";
    description = ''
      A program that directly executes instructions written in a programming
      language, without requiring compilation into the native machine language.
    '';
  };

```

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

In file bochs/default.nix:

```nix
stdenv.mkDerivation {

. . .

  meta = {
    . . .
    categories = with lib.categories; [ emulator debugger ];
    . . .
    };
  };
}

```

# Drawbacks
[drawbacks]: #drawbacks

The most immediate drawbacks are:

1. A huge treewide edit of Nixpkgs

   On the other hand, this is easily sprintable and amenable to automation.

2. Bikeshedding

   How many and which categories we should create? Can we expand them later?

   For start, we can follow/take inspiration from many of the already existing
   categories sets and add extra ones when the needs arise. Indeed, it is way
   easier to create such categories using Nix language when compared to other
   software collections.

# Alternatives
[alternatives]: #alternatives

1. Do nothing

   This will exacerbate the problems already listed.

2. Ignore/nuke the categorization completely

   This is not an idea as bad as it appear. After all, categorization has a
   non-negligible propensity to bikeshedding. Removing it removes all problems.
   
   Nonetheless, other good software collections do this just fine, and we can
   easily imitate them. Indeed, we can follow/take a peek at how Repology keeps
   the categorizations defined by those software collections.

# Unresolved questions
[unresolved]: #unresolved-questions

Still unsolved is what data structure is better suited to represent a category.

# Future work
[future]: #future-work

- Curation of categories.
- Update documentation.
