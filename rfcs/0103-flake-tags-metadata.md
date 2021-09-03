---
feature: Flakes metadata (tags)
start-date: 2021-09-02
author: Bryan Honof
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Having a bit more information about what a flake provides could be useful for
identifying, and categorising, the software the flake contains. This way
existing tools like search.nixos.org can use this information for
indexing/searching.

# Motivation
[motivation]: #motivation

Just as NixPkgs uses a file structure to categorise software, e.g.
`./pkgs/games/minetest`, tags in a flake could function in the same way. Having
a tag called "games" in a flake that provides the minetest package as example,
will indicate that this flake possibly provides a package that happens to be a
game.

As mentioned in the summary, one of the use cases could be that of
search.nixos.org. It will also give the user an opportunity to specify what they
think the software's category is. Another use case could be that of NixOps.
Currently, NixOps doesn't use flakes, but shouldn't be too difficult to convert
to one. Once that has happened, a NixOps plugin could identify itself to be a
plugin by providing the tags `plugin` and `nixops`, inside their flake.

The expected outcome is that flakes will be better identifyable through a simple
interface.

# Detailed design
[design]: #detailed-design

The `tags` attribute in a flake should NOT be mandatory, but optional. It is
already possible to add an attribute `tags`, that is a list of strings, since
the `nix` command will ignore this attribute anyways. It would be a nice feature
to have Nix also parse this attribute when calling `nix flake show`, or `nix
flake metadata`.

## Tags as a way to tell what the flake repository is about

One site that already uses a sort of tag system is github. When looking at
[the github page for Nix](https://github.com/NixOS/nix), one can see multiple
tags assigned to the repository. Namely: `c-plus-plus`, `package-manager`,
`nix`, `functional-programming`, `declarative-language`. This tells the end-user
what Nix is all about. Without even reading the description, looking into the
source, or `grep`ping my way through the source, I already know it's programmed
in C++, Nix, is about functional- a declarative programming, etc.

Having tags in flakes would serve the same purpose, quickly identifying what a
repository is all about through the use of keywords.

## Tags as a way to make looking for flakes easier

There's an experimental feature over at
[search.nixos.org](https://search.nixos.org/flakes?) that allows a user to
search for flakes. Currently, it's only possible to search by name. Having tags
inside the flake as well would allow the user to provide additional detail
about what they're looking for. Instead of just searching for `minetest`, with
tags the user could also search for `minetest tags:server`, which would return
all the flakes that provide the `minetest` package, and also have `server` in
their tags list.

## Tags as a way to group related software together

Currently, there's a lot of software that either extends, or provides libraries
for, already existing packages. Take Python as example. There's many python
packages inside nixpkgs. These packages provide the python interpreter,
packages, libraries, etc. Having a flake that provides packages for
python could have the following tags: `python3`, `python37`, `python39`,
identifying the versions of python it supports, `machine-learning`, identifying
that this flake has something to do with machine learning, and `library`, saying
it's a library for python.

This mechanism would cause related software to be better identifyable. A user
that sees a flake with tags `python`, and `library`, would almost instantly know
that this flake provides a library for python. The `nix flake show` command
already does something similar to this, by telling the user the full name for
the path, e.g.
```
└───packages
    ├───aarch64-linux
    │   └───nixops-ovh: package 'python3.9-nixops-ovh-0.1.0'
```
But this isn't easily searchable.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

Given the following `flake.nix`.
```nix
#flake.nix
{
  description = "Minetest server version 5: Infinite-world block sandbox game";
  
  tags = [ "minetest" "server" "game" ];
  
  #...
}
```

When running `nix flake metadata`, on this flake, it would result in the following:
```
$ nix flake metadata
Resolved URL:  ...
Locked URL:    ...
Description:   Minetest server version 5: Infinite-world block sandbox game
Tags:          minetest, server, game
Path:          ...
Revision:      ...
```

When querying [search.nixos.org](https://search.nixos.org/flakes?) with the
following query, `minetest tags:server`, it will return the `minetest` flake,
that also happens to contain the tag `server`.

# Drawbacks
[drawbacks]: #drawbacks

There's a change that, if this gets implemented in multiple tools, the end-user
won't use it.

# Alternatives
[alternatives]: #alternatives

1. Try to parse the `description` attribute
  This isn't really scaleable, and the description can sometimes be misleading.

2. Use the github tags
  Assuming every single flake in existence will be on github isn't that good of
  an idea.

# Unresolved questions
[unresolved]: #unresolved-questions

If this is an useful something for the Nix ecosystem to agree upon?

# Future work
[future]: #future-work

Tags should be optional, as mentioned above, so existing software will keep
working the way it works right now. It might be possible to use the tags in the
future to implement feature such as a more advance query for search.nixos.org.
