---
feature: simple-package-paths
start-date: 2022-09-02
author: Silvan Mosberger
co-authors: Robert Hensing
pre-RFC reviewers: Thomas Bereknyei, John Ericson, Alex Ameen
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: https://github.com/NixOS/nixpkgs/pull/211832
---

# Summary
[summary]: #summary

Auto-generate trivial top-level attribute definitions in `pkgs/top-level/all-packages.nix` from a directory structure that matches the attribute name.
This makes it much easier to contribute new packages, since there's no more guessing needed as to where the package should go, both in the ad-hoc directory categories and in `pkgs/top-level/all-packages.nix`.

# Motivation
[motivation]: #motivation

- It is not obvious to package contributors where to add files or which ones to edit. These are very common questions:
  - Which directory should my package definition go in?
  - What are all the categories and do they matter?
  - What if the package has multiple matching categories?
  - Why can't I build my package after adding the package file?
  - Where in all-packages.nix should my package go?
- Figuring out where an attribute is defined is a bit tricky:
  - First one has to find the definition of it in all-packages.nix to see what file it refers to
    - On GitHub this is even more problematic, as the `all-packages.nix` file is [too big to be displayed by GitHub](https://github.com/NixOS/nixpkgs/blob/nixos-22.05/pkgs/top-level/all-packages.nix)
  - Then go to that file's definition, which takes quite some time for navigation (unless you have a plugin that can jump to it directly)
    - It also slows down or even locks up editors due to the file size
  - `nix edit -f . package-attr` works, though that's not yet stable (it relies on the `nix-command` feature being enabled) and doesn't work with packages that don't set `meta.position` correctly).
- `all-packages.nix` frequently causes merge conflicts. It's a point of contention for all new packages

# Detailed design
[design]: #detailed-design

This RFC consists of two parts, each of which is implemented with a PR to Nixpkgs.

## PR 1: The unit directory standard

This part establishes the new _unit directory standard_ in Nixpkgs.
This standard is internal to Nixpkgs and not exposed as public interface.
This standard must be documented in the Nixpkgs manual.

### File structure

Create the initially-empty directory `pkgs/unit`, called _unit base directory_, in Nixpkgs.

Check the following using CI:
- The unit base directory must only contain subdirectories of the form `pkgs/unit/${shard}/${name}`, called _unit directories_.
- `name` is a string only consisting of the ASCII characters a-z, A-Z, 0-9, `-` or `_`.
- `shard` is the lowercased first two letters of `name`, expressed in Nix: `shard = toLower (substring 0 2 name)`.
- Each unit directory must contain a `package.nix` file and may contain arbitrary other files.

### Semantics

Introduce code to automatically define `pkgs.${name}` for each unit directory as a value equivalent to
```nix
pkgs.callPackage pkgs/unit/${shard}/${name}/package.nix { }`
```

Check the following using CI for each unit directory:
- The only definition for `pkgs.${name}` is the automatically generated one from the unit directory
- `pkgs.${name}` must evaluate to a [derivation](https://nixos.org/manual/nix/stable/glossary.html#gloss-derivation).
- The `package.nix` file must not transitively refer to files outside its unit directory.

## PR 2: Migration

Automatically migrate to the unit directory standard for all definitions `pkgs.${name}` that can be migrated by
- Only moving files
- Not changing the evaluation result

This will cause merge conflicts with all existing PRs that modify such moved files, however they can trivially be rebased using `git rebase && git push -f`.
However, to have the least amount of conflicts, this migration should be performed soon after a release when ZHF is over and the PR rate slows down.
This also gives a lot of time to fix any potential problems before the next release.

Manual updates may also be done to ensure further non-evaluation validity, such as
- [CODEOWNERS](https://github.com/NixOS/nixpkgs/blob/master/.github/CODEOWNERS)
- Update scripts like [this](https://github.com/NixOS/nixpkgs/blob/cb2d5a2fa9f2fa6dd2a619fc3be3e2de21a6a2f4/pkgs/applications/version-management/cz-cli/generate-dependencies.sh)

Due to the strict limitations of standard, this PR will not start enforcing it for new packages.

## Examples
[examples]: #examples

To add a new package `pkgs.foobar` to Nixpkgs, one only needs to create the file `pkgs/unit/fo/foobar/package.nix`.
No need to find an appropriate category nor to modify `pkgs/top-level/all-packages.nix` anymore.

With some packages, the `pkgs/unit` directory may look like this:

```
pkgs
└── unit
   ├── _0
   │  ├── _0verkill
   │  └── _0x
   ┊
   ├── ch
   │  ├── ChowPhaser
   │  ├── CHOWTapeModel
   │  ├── chroma
   │  ┊
   ┊
   ├── t
   │  └── t
   ┊
```

# Interactions
[interactions]: #interactions

## Migration size
Due to the limitations of the standard, only a limited set of top-level attributes can be migrated:
- No attributes that aren't derivations like `pkgs.fetchFromGitHub` or `pkgs.python3Packages`
- No attributes that share common files with other attributes like [`pkgs.readline`](https://github.com/NixOS/nixpkgs/tree/cb2d5a2fa9f2fa6dd2a619fc3be3e2de21a6a2f4/pkgs/development/libraries/readline)
- No attributes that references files from other packages like [`pkgs.gettext`](https://github.com/NixOS/nixpkgs/blob/cb2d5a2fa9f2fa6dd2a619fc3be3e2de21a6a2f4/pkgs/development/libraries/gettext/default.nix#L60)

A good estimation of this based on [a trial PR](https://github.com/NixOS/nixpkgs/pull/211832) on commit [287b071e9a71](https://github.com/nixos/nixpkgs/commit/287b071e9a7130cacf7664e5c69ec3a889b800f8):
- 18136 (100.0%) total top-level attributes
- 16319 (90.0%) are derivations (`lib.isDerivation`)
- 10763 (59.3%) are derivations and don't violate any other conditions

## Package locations

`nix edit` and search.nixos.org will automatically point to the new location without problems, since they rely on `meta.position` to get the file to edit, which still works.

## Git and NixOS release problems

- The migration will cause merge conflicts for a lot of PRs, but they are trivially resolvable using `git rebase && git push -f` due to Git's file rename tracking.
- Commits that change moved files in `pkgs/unit` can be cherry-picked to the previous file location without problems for the same reason.
- `git blame` locally and on GitHub is unaffected, since it follows file renames properly.

## `callPackage` with `nix-build -E`

A commonly recommended way of building package directories in Nixpkgs is to use `nix-build -E 'with import <nixpkgs> {}; callPackage pkgs/applications/misc/hello {}'`.
Since the path changes `package.nix` is now used, this becomes like `nix-build -E 'with import <nixpkgs> {}; callPackage pkgs/unit/he/hello/package.nix {}'`, which is harder for users.
However, calling a path like this is an anti-pattern anyway, because it doesn't use the correct Nixpkgs version and it doesn't use the correct argument overrides.
The correct way of doing it was to add the package to `pkgs/top-level/all-packages.nix`, then calling `nix-build -A hello`.
This `nix-build -E` workaround is partially motivated by the difficulty of knowing the mapping from attributes to package paths, which is what this RFC improves upon.
By teaching users that `pkgs/unit/*/<name>` corresponds to `nix-build -A <name>`, the need for such `nix-build -E` workarounds should disappear.

# Drawbacks
[drawbacks]: #drawbacks

- The existing categorization of packages gets lost. Counter-arguments:
  - It was never that useful to begin with
    - The categorization was always incomplete, because packages defined in the language package sets often don't get their own categorized file path.
    - It was an inconvenient user interface, requiring a checkout or browsing through GitHub
    - Many packages fit multiple categories, leading to multiple locations to search through instead of one
  - There's other better ways of discovering similar packages, e.g. [Repology](https://repology.org/)
- This breaks `builtins.unsafeGetAttrPos "hello" pkgs`. Counter-arguments:
  - We have to draw a line as to what constitutes the public interface of Nixpkgs. We have decided that making attribute position information part of that is not productive. For context, this information is already accepted to be unreliable at the language level, noting the `unsafe` part of the name.
  - Support for this could be added to Nix (make `builtins.readDir` propagate file as a position)

# Alternatives
[alternatives]: #alternatives

TODO: This needs updating

## A different unit base directory

Context: `pkgs/unit` is the unit base directory

Alternatives:
- Use `unit` (at the Nixpkgs root) instead of `pkgs/unit`.
  - This is future proof in case we want to make the directory structure more general purpose, but this is out of scope
- Other name proposals were deemed worse: `pkg`, `component`, `part`, `mod`, `comp`

## Alternate `pkgs/unit` structure

- Use a flat directory, e.g. `pkgs.hello` would be in `pkgs/unit/hello`.
  - Good because it's simpler, both for the user and for the code
  - Bad because the GitHub web interface only renders the first 1 000 entries (and we have about 10 000 that benefit from this transition, even given the restrictions)
  - Bad because it makes `git` and file listings slower
- Use `substring 0 3 name` or `substring 0 4 name`. This was not done because it still leads to directories in `pkgs/unit` containing more than 1 000 entries, leading to the same problems.
- Use multi-level structure, like a 2-level 2-prefix structure where `hello` is in `pkgs/unit/he/ll/hello`,
  if packages are less than 4 characters long, we will it out with `-`, e.g. `z` is in `pkgs/unit/z-/--/z`.
  This is not great because it's more complicated, longer to type and it would improve performance only marginally.
- Use a dynamic structure where directories are rebalanced when they have too many entries.
  E.g. `pkgs.foobar` could be in `pkgs/unit/f/foobar` initially.
  But when there's more than 1 000 packages starting with `f`, all packages starting with `f` are distributed under 2-letter prefixes, moving `foobar` to `pkgs/unit/fo/foobar`.
  This is not great because it's very complex to determine which directory to put a package in, making it bad for contributors.

## Alternate `package.nix` filename

- `default.nix`:
  - Bad because it doesn't have its main benefits here:
    - Removing the need to specify the file name in expressions, but this does not apply because this file will be imported automatically by the code that replaces definitions from `all-packages.nix`.
    - Removing the need to specify the file name on the command line, but this does not apply because a package function must be imported into an expression before it can be used, making `nix build -f pkgs/unit/hell/hello` equally broken regardless of file name.
  - Not using `default.nix` frees up `default.nix` for a short expression that is actually buildable, e.g. `(import ../.. {}).hello`, although we don't yet have a use case for this that isn't covered by `nix-build ../.. -A $attrname`.
  - Bad because using `default.nix` would tempt users to invoke `nix-build .` whereas making package functions auto-callable is a known anti-pattern as it duplicates the defaults.
  - Good because `default.nix` is already a convention most people are used to
- `pkg-fun.nix`/`pkg-func.nix`: The idea with this proposal was to make it easier to potentially transition to a non-function form of packages in the future, but there's no problem with introducing versioning later if needed in case we want to reuse `pkg.nix`/`package.nix`. We also don't even know if we actually want to have a non-function form of packages. Also the abbreviations are a bit jarring.

## Filepath backwards-compatibility

Additionally have a backwards-compatibility layer for moved paths, such as a symlink pointing from the old to the new location, or for Nix files even a `builtins.trace "deprecated" (import ../new/path)`.
- We are not doing this because it would give precedent to file paths being a stable API interface, which definitely shouldn't be the case (bar some exceptions).
- It would also lead to worse merge conflicts as the transition is happening, since Git would have to resolve a merge conflict between a symlink and a changed file.

## Not having the [reference requirement](#user-content-req-ref)

The reference requirement could be removed, which would allow unit directories to reference files outside themselves, and the other way around. This is not great because it encourages the use of file paths as an API, rather than explicitly exposing functionality from Nix expressions.

## Restrict design to try delay issues like "package variants" {#no-variants}

We perceived some uncertainty around [package variants](#def-package-variant) that led us to scope these out at first, but we did not identify a real problem that would arise from allowing non-auto-called attributes to reference `pkgs/unit` files. However, imposing unnecessary restrictions would be counterproductive because:

 - The contributor experience would suffer, because it won't be obvious to everyone whether their package is allowed to go into `pkgs/unit`. This means that we'd fail to solve the goal "Which directory should my package definition go in?", leading to unnecessary requests for changes in pull requests.

 - Changes in dependencies can require dependents to add an override, causing packages to be moved back and forth between unit directories and the general `pkgs` tree, worsening the problem as people have to decide categories *again*.

 - When lifting the restriction, the reviewers have to adapt, again leading to unnecessary requests for changes in pull requests.
 
 - We'd be protracting the migration by unnecessary gatekeeping or discovering some problem late.

That said, we did identify risks:

 - We might get something wrong, and while we plan to incrementally migrate Nixpkgs to this new system anyway, starting with fewer units is good.
    - Mitigation: only automate the renames of simple (`callPackage path { }`) calls, to keep the initial change small
 
 - We might not focus enough on the foundation, while we could more easily relax requirements later.
    - After more discussion, we feel confident that the manual `callPackage` calls are unlikely to cause issues that we wouldn't otherwise have.

## Recommend a `callPackage` pattern with default arguments

> - While this RFC doesn't address expressions where the second `callPackage` argument isn't `{}`, there is an easy way to transition to an argument of `{}`: For every attribute of the form `name = attrs.value;` in the argument, make sure `attrs` is in the arguments of the file, then add `name ? attrs.value` to the arguments. Then the expression in `all-packages.nix` can too be auto-called
>   - Don't do this for `name = value` pairs though, that's an alias-like thing

`callPackage` does not favor the default argument when both a default argument and a value in `pkgs` exist. Changing the semantics of `callPackage` is out of scope.

## Allow `callPackage` arguments to be specified in `<unit>/args.nix`

The idea was to expand the auto-calling logic according to:

Unit directories are automatically discovered and transformed to a definition of the form
```
# If args.nix doesn't exist
pkgs.${name} = pkgs.callPackage ${unitDir}/package.nix {}
# If args.nix does exists
pkgs.${name} = pkgs.callPackage ${unitDir}/package.nix (import ${unitDir}/args.nix pkgs);
```

Pro:
 - It makes another class of packages uniform, by picking a solution with restricted expressive power.

Con:
 - It does not solve the contributor experience problem of having too many rules.
 - `args.nix` is another pattern that contributors need to learn how to use, as we have seen that it is not immediately obvious to everyone how it works.
 - A CI check can mitigate the possible lack of uniformity, and we see a simple implementation strategy for it.
 - This keeps the contents of the unit directories simple and a bit more uniform than with optional `args.nix` files.

# Unresolved questions
[unresolved]: #unresolved-questions

# Future work
[future]: #future-work

All of these questions are in scope to be addressed in future discussions in the [Nixpkgs Architecture Team](https://nixos.org/community/teams/nixpkgs-architecture.html):

- Add a meta tagging system to packages as a replacement for the package categories. Maybe `meta.tags` with `search.nixos.org` integration.
- Making the filetree more human-friendly by grouping files together by "topic" rather than technical delineations.
  For instance, having a package definition, changelog, package-specific config generator and perhaps even NixOS module in one directory makes work on the package in a broad sense easier.
- This RFC only addresses the top-level attribute namespace, aka packages in `pkgs.<name>`, it doesn't do anything about package sets like `pkgs.python3Packages.<name>`, `pkgs.haskell.packages.ghc942.<name>`, which may or may not also benefit from a similar auto-calling
- Improve the semantics of `callPackage` and/or apply a better solution, such as a module-like solution
- What to do with different versions, e.g. `wlroots = wlroots_0_14`? This goes into version resolution, a different problem to fix
- What to do about e.g. `libsForQt5.callPackage`? This goes into overrides, a different problem to fix
- What about aliases like `jami-daemon = jami.jami-daemon`?
- What about `recurseIntoAttrs`? Not single packages, package sets, another problem
