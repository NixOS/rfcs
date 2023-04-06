---
feature: nix_formatting
start-date: 2021-08-17
author: Raphael Megzari
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: 0x4A6F, Silvan Mosberger (infinisil), piegames, Thomas Bereknyei (tomberek)
shepherd-leader: Silvan Mosberger (infinisil)
related-issues: (will contain links to implementation PRs)
---

# Summary

[summary]: #summary

Decide on basic Nix style guidelines and pick a default code formatter for Nix code. 
Format Nixpkgs using that formatter and enforce it using CI.

## Motivation

[motivation]: #motivation

TODO: Currently, there is no authoritative style guide for Nix code in Nixpkgs.
The currenty style has evolved organically over time, leading to inconsistencies both across files and language features.

- We want to prevent debate around how things should be formatted.
- We want to make it as easy as possible for contributors (especially new ones) to make changes without having to worry about formatting.
- Conversely, reviewers should not be bothered with ill-formatted contributions.
- We want a unified Nix code style that's consistent with itself, easily readable, accessible and results in readable diffs.

## Detailed design

[design]: #detailed-design

There are four main parts to this RFC:
- Establish basic formatting guidelines
- Pick a formatter implementation
- Migrate Nixpkgs to the format and enforce it in CI
- Create a process for maintenance of the implementation

### Nix formatting style

We introduce a set of general *guidelines* that describe the Nix formatting style (**Appendix A**).

From these style guidelines, a set of more specific formatting rules is derived (**Appendix B**).

The interactions between different language features are complex and producing a style that matches the expectations involves a lot of special cases. Edge cases abound.
Any attempt at creating an exhaustive rule set would be futile.
Therefore, the formatting rules are intentionally under-specified, leaving room for the formatter implementation.
However, the most important or potentially controversial rules are included.
The test suite of the formatter implementation specifies the exact formatting, it is up to the formatter team to adjust it as needed.
TODO?: While the style guidelines are fixed in this RFC, the formatting rules will be documented at TODO and maintained by the formatter team (see below).

### Formatter tooling

In order to pick a formatter, we looked at the following criteria:

- Output: Capability of matching the desired output style
- Maintainability: The code base needs to be updated over time
  - The language the formatter is written in matters
  - The quality of the codebase
  - The libraries the formatter depends on and their maintaindness
  - Maintainability is more important than current maintenance situation, since this is a very long-term project TODO
- Tests: The code should be tested well
- Approach:

In contrast, these are not criteria:

- Diff size when applied to current Nixpkgs: As noted in the formatting recommendations, the desired output does take into account existing Nixpkgs idioms and preferred format, but the size of the treewide change is not significant
- Current usage metrics / Popularity
- Performance: Beyond a certain threshold optimizing for this will detract from other criteria.

We looked at all the potential formatter tools and evaluated these criteria to our best knowledge:

