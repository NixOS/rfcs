---
feature: Decouple filesystem from categorization
start-date: 2023-04-23
author: Anderson Torres
co-authors:
shepherd-team: @7c6f434c @natsukium @fgaz @infinisil
shepherd-leader: @7c6f434c
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
         3, anyone?).

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

In a `nix repl`:

```
nix-repl> :l <nixpkgs>
Added XXXXXX variables.

nix-repl> pkgs.bochs.meta.categories
[ { ... } ]

nix-repl> map (z: z.name) pkgs.bochs.meta.categories
[ "debugger" "emulator" ]
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

3. Superfluous

   It can be argued that there are other ways to discover similar or related
   package sets, like Repology.

   However, this argument is a bit circular, because e.g. the classification
   shown by Repology effectively replicates the classification done by the many
   software collections in its catalog. Therefore, relying in Repology merely
   transfers the question to external sources.

   Further it becomes more pronounced when we take into account the fact Nixpkgs
   is top 1 of most Repology statistics. The expected outcome, therefore, should
   be precisely the opposite: Nixpkgs being _the_ source of structured metainfo
   for other software collections.

# Alternatives
[alternatives]: #alternatives

1. Do nothing

   This will exacerbate the problems already listed.

2. Ignore/nuke the categorization completely

   This is an alternative worthy of some consideration. After all,
   categorization is not without its problems, as shown above. Removing or
   ignoring classification removes all problems.

   However, there are good reasons to keep the categorization:

   - The complete removal of categorization is too harsh. A solution that keeps
     and enhances the categorization is way more preferrable than one that nukes
     it completely.

   - As said before, the categorization is already present; this RFC proposes to
     expose it to a higher level, in a structured, more discoverable format.

   - Categorization is very traditional among software collections. Many of them
     are doing this just fine for years on end, and Nixpkgs can imitate them
     easily - and even surpass them, given the benefits of Nix language
     machinery.

   - Categorization is useful in many scenarios and use cases - indeed they
     are ubiquitous in software world:
     - specialized search engines (from Repology to MELPA)
     - code forges, from Sourceforge to Gitlab
     - as said above, software collections from pkgsrc to slackbuilds
     - organization and preservation (as Software Heritage)

# Prior art
[prior-art]: #prior-art

As said above, categorization is very traditional among software collections. It
is not hard to cite examples in this arena; the most interesting ones I have
found are listed below (linked at [references section](#references)):

- FreeBSD Ports;
- Debtags;
- Appstream Project;

# Unresolved questions
[unresolved]: #unresolved-questions

Still unsolved is what data structure is better suited to represent a category.

- For now we stick to a set `{ name, description }`.

# Future work
[future]: #future-work

## Categorization Team
[categorization-team]: #categorization-team

Given the typical complexities that arise from categorization, and expecting
that regular maintainers are not expected to understand its minuteness
(according to the experience from [Debtags
Team](https://wiki.debian.org/Debtags/FAQ#Why_don.27t_you_just_ask_the_maintainers_to_tag_their_own_packages.3F)),
it is strongly recommended the creation of a team entrusted to manage issues
related to categorization, including but not limited to:

- Update documentation.
- Curate the categories.
- Update Continuous Integration.
- Integrate categorization over the current codebase.

Such a team should receive authority to carry out their duties:

- Coordinaton of efforts to import, integrate and update categorization of
  packages.
- Disputations over categorization, especially corner cases.
- Decisions about when a Continuous Integration check for categorisation is
  ready to be developed with gray/neutral failure statuses, and when a CI check
  with a good track record in gray mode can be upgraded to red/blocking
  failures.

# References
[references]: #references

- [Desktop Menu
  Specification](https://specifications.freedesktop.org/menu-spec/latest/);
  specifically,
  - [Main
    categories](https://specifications.freedesktop.org/menu-spec/latest/apa.html)
  - [Additional
    categories](https://specifications.freedesktop.org/menu-spec/latest/apas02.html)
  - [Reserved
    categories](https://specifications.freedesktop.org/menu-spec/latest/apas03.html)

- [Appstream](https://www.freedesktop.org/wiki/Distributions/AppStream/)

- [Debtags](https://wiki.debian.org/Debtags)

  - [Debtags FAQ](https://wiki.debian.org/Debtags/FAQ)

- [NetBSD pkgsrc guide](https://www.netbsd.org/docs/pkgsrc/)
  - Especially, [Chapter 12, Section
    1](https://www.netbsd.org/docs/pkgsrc/components.html#components.Makefile)
    contains a short list of CATEGORIES.

- [FreeBSD Porters
  Handbook](https://docs.freebsd.org/en/books/porters-handbook/)
  - Especially
    [Categories](https://docs.freebsd.org/en/books/porters-handbook/makefiles/#porting-categories)
