| feature | simple-package-paths |
| --- | --- |
| start-date | 2022-09-02 |
| author | Silvan Mosberger (@infinisil) |
| co-authors | Robert Hensing (@roberth) |
| pre-RFC reviewers | Thomas Bereknyei (@tomberek), John Ericson (@Ericson2314), Alex Ameen (@aakropotkin) |
| shepherd-team | @phaer @06kellyjac @aakropotkin @piegamesde |
| shepherd-leader | - |
| related-issues | https://github.com/NixOS/nixpkgs/pull/237439, https://github.com/NixOS/nixpkgs/pull/211832 |

# Summary
[summary]: #summary

Auto-generate trivial top-level attribute definitions in Nixpkgs' `pkgs/top-level/all-packages.nix` from a directory structure that matches the attribute name.
This makes it much easier to contribute new packages, since there's no more guessing needed as to where the package should go, both in the ad-hoc directory categories and in `all-packages.nix`.

# Motivation
[motivation]: #motivation

- It is not obvious to package contributors where to add files or which ones to edit. These are very common questions:
  - Which directory should my package definition go in?
  - What are all the categories and do they matter?
  - What if the package has multiple matching categories?
  - Why can't I build my package after adding the package file?
  - Where in `all-packages.nix` should my package go?
- Figuring out where an attribute is defined is a bit tricky:
  - First one has to find the definition of it in `all-packages.nix` to see what file it refers to
    - On GitHub this is even more problematic, as the `all-packages.nix` file is [too big to be displayed by GitHub](https://github.com/NixOS/nixpkgs/blob/nixos-22.05/pkgs/top-level/all-packages.nix)
  - Then go to that file's definition, which takes quite some time for navigation (unless you have a plugin that can jump to it directly)
    - It also slows down or even locks up editors due to the file size
  - `nix edit -f . package-attr` works, though that's not yet stable (it relies on the `nix-command` feature being enabled) and doesn't work with packages that don't set `meta.position` correctly).
- `all-packages.nix` frequently causes merge conflicts. It's a point of contention for all new packages

# Detailed design
[design]: #detailed-design

This RFC consists of two parts, each of which is implemented with a PR to Nixpkgs.
These PR's should be done after a release to maximize the testing period and minimize merge conflicts.

## PR 1: The directory structure

This part establishes the new directory structure in Nixpkgs.
This directory structure is internal to Nixpkgs and not exposed as public interface.
This directory structure must be documented in the Nixpkgs manual.
This PR will be backported to the stable release in order to ensure that backports of new packages work.

### File structure

Create the initially-empty `pkgs/by-name` directory in Nixpkgs, and migrate the `hello` package into it.

Check the following using CI:
- `pkgs/by-name` must only contain subdirectories of the form `${shard}/${name}`, called _package directories_.
- The `name`'s of package directories must be unique when lowercased
- `name` is a string only consisting of the ASCII characters `a-z`, `A-Z`, `0-9`, `-` or `_`.
- `shard` is the lowercased first two letters of `name`, expressed in Nix: `shard = toLower (substring 0 2 name)`.
- Each package directory must contain a `package.nix` file and may contain arbitrary other files.

### Semantics

Introduce code to automatically define `pkgs.${name}` for each package directory as a value equivalent to
```nix
pkgs.callPackage pkgs/by-name/${shard}/${name}/package.nix { }
```

Optionally there may also be an overriding definition of `pkgs.${name}` in `pkgs/top-level/all-packages.nix` equivalent to
```nix
pkgs.callPackage pkgs/by-name/${shard}/${name}/package.nix args
```

with an arbitrary `args`.

Check the following using CI for each package directory:
- `pkgs.${name}` is defined as above, either automatically or with some `args` in `pkgs/top-level/all-packages.nix`.
- `pkgs.${name}` is a [derivation](https://nixos.org/manual/nix/stable/glossary.html#gloss-derivation).
- <a id="req-ref"></a> The `package.nix` file evaluated from `pkgs.${name}` must not access files outside its package directory.

## PR 2: Automated migration

Automatically migrate to new directory structure for all _satisfiying definitions_ `pkgs.${name}`, meaning derivations defined as above using `callPackage`.

However automatic migration is only possible if:
- Files don't need to be changed, only moved, with the exception of `pkgs/top-level/all-packages.nix`
- The Nixpkgs package evaluation result does not change

All satisfying definitions that can't be automatically migrated due to the above restrictions will be added to a CI exclusion list.
CI is added to ensure that all satisfying definitions except the CI exclusion list must be using the new directory structure.
This means that the new directory structure becomes mandatory for new satisfying definitions after this PR.
The CI exclusion list should be removed eventually once the non-automatically-migratable satisfying definitions have been manually migrated.
Only in very limited circumstances is it allowed to add new entries to the CI exclusion list.

Non-automatic updates may also be done to ensure further correctness, such as
- [GitHub's CODEOWNERS](https://github.com/NixOS/nixpkgs/blob/master/.github/CODEOWNERS)
- Update scripts like [this](https://github.com/NixOS/nixpkgs/blob/cb2d5a2fa9f2fa6dd2a619fc3be3e2de21a6a2f4/pkgs/applications/version-management/cz-cli/generate-dependencies.sh)
- The Nixpkgs manual like [here](https://github.com/NixOS/nixpkgs/blob/4c8ca604aef8204145c185c89cc52ee54dd7fc1a/doc/contributing/quick-start.chapter.md#L27)

This PR [will cause merge conflicts](https://github.com/nixpkgs-architecture/nixpkgs/pull/2) with all existing PRs that modify moved files, however they can trivially be rebased using `git rebase && git push -f`.
Because of this, merging of this PR should be widely announced with a pinned issue on the Nixpkgs issue tracker and a Discourse post.
Additionally this PR can benefit from being merged after a release due to the decreased PR count, leading to less conflicts.

## Examples
[examples]: #examples

To add a new package `pkgs.foobar` to Nixpkgs, one only needs to create the file `pkgs/by-name/fo/foobar/package.nix`.
No need to find an appropriate category nor to modify `all-packages.nix` anymore.

With some packages, the `pkgs/by-name` directory may look like this:

```
pkgs
└── by-name
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

## Shard distribution

The sharded structure [leads to a distribution](https://gist.github.com/infinisil/95c7013db62e9f23ab2bc92165a37221) as follows:
- There's 17305 total non-alias top-level attribute names in Nixpkgs revision [6948ef4deff7](https://github.com/nixos/nixpkgs/commit/6948ef4deff7a72ebe5242244bd3730e8542b925)
- These are split into 726 shards
- The top three shards are:
  - "li": 1092 values, coming from the common `lib` prefix
  - "op": 260 values
  - "co": 252 values
- There's only a single directory with over 1 000 entries, which is notably GitHub's display limit, so this means only 92 attributes would be harder to see on GitHub

These stats are also similar for other package sets for if directory structure were to be adopted for them in the future.

## Migration size
Due to the limitations of the new directory structure, only a limited set of top-level attributes can be automatically migrated:
- No attributes that aren't derivations like `pkgs.fetchFromGitHub` or `pkgs.python3Packages`
- No attributes defined using non-`pkgs.callPackage` functions like `pkgs.python3Packages.callPackage` or `pkgs.haskellPackages.callPackage`.
In the future we might consider having a separate namespace for such definitions.

Concretely this [can be computed](https://gist.github.com/infinisil/4f2bd165c2603fc28ab536f39ac2fd27) to be 81.2% (14036) attributes out of the 17280 total non-alias top-level Nixpkgs attributes in revision [6948ef4deff7](https://github.com/nixos/nixpkgs/commit/6948ef4deff7a72ebe5242244bd3730e8542b925).

And the initial automatic migration will be a bit more limited due to the additional constraints:
- No attributes that share common files with other attributes like [`pkgs.readline`](https://github.com/NixOS/nixpkgs/tree/cb2d5a2fa9f2fa6dd2a619fc3be3e2de21a6a2f4/pkgs/development/libraries/readline)
- No attributes that references files from other packages like [`pkgs.gettext`](https://github.com/NixOS/nixpkgs/blob/cb2d5a2fa9f2fa6dd2a619fc3be3e2de21a6a2f4/pkgs/development/libraries/gettext/default.nix#L60)
These attributes will need to be moved to the new directory structure manually with some arguably-needed refactoring to improve reusability of common files.

## Package locations

`nix edit` and search.nixos.org will automatically point to the new location without problems, since they rely on `meta.position` to get the file to edit, which still works.

## Git and NixOS release

- Backporting changes to moved files [won't be problematic](https://github.com/nixpkgs-architecture/nixpkgs/pull/4)
- `git blame` locally and on GitHub is unaffected, since it follows file moves properly.

## `callPackage` with `nix-build --expr`

A commonly recommended way of building current package directories in Nixpkgs is to use `nix-build --expr 'with import <nixpkgs> {}; callPackage pkgs/applications/misc/hello {}'`.
Since the path changes `package.nix` is now used, this becomes like `nix-build --expr 'with import <nixpkgs> {}; callPackage pkgs/by-name/he/hello/package.nix {}'`, which is harder for users.
However, calling a path like this is an anti-pattern anyway, because it doesn't use the correct Nixpkgs version and it doesn't use the correct argument overrides.
The correct way of doing it was to add the package to `all-packages.nix`, then calling `nix-build -A hello`.
This `nix-build --expr` workaround is partially motivated by the difficulty of knowing the mapping from attributes to package paths, which is what this RFC improves upon.
By teaching users that `pkgs/by-name/<shard>/<name>` corresponds to `nix-build -A <name>`, the need for such `nix-build --expr` workarounds should disappear.

## Manual removal of custom arguments

While this RFC allows passing custom arguments, doing so means that `all-packages.nix` will have to be maintained for that package.
In specific cases where attributes of custom arguments are of the form `name = value` and `name` isn't a package attribute, they can be avoided without breaking the API.
To do so, ensure that the function in the called file has `value` as an argument and set the default of the `name` argument to `value`.

This notably doesn't work when `name` is already a package attribute or when such a package is added later, because then the default is never used and instead overridden.

## Package variants

Sometimes there's a need to create a variant of a package with different `callPackage` arguments. This can be achieved using `.override` as follows:
```nix
{
  graphviz_nox = graphviz.override { withXorg = false; };
}
```

However this can cause problems with an overlay that tries to make the variant the default as follows:
```nix
self: super: {
  # Oops, infinite recursion!
  graphviz = self.graphviz_nox;
}
```

Because of this, there's the pattern of duplicating the `callPackage` call with the custom arguments as such:
```nix
{
  graphviz_nox = callPackage ../tools/graphics/graphviz { withXorg = false; };
}
```

The semantics of how package directories are checked by CI do allow the definition of package variants from package directories:
```nix
{
  graphviz_nox = callPackage ../by-name/gr/graphviz/package.nix { withXorg = false; };
}
```

# Drawbacks
[drawbacks]: #drawbacks

- This directory structure can only be used for top-level packages using `callPackage`, so not for e.g. `python3Packages.requests` or a package defined using `haskellPackages.callPackage`
- It's not possible anymore to be a [GitHub code owner](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners) of category directories.
- The existing categorization of packages gets lost. Counter-arguments:
  - It was never that useful to begin with.
    - The categorization was always incomplete, because packages defined in the language package sets often don't get their own categorized file path.
    - It was an inconvenient user interface, requiring a checkout or browsing through GitHub
    - Many packages fit multiple categories, leading to multiple locations to search through instead of one
  - There's other better ways of discovering similar packages, e.g. [Repology](https://repology.org/)
- This breaks `builtins.unsafeGetAttrPos "hello" pkgs`. Counter-arguments:
  - We have to draw a line as to what constitutes the public interface of Nixpkgs. We have decided that making attribute position information part of that is not productive. For context, this information is already accepted to be unreliable at the language level, noting the `unsafe` part of the name.
  - Support for this could be added to Nix (make `builtins.readDir` propagate file as a position)

# Alternatives
[alternatives]: #alternatives

## An alternative to the `pkgs/by-name` location

Context: this directory contains the shards, which contain the package directories. We could move the shards to a different location.

Alternatives:
- Use `by-name` in the root directory instead
  - (+) This is future proof in case we want to make the directory structure more general purpose
    - (-) We don't yet know if we want that, so this is out of scope for now
- Use `pkgs` instead, so that the `${shard}`'s are siblings to the other current directories in `pkgs` such as `top-level`, with the intention that the other directories would be hopefully removed at some point, then only leaving the shards in `pkgs`
  - (+) If we remove the other directories at some point, only the `${shard}`'s will be left in `pkgs`
  - (-) This leads to ambiguities between the directories from the new directory structure and the other directories, requiring special handling in the code and CI, leading to complexities.
  - (-) This makes it hard to pick out the few non-shard directories in directory listings since they will be interleaved with the ~700 shards.
  - (-) This would be harder to document and explain to people, since one always has to disregard all non-sharded directories, with no obvious justification
  - (-) Currently we cannot apply this directory structure to all definitions in `pkgs`, in particular nested packages like `pythonPackages.*`, non-`callPackage`'d definitions like `copyDesktopItems` and non-derivations like `fetchFromGitHub`.
    Depending on how we want to handle those, it might make more sense to keep `pkgs/by-name` or to use `pkgs` directly once all legacy paths are migrated away to another top-level directory, we don't yet know. `pkgs/by-name` will be easier to migrate to `pkgs` than the other way around though.
  - (-) Causes poor auto-completion for the existing directories
- A variation of the above that improves on this is altering the shards to be prefixed with `_` so that they're always ordered together and not interleaved with non-shards. Non-shards would still be at the bottom of file listings though, but at least together. It shares the same other problems however.
- `pkgs/unit`: This was the name initially used by the RFC until `by-name` was proposed and favored.
  - (+) It's not associated with any pre-existing assumptions about what it means, which should cause people unfamiliar with this directory structure to read the documentation.
    - (-) This is however also a disadvantage, the name doesn't inform people anything about what it does
    - (-) Systemd also has the term "unit", which could be confused with this
  - (+) It makes sense to view package directories as units, because they are discrete entities distinct from other entities of the same type
  - (+) We envision that in the future we could extend the directory structure to not just include a package definition for each directory, but also other parts such as NixOS modules, library components, tests, etc. In this case `unit` would fit even better and could be described as
    > A collection of standardized files related to the same software component
- Various other proposals: `pkgs/auto`, `pkgs/pkg`, `pkgs/mod`, `pkgs/component`, `pkgs/part`, `pkgs/comp`, `pkgs/app`, `pkgs/simple`, `pkgs/default`, `pkgs/shards`, `pkgs/top`, `pkgs/main`
  - (-) Generally all of these names have some pre-existing assumptions about them, causing potential confusion when used for this concept
  - `pkgs/default`: Could be interpreted to be some Nix-builtin magic that defaults to that folder. Could also be interpreted as "this is where the default packages go", which then raises the question "which packages are part of the default ones?"
  - `pkgs/shards`: The sharding is a self-evident implementation detail, it shouldn't be repeated
  - `pkgs/simple`: Implies that there's a complicated way to declare packages, which there currently is, but it's something we should get away from.
    If we migrate everything, simple wouldn't mean anything anymore.
  - `pkgs/top`: Easily confusable with `pkgs/top-level`, though `top` would make sense otherwise if we eventually moved all top-level packages to there.
    - We could consider moving `pkgs/top-level` to another location then, e.g. `pkgs/package-sets`.
  - `pkgs/main`: "If these are the main packages, where do the others go? What even is a main package?". Also could be confused with an entry-point
- `packages/${shard}`
  - (+) Provides a clean starting point without having to be close to the legacy structure
  - (-) This would be very confusing to newcomers because there's now both a `pkgs` and a `packages` directory in the Nixpkgs root, both spelled the same but very different contents.
- `pkgs/_`
  - (+) Very short, fast to type (though that can depend on the keyboard layout)
  - (+) Avoids naming discussions, because there is no name
    - (-) Naming things is hard, but we shouldn't avoid the problem by giving it no name, which is arguably the worst name
  - (-) Looks hacky and internal
  - (+) Looks temporary, intention to move to `pkgs` itself once everything is sharded
    - (-) It shouldn't be temporary. While we do hope to migrate all packages to some sharded form at some point, this may never happen, or the direction is completely changed, and this may take years to form.

## Alternate shard structure

Context: The structure is `pkgs/by-name/${shard}/${name}` with `shard` being the lowercased two-letter prefix of `name`.

Alternatives:
- A flat directory, where `pkgs.hello` would be in `pkgs/by-name/hello`.
  - (+) Simpler for the user and code.
  - (-) The GitHub web interface only renders the first 1 000 entries when browsing directories, which would make most packages inaccessible in this way.
    - (+) This feature is not used often.
      - (-) [A poll](https://discourse.nixos.org/t/poll-how-often-do-you-navigate-through-directories-on-github-to-get-to-a-nixpkgs-package-file/21641) showed that about 41% of people rely on this feature every week.
  - (-) Bad because it makes `git` and file listings slower.
- Use three-letter or four-letter prefixes.
  - (-) Also leads to directories containing more than 1 000 entries, see above.
- Use multi-level structure, e.g. a two-level two-letter prefix structure where `hello` is in `pkgs/by-name/he/ll/hello`
  - (+) This would allow virtually a unlimited number of packages without performance problems
  - (-) It's hard to understand, type and implement, needs a special case for packages with few characters
    - E.g. `x` could go in `pkgs/by-name/x-/--/x`
  - (-) There's not enough packages even in Nixpkgs that a two-level 4-letter structure would make sense. Most of the structure would only be filled by a couple entries.
  - (-) Even Git only uses 2-letter prefixes for its objects hex hashes
- Use two-letter prefixes split into two directories, like `pkgs/by-name/h/e/hello`
  - (+) Allows easy traversal by clicking on GitHub file listings, shard directories being limited to under 40 children
  - (-) Requires special-casing single-letter attribute names
    - (+) There's currently only 6 such cases, which could be handled on a one-off basis
  - (-) Makes auto-completion worse, having to tab-complete once more
  - (-) Makes it harder to create shards: if a shard doesn't exist yet, it has to be created with either one or two `mkdir`'s, or a `mkdir -p`
- Use a dynamic structure where directories are rebalanced when they have too many entries.
  E.g. `pkgs.foobar` could be in `pkgs/by-name/f/foobar` initially.
  But when there's more than 1 000 packages starting with `f`, all packages starting with `f` are distributed under 2-letter prefixes, moving `foobar` to `pkgs/by-name/fo/foobar`.
  - (-) The structure depends not only on the name of the package then, making it harder to find packages again and figure out where they should go
  - (-) Complex to implement

## Alternate `package.nix` filename

Context: The only file that has to exist in package directories is `package.nix`, it must contain a function suitable for `callPackage`.

Alternatives:
- `default.nix`
  - (+) `default.nix` is already a convention most people are used to.
  - (-) We don't benefit from the usual `default.nix` benefits:
    - Removing the need to specify the file name in expressions, but this does not apply because this file will be imported automatically by the code that replaces definitions from `all-packages.nix`.
      - (+) But there's still some support for `all-packages.nix` for custom arguments, which requires people to type out the name
        - (-) This is hopefully only temporary, in the future we should fully get rid of `all-packages.nix`
    - Removing the need to specify the file name on the command line, but this does not apply because a package function must be imported into an expression before it can be used, making `nix build -f pkgs/by-name/hell/hello` equally broken regardless of file name.
  - (-) Not using `default.nix` frees up `default.nix` for an expression that is actually buildable, e.g. `(import ../.. {}).hello`, although we don't yet have a use case for this that isn't covered by `nix-build ../.. -A <attrname>`.
  - (-) Using `default.nix` would tempt users to invoke `nix-build .`, which wouldn't work and making package functions auto-callable is a known anti-pattern.
- `pkg-fun[c].nix`
  - (+) Makes a potential transition to a non-function form of packages in the future easier.
    - (-) There's no problem with introducing versioning later with different filenames.
    - (-) We don't even know if we actually want to have a non-function form of packages.
  - (-) Abbreviations are a bit jarring.

## Filepath backwards-compatibility

Context: The migration moves files around without providing any backwards compatibility for those moved paths.

Alternative:
- Have a backwards-compatibility layer for moved paths, such as a symlink pointing from the old to the new location, or for Nix files even a `builtins.trace "deprecated" (import ../new/path)`.
  - (-) It would give precedent to file paths being a stable API interface, which definitely shouldn't be the case (bar some exceptions).
  - (-) Leads to worse merge conflicts as the transition is happening, since Git would have to resolve a merge conflict between a symlink and a changed file.

## Don't allow custom arguments

Context: It's possible to override the default `{ }` argument to `callPackage` by manually specifying the full definition in `all-packages.nix`

The alternative is to not allow that, requiring that `pkgs.${name}` corresponds directly to `callPackage pkgs/by-name/${shard}/${name}/package.nix { }`.
- (-) It's harder to explain to beginners whether their package can use the new directory structure or not
- (+) The direct correspondance ensures that the package directory contains all information about the package, which is very intuitive
  - (-) We're not at the point where we can have that though, custom arguments don't have a good replacement yet
- (-) If a package previously didn't need custom arguments, it would be moved to the new directory structure. But when the need for a custom argument arises, it then requires moving it out from new directory structure and into the freeform structure of `pkgs/` again.
- (+) It's easier to relax restrictions than to impose new ones

## Reference check

Context: There's a [requirement](#user-content-req-ref) to check that package directories can't access paths outside themselves.

Alternatives:
- Don't have this requirement
  - (-) Doesn't discourage the use of file paths as an API.
  - (-) Makes further migrations to different file structures harder.
- Make the requirement also apply the other way around: Files outside the package directory cannot access files inside it, with `package.nix` being the only exception, and only for the one attribute in `all-packages.nix`
  - (-) Enforcing this requires a global view of Nixpkgs, which is nasty to implement
  - (-) [Package variants](#package-variants) would not be possible to define

## Allow `callPackage` arguments to be specified in `args.nix`

Context: Custom `callPackage` arguments have to be added to `all-packages.nix`

Alternative:
Expand the auto-calling logic according to:
Package directories are automatically discovered and transformed to a definition of the form
```
# If args.nix doesn't exist
pkgs.${name} = pkgs.callPackage ${packageDir}/package.nix {}
# If args.nix does exists
pkgs.${name} = pkgs.callPackage ${packageDir}/package.nix (import ${packageDir}/args.nix pkgs);
```

- (+) It makes another class of packages uniform, by picking a solution with restricted expressive power.
- (-) It does not solve the contributor experience problem of having too many rules.
      `args.nix` is another pattern that contributors need to learn how to use, as we have seen that it is not immediately obvious to everyone how it works.
  - (+) A CI check can mitigate the possible lack of uniformity, and we see a simple implementation strategy for it.
- (-) Complicates the directory structure with an optional file

# Unresolved questions
[unresolved]: #unresolved-questions

# Future work
[future]: #future-work

All of these questions are in scope to be addressed in future discussions in the [Nixpkgs Architecture Team](https://nixos.org/community/teams/nixpkgs-architecture.html):

- Expose an API to get access to the package functions directly, without calling them
- Add a meta tagging or categorization system to packages as a replacement for the package categories. Maybe `meta.tags` with `search.nixos.org` integration. Maybe https://repology.org/ integration. See also https://github.com/NixOS/rfcs/pull/146.
- Making the filetree more human-friendly by grouping files together by "topic" rather than technical delineations.
  For instance, having a package definition, changelog, package-specific config generator and perhaps even NixOS module in one directory makes work on the package in a broad sense easier.
- This RFC only addresses the top-level attribute namespace, aka packages in `pkgs.<name>`, it doesn't do anything about package sets like `pkgs.python3Packages.<name>`, `pkgs.haskell.packages.ghc942.<name>`, which may or may not also benefit from a similar auto-calling
- Improve the semantics of `callPackage` and/or apply a better solution, such as a module-like solution
- Potentially establish an updateScript standard to avoid problems like, relates to Flakes too
- What to do with different versions, e.g. `wlroots = wlroots_0_14`? This goes into version resolution, a different problem to fix
- What to do about e.g. `python3Packages.callPackage`? This goes into overrides, a different problem to fix
- What about aliases like `jami-daemon = jami.jami-daemon`?
- What about `recurseIntoAttrs`? Not single packages, package sets, another problem
