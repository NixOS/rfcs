---
feature: flake-version
start-date: 2023-08-11
author: lucasew
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Add a optional `version` option for a flake to define which flake spec version one flake is using.

# Motivation
[motivation]: #motivation

Flakes are marked as unstable but are so widespread in the ecosystem that the
feature flag is more like an annoyance than something really good, pragmatically speaking.

# Detailed design
[design]: #detailed-design

In Docker, there is a tool called `docker-compose`, the reason why this tool exists
is not very relevant to this document but it's basically a tool that the user
uses some kind of data definition language to define a set of entities that
Docker will setup and spawn. This data definition language structure is as
stable as flake is today but they apply an extra concept to have more flexibility
if they need to change something: the `version` attribute.

Right now we have basically two flake specifications that became minimally widespread.
The first were introduced in Nix 2.4 and the second introduced in Nix 2.7.

The difference, [that is available in Nix 2.7 release notes](https://nixos.org/manual/nix/stable/release-notes/rl-2.7)
is basically about how default outputs are handled. Basically
`defaultThing.<system>` becomes `things.<system>.default`.

That way we can define the already existent versions as the following:
- Version 1: Flakes scheme introduced in Nix 2.4
- Version 2: Flakes revision introduced in Nix 2.7

The lack of `version` in a `flake.nix` will trigger a warning and then Nix will handle as
if `version` has the latest one supported by the version, so `1` for Nix <2.7 and `2` or more
for Nix past `>=2.7`. The support of the presence of the version option will require backs,
otherwise only the missing value case will be supported without the warning.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

```nix
{
    description = "Demo flake";
    version = 2;
    inputs = {
        nixpkgs.url = "nixpkgs";
    };
    outputs = { nixpkgs }: {
        packages.x86_64-linux.default = ...;
    };
}
```

# Drawbacks
[drawbacks]: #drawbacks

- Logic complexity in the Nix evaluator to support different versions.
- Inter-flake references may require some kind of driver to support inputs from different flakes.

# Alternatives
[alternatives]: #alternatives

- Flake usage without the experimental feature raising a warning instead of a hard error.

# Unresolved questions
[unresolved]: #unresolved-questions

- Do versions will be strings, like "1.0", or numbers, like 1?
It may be both but string versions allow minor versions.

# Future work
[future]: #future-work

Flake as a stable feature, but also allowing revisions.
