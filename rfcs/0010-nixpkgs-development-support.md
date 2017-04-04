---
feature: nixpkgs-development-support
start-date: 2017-04-04
author: Shea Levy
co-authors: (find a buddy later to help our with the RFC)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Add a `development-support` section to `nixpkgs` with functions useful
for those using nix in their software development.

# Motivation
[motivation]: #motivation

Currently, nixpkgs has some features, like `callCabal2nix` and the
`env` attribute of haskell packages, that don't really have anything
to do with package management per se but rather provide support for
developers who use nix to manage their projects. With the merging of
the `builtins.exec` nix feature, there are a number of developer tools
I'd like to make widely available, such as something to translate a
.gitignore into a filterSource call or do no-sha256 fetchgit with
caching. It would be good to have a single blessed place to put these
kinds of tools.

# Detailed design
[design]: #detailed-design

Add `pkgs/development-support`, add `pkgs.developmentSupport` calling
the functions defined in `pkgs/development-support`.

Any tool relying on `builtins.exec` will take that function as an
argument, rather than using the builtin directly, so that all of
nixpkgs evaluates properly without
`allow-unsafe-native-code-during-evaluation`.

# Drawbacks
[drawbacks]: #drawbacks

Arguably nixpkgs is about package management and shouldn't necessarily
be the one source for all things shared nix.

# Alternatives
[alternatives]: #alternatives

Separate repository with these tools defined, but then we lose tight
integration with the packages they depend on.

# Unresolved questions
[unresolved]: #unresolved-questions

None I think.