| Formatter | [alejandra](https://github.com/kamadorueda/alejandra) | [nixfmt](https://github.com/serokell/nixfmt) | [nixpkgs-fmt](https://github.com/nix-community/nixpkgs-fmt) |
| --- | --- | --- | --- |
| Output                         | ✅ | ✅ | ⚠️[^outputs] |
| Maintainability (language)     | ✅(Rust) | ⚠️(Haskell)[^haskell] | ✅(Rust) |
| Maintainability (code quality) | ⚠️  | ✅ | ⚠️ |
| Maintainability (dependencies) | ✅ (rnix)   | ❌[^internal] | ✅(rnix) |
| Test suite                     | ✅ | ❌ | ✅ |
| Approach[^transformation] | ✅ | ✅ | ❌[^transformation] |
| --- | --- | --- | --- |
| Nixpkgs test run | [#157382](https://github.com/NixOS/nixpkgs/pull/157382) | [#147608](https://github.com/NixOS/nixpkgs/pull/147608) | [#147623](https://github.com/NixOS/nixpkgs/pull/147623) |

From this evaluation, we decide that the code base of alejandra will be used as the base.

[^outputs]: formatting inside of anti-quotation
[^transformation]: Nixpkgs-fmt has the unique approach of applying modification rules to the Nix code, instead of parsing and pretty-printing it like most others. (See their README for details.) TODO something about maintainability
[^internal]: nixfmt ships with its own parser
[^haskell]: the Nix ecosystem is showing interest and signs of adopting Rust tooling; Nix bindings, Nickel, parsers, formatters, lsp, etc.

### Formatting Nixpkgs

Once the tooling fully conforms to the style guide, Nixpkgs will be fully reformatted. The output of the chosen formatter will be authoritative for Nixpkgs.

The Nix Formatter Team is responsible for the migration of Nixpkgs, and will do so in close coordination with the release managers.

CI will enforce the formatting on every pull request. The formatting hook will pin a version of the formatter for reproducibility, which is independent from the one provided by Nixpkgs. In order to minimize conflicts, the format used for Nixpkgs may only be updated shortly before release branch-off, at which point old pull requests will need to be rebased.

In order to not clutter the history, formatting will be done all at once and the respective commit will be added to `.git-blame-ignore-revs`. In order to not cause any conflicts with back-porting, this will have to be done shortly before a release branch-off. Merge conflicts are unavoidable for most open pull requests.

#### Staging

Coordinate with release managers to merge the formatting PR in between two staging runs to avoid conflicts there.

Other long-running branches (haskell, python, etc.) will not be considered, there will however be an announcement so that contributors can coordinate to not have any of these branches in use at that time either.

In case a separate branch can't be merged into master again due to a formatting conflict, `git filter-branch` and a `git rebase` can still be used to resolve it without trouble.

### Maintenance

To help maintaining the formatter, a team is created.
It is given commit access the formatter repository living in the NixOS GitHub organization and has the authority to change the formatting rules.
It is bound to the style guide and rules specified in this RFC.

Should new syntax features be introduced into Nix, the formatter team should be consulted prior to their introduction.

The team initially consists of:
- @infinisil
- @tomberek
- @piegames
- @0x4A6F
- @kamadorueda (if available, TODO: @tomberek sent a message)

The team has the authority to remove and add members as needed.

## Examples and Interactions

[examples-and-interactions]: #examples-and-interactions

### Documentation

Update [Section 20.1 (Coding conventiones → Syntax)](https://nixos.org/manual/nixpkgs/stable/#sec-syntax) of the Nixpkgs manual. All formatting-specific guidance is removed and replaced with instructions on how to automatically format Nixpkgs instead.

### Automatically generated files

TODO discuss that https://github.com/NixOS/rfcs/pull/101#discussion_r690272696
- exclude option in tooling
- 2nix apply fomatting style

## Drawbacks

[drawbacks]: #drawbacks

- Having a commit that changes the formatting, can make git blame harder to use. It will need `--ignore-rev` flag.
- Every formatter will have bugs.

## Alternatives

[alternatives]: #alternatives

- Keep the status quo of not having an official formatter. The danger is that this creates discord within the nix community. On top of fragmented the community it can generate lengthy discussions (which do not advance the eco-system).

### Incremental migration

A more gradual approach, where only changed files get formatted for some period of time to make a more graceful transition has been rejected for practical concerns. Among other things, such an approach would not improve the amount of merge conflicts, and increase the workload for contributors during that time significantly.

## Unresolved questions

[unresolved]: #unresolved-questions

- Are there situation where automated formatting is worse than manual formatting? Do we want to have exceptions to automated formatting?

## Future work

[future]: #future-work

- TODO General style guidelines beyond AST reformatting

## Appendix A: Formatting style guidelines

**Nomenclature:**
Brackets: `[]`
Braces: `{}`
Parentheses: `()`

*These are not strict rules but guidelines to help create more consistent formatting rules.
Nevertheless, deviations should be documented and explained.*

- When deciding between two *equally good* options, currently prevalent formatting style in `nixpkgs` should be followed.
- On the top level (indentation zero), special rules may apply.
- Two spaces are used for each indentation level, there is no vertical alignment
- Consistency across language features is important. Syntax that behaves similarly should be formatted similarly.
- The Nix formatting style is space heavy. Where there can be a space, there should be a space.
  - Brackets and braces are generally written with a space on the inside, like `[ `, ` ]`, `{ ` and ` }`.
  - `[]` is written as `[ ]`, same for `{ }`.
  - Exception: Parentheses are written *without* a space on the inside
- Statements are either written on one line, or maximally spread out across lines, with no in-between (e.g. grouping).
  - Multi-line statements increment the indentation level in the statement's "body".
  - Grouping should be done by adding blank lines or comments.
- Where ~~possible~~ sensible indentation depth should be minimized, "double-indentations" should be avoided.
  - Examples are `… in {` and `… else if`

## Appendix B: Formatting rules

### Function declaration

> Discussions:
> [1](https://github.com/kamadorueda/alejandra/issues/95)

#### With Destructured Arguments

✅ Good:

```nix
{ mkDerivation, ... } @ attrs:
  mkDerivation # ...
```

- Indenting the body relative to the function signature
  hints that a new scope is introduced by the
  function arguments.
- Keeping the signature in one line
  when there is only 1 argument in the destructuring (`mkDerivation`)
  helps saving vertical space.
- Spacing between elements of the destructuring,
  and between opening and closing elements
  is consistent with _List_ and _Attrset_.

✅ Good:

```nix
{ mkDerivation, ... } @ attrs: {
  url, 
  sha256,
  ...
}:
mkDerivation # ...
```

- When a file starts with one or more of nested function declarations,
  it's valid not to indent the body of the function
  because it's clear when reading the file from top to bottom
  that the whole remaining of the file
  is the scope of the function(s),
  Therefore saving an unneeded indent.

✅ Good:

```nix
{
  mkDerivation,
  lib,
  fetchurl,
  ...
} @ attrs:
  stdenv.mkDerivation # ...
```

- Adding an argument produces a minimal diff
  (including the first and last elements):

  ```patch
    mkDerivation,
    lib,
    fetchurl,
  + google-chrome-stable,
  ```

- Removing an argument produces a minimal diff
  (including the first and last elements):

  ```patch
    mkDerivation,
  - lib,
    fetchurl,
  ```

- The comma at the end is consistent with _Let-In_, and _Attrset_,
  where the separator goes after the element
  instead of at the beginning.

❌ Bad:

```nix
{ lib
, mkDerivation
, fetchurl
, ...
} @ attrs:
stdenv.mkDerivation # ...
```

- Removing the first element
  produces a diff in two elements:

  ```diff
  - { lib
  - , mkDerivation
  + { mkDerivation
    , fetchurl
    , ...
    } @ attrs:
    stdenv.mkDerivation # ...
  ```

- Documenting the first argument creates an inconsistency
  between the way arguments start:

  ```nix
  {
    # Lorem Ipsum
    lib
  , mkDerivation
  , fetchurl
  , ...
  } @ attrs:
  stdenv.mkDerivation # ...
  ```

- This is not consistent with _Let-In_, and _AttrSet_,
  where the separator goes after the element
  instead of at the beginning.
- It ruins "folding by indentation" modes
  on Vim, Neovim, VSCode, and other major code editors,
  because the data-structure has the same indentation
  as the opening brace.

❌ Bad:

```nix
{ mkDerivation, lib, fetchurl, ... }@attrs: stdenv.mkDerivation # ...
```

- One-liners are unreadable and produce bad diffs.

❌ Bad:

```nix
{ mkDerivation, lib, fetchurl, extra-cmake-modules, kdoctools, wrapGAppsHook
, karchive, kconfig, kcrash, kguiaddons, kinit, kparts, kwind, ... }@attrs:
stdenv.mkDerivation # ...
```

- It's hard to tell this destructuring has an ellipsis (`...`) at a first glance,
  because it's mixed with the other arguments.
- Moving elements becomes harder
  than a simple whole-line movement.
  (Moving a whole line is normally a keyboard-shortcut
  or command in major code editors).
- Excessively compact:
  adding, removing, or editing an argument
  produces a diff in more than one argument.
- `}@attrs` is not intuitive
  with the rules of written english,
  where you add whitespace
  after the end of the previous phrase
  (`phrase. Other phrase`).

### Inherit

✅ Good:
```nix
inherit foo bar;
inherit (attrs) foo bar;
inherit
  foo
  bar
  ;
inherit (attrs)
  foo
  bar
  ;
```

- Inherit expressions can have their symbols either all on the same line as the `inherit`, or one line per element each.
- The `(attrs)` is always on the same line as the `inherit` statement. There are no spaces on the inside of its parentheses.
  - TODO what if attrs is long like in https://github.com/kamadorueda/alejandra/issues/367 ?

❌ Bad:
```nix
TODO
inherit (attrs) foo
  bar
  ;
```

TODO

Bad???
```nix
inherit
  (attrs)
  foo
  bar
  ;
```

### If-Then-Else

✅ Good:

```nix
if predicate
then foo
else bar
```

- The keyword at the beginning of the line
  states clearly the meaning of the content that follows.
- Produces a clean diff when you add more code.
  For example: adding content to the `else`
  only produces a diff in the `else`.

❌ Bad:

```nix
if predicate then foo else bar
```

- One-liners are hard to understand,
  specially when nested,
  or when logic gets long.
- Adding content produces a diff in the entire `if-then-else`.

✅ Good:

```nix
if something <= 2.0
then
  if somethingElse
  then foo
  else bar
else if something <= 4.0
then {
  foo = 10;
}
else if something <= 6.0
then [
  10
  20
]
else bar
```

- It's easy to follow that there are many conditionals.
- The indentation makes it easy to read
  which expression is associated to each conditional.
- Adding or modifying the branches produces a clean diff.

❌ Bad:

```nix
if cond
then if
  looooooooooooooooooooooooooooooooooooooooooooooooooooong
then foo
else bar
else if cond
then foo
else bar
```

- It's complex to distinguish the parent `if-then-else`
  from the child `if-then-else`

### Lists

✅ Good:
```nix
[ foo bar baz ]
[
  foo
  bar
  baz
]
[ ]
```

- For consistency with other formatting rules, more spacing is preferred

❌ Bad:
```nix
[foo bar baz]
[]
```

### Function applications

✅ Good:
```nix
fun arg1 arg2 arg3


callPackage ./some/path {
  foo = "bar";
} (
  if foo
  then bar
  else baz
)


if something <= 2.0
then
  if somethingElse
  then foo
  else bar
else if something <= 4.0
then
  {
    foo = 10;
  } // {
    bar = 20;
  }
else if something <= 6.0
then (
  if foo
  then bar
  else baz
)
else bar



callPackage
  ./some/path
  {
    foo = "bar";
  }
  (
    if foo
    then bar
    else baz
  )
```

- Consistent with `if then else` (except that the 

❌ Bad:
```nix

# - Rightward drift
# - Does not minimize indentation
callPackage ./some/path {
  foo = "bar";
} {
    bar = "baz";
  } {
      baz = "foobar";
    }
```

### String interpolation

TODO https://github.com/kamadorueda/alejandra/issues/242

Find a solution which is friendly to formatter implementations
