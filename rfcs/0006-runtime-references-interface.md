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
for builds to specify their own runtime references, and possibly for
nix to tell the build what its build time inputs are, bypassing nix's
own hash scanning.

# Motivation
[motivation]: #motivation

The existing hash scanning works very well for most use cases. There
are times, however, where we have to hack around the constraints it
imposes (e.g. `nukeReferences`, not storing the configure flags used
to build gcc, storing the path of a file in a comment to ensure the
build depends on it, etc.). Moreover, every time we need to tweak the
logic we need a new nix release. Finally, recursive nix will involve a
more complex reference checking story. Having an interface to
explicitly specify runtime references would improve all of these
issues.

# Detailed design
[design]: #detailed-design

Nix will put all the build time references (or requisites?) into
`$NIX_BUILD_TOP/build-time-references`. After the build completes, nix
will check `$NIX_BUILD_TOP/runtime-references` and, if it exists, skip
its builtin hash scanning and just use the file. Both files are
newline-separated lists of store paths. Parse errors in the
`runtime-references` file, or non-existent store paths, fail the build.

Alternatively, since recursive nix will require a more complex
interface with the host nix process anyway, we can just expose a unix
domain socket (possibly just a socketpair) to the build to query the
build time references and set the run time references.

# Drawbacks
[drawbacks]: #drawbacks

Arguably this will be a slight increase in complexity, but IMO it's
more moving complexity to a more appropriate place.

# Alternatives
[alternatives]: #alternatives

The main alternative is just sticking with the status quo and hacks,
which mostly works and can be accomodated (though not super cleanly)
in the recursive nix regime

# Unresolved questions
[unresolved]: #unresolved-questions

The exact specifics of the interface (see "Alternatively" in the
[detailed design](#detailed-design)).
