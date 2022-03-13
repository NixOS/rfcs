---
feature: flake-names
start-date: 2022-03-12
author: Anselm Schüler
co-authors: None
shepherd-team: None
shepherd-leader: None
related-issues: None
---

# Summary
[summary]: #summary

Flakes can declare the field `name`.  
It represents the name of the flake.  
The derivations for a flake are no longer called `source`, but use the flake name.

# Motivation
[motivation]: #motivation

Flake-centric workflows often end up with a lot of derivations named “source”, and it’s difficult to navigate this.
Also, the discoverability and usability of flakes needs to be improved. Current commands mostly show technical information. This would be a step in the right direction.

# Detailed design
[design]: #detailed-design

A new supported property for flakes is introduced, `name`.  
The derivation that contains the flake’s content is called `flake-source-${name}` or, if a source control tag (e.g. git tag such as V3) is available, `flake-source-${name}-${tag}`.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

Running `nix flake metadata` on a flake that declares this field displays it at the top.  
Running `nix flake show` on a flake that declares this field shows the name instead of the URL, followed by the URL in parentheses.

Examples:

File `/example/flake.nix`
```nix
{
  name = "example";
  outputs = { ... }: {
    lib.example = "example";
  };
}
```

Shell
```console
$ nix eval git+file:///example
[…] copying flake-source-example
"example"
```

Example of interactions:

Shell (using the previous file)
```
$ nix flake metadata /example
Name:          example
Resolved URL:  git+file:///example
Locked URL:    …
$ nix flake show /example
example (git+file:///home/anselmschueler/Code/example?rev=b0&rev=c714c8624f5d49a9d88e6e24550dd88515923c18)
└───lib: unknown
```

# Drawbacks
[drawbacks]: #drawbacks

This may cause clutter and additional maintenance.  
Since this changes the output of nix flake metadata and nix flake show, it might cause scripts that read this output to break.

# Alternatives
[alternatives]: #alternatives

Flake names could be handled entirely through outside means, with things like the global registry merely pointing to flakes under names.

# Unresolved questions
[unresolved]: #unresolved-questions

The name scheme could be changed. `flake-source-${name}-${tag}` could be too long.  
The interactions with nix flake metadata and nix flake show are not critical to the design, which is mostly aimed at clarifying derivation names.

# Future work
[future]: #future-work

Flake discoverability and usability needs to be improved.
