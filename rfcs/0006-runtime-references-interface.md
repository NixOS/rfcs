---
feature: runtime-references-interface
start-date: 2017-04-01
author: Shea Levy
co-authors: (find a buddy later to help our with the RFC)
related-issues: https://github.com/NixOS/rfcs/pull/6
---

# Summary
[summary]: #summary

Currently, nix itself scans derivation outputs for the hashes of the
(transitive closure of) the inputs of the build and registers those it
finds as references. This feature would provide an optional interface
for builds to specify their own runtime references and for nix to tell
the build what its build time inputs are, bypassing nix's own hash
scanning.

# Motivation
[motivation]: #motivation

The existing hash scanning works very well for most use cases. There
are times, however, where we have to hack around the constraints it
imposes (e.g. `nukeReferences`, not storing the configure flags used
to build gcc, storing the path of a file in a comment to ensure the
build depends on it, building disk images that don't retain references
to their contents, etc.). Moreover, every time we need to tweak the
logic we need a new nix release. Finally, recursive nix will involve a
more complex reference checking story. Having an interface to
explicitly specify runtime references would improve all of these
issues.

Nix will need to provide the build time requisites to the build to
enable us to move reference scanning to stdenv and to allow for setups
that use the reference scan results as a base and then modify that set
accordingly.

# Detailed design
[design]: #detailed-design

Nix will put all the build time requisites into
`$NIX_BUILD_TOP/build-time-requisites`. After the build completes, nix
will check `$NIX_BUILD_TOP/runtime-references` and, if it exists, skip
its builtin hash scanning and just use the file. Both files are
newline-separated lists of store paths. Parse errors in the
`runtime-references` file, or non-existent store paths, fail the build.

Optionally, to avoid duplicating the default reference scanning behavior
in Nix, we will also expose a tiny wrapper around the Nix
`scanForReferences` API, which consumers can use by using
`<nix/scan-for-references.nix>`. This will be usable inside a build as
follows:

```nix
${import <nix/scan-for-references.nix>} \
  $NIX_BUILD_TOP/build-time-requisites | grep -v [evil-reference] > \
  $NIX_BUILD_TOP/runtime-references
```

# Drawbacks
[drawbacks]: #drawbacks

Arguably this will be a slight increase in complexity, but IMO it's
more moving complexity to a more appropriate place.

# Alternatives
[alternatives]: #alternatives

The main alternative is just sticking with the status quo and hacks,
which mostly works and can be accomodated (though not super cleanly)
in the recursive nix regime. Tools like `nukeReferences` and similar
can approximate the mechanism we propose in this RFC in many cases,
but with disk images in particular they fall short, because the paths
are valid _inside_ the image, but we don't want to retain references
in the store that built it.

# Unresolved questions
[unresolved]: #unresolved-questions

None I'm aware of.

# Future work
[future]: #future-work

If this feature is added, we will likely want to implement hash
scanning in stdenv and add hooks to disable it or do something
afterward, and use that infrastructure to replace nukeReferences usage
etc.

Once we have recursive nix, we may be able to get away with removing
or reducing the `build-time-requisites` file.
