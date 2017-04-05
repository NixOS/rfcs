---
feature: per-project-config
start-date: 2017-04-05
author: Shea Levy
co-authors: (find a buddy later to help our with the RFC)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Trusted projects can have a `nix.conf.local` in their root, which is
merged into the calling user's `nix.conf` for nix operations performed
in that tree.

# Motivation
[motivation]: #motivation

Some projects want to pull from a specific binary cache, or depend on
features like `allow-unsafe-native-code-during-evaluation`. It should
be possible to automatically turn those on in a way localized to work
on that project.

# Detailed design
[design]: #detailed-design

The `trusted-project-roots` nix conf option is a list of paths
(default empty). If nix operates in[*][unresolved] a subdirectory of
one of those paths, it walks up until it reaches `nix.conf.local`, if
it exists, and reads it as a `nix.conf` with options overriding those
in the global `nix.conf`.

Since the nix daemon never deals with nix expressions directly, it is
only the client process which will see the `nix.conf.local` files and
thus when the daemon is operative `nix.conf.local` can only set
options that clients are allowed to set.

# Drawbacks
[drawbacks]: #drawbacks

If people are careless with `trusted-project-roots` and evaluate
arbitrary nix expressions, they can be hit with arbitrary code
execution.

# Alternatives
[alternatives]: #alternatives

Currently, we must manually switch our option sets per project as
appropriate, or try to find a global set that works for most cases. If
one of those cases requires
`allow-unsafe-native-code-during-evaluation`, there is a temptation to
just set that globally.

# Unresolved questions
[unresolved]: #unresolved-questions

Is the path nix is operating on determined by the current working
directory or the path of the nix expression(s) it's evaluating?

What degree of symlink resolution, if any, should be done before
checking if one path is in a subdirectory of another?

# Future work
[future]: #future-work

None impacting any nix projects directly.
