---
feature: configuration_file_generators
start-date: 2020-10-18
author: Michael Raskin @7c6f434c
co-authors: (in-progress)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Provide the configuration file generation functionality separately from NixOS
as a whole, and using the module system without the global namespace.

# Motivation
[motivation]: #motivation

There is currently a lot of code duplication between
* NixOS
* home-manager
* nix-darwin

and obviously growing code duplication with any effort running on below-Tier-2
platforms. That leads both to effort duplication, and to confusion among users
using multiple Nix ecosystem tools for service generation,

While fully resolving the problem is likely not fully compatible with the core
preferences of maintainers on each specific platform, we believe that config
file generation could be a shared resource just like Nixpkgs based on the
following properties:
* unlike, say, upstream `systemd` unit files we typically do not
  reuse-and-override upstream configs, but generate our own (both in NixOS and
  other service collections)
* the configs for a piece of software often have few dependencies on the
  general environment
* it can be defined as a purely functional library, simplifying integration

We aim to reduce duplication of effort and code while also having a high level
of inspection and tweaking possibilities without needing to patch module
source.

# Detailed design
[design]: #detailed-design

This RFC proposal builds upon RFCs#42 defining a configuration file abstraction
approach.

A top-level directory is added to the Nixpkgs repository, and a library of
functions implementing program configuration file generation is created within
this directory.  Each such generator takes as an input a NixOS module system
based attribute set «subtree», e.g. the attribute set typically bound to `cfg`
variable in the current NixOS service modules.

The output of each such function is an attribute set. The keys are relative
file names of configuration files, and the values are attribute sets of RFCs#42
settings abstraction and serialiser.

The function is provided as a member of an attribute set, which also contains
the corresponding type specifications for input and output modules are defined.

In some cases we only provide low-level overridable default configuration. In
this case the input may have the type that is always an empty attribute set,
`{}`.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

A minimalistic silly example is:

Input:
```
  {
     port = 1234;
     nodeName = "localhost";
     content = "Hello";
  }
```

Output:
```
  {
    "subdir/listen.conf" = {
      serialiser = toJSON;
      settings = {
        listenPort = "1234";
        serverGreet = "I am localhost";
      };
      type = …;
    };
    "subdir/content.conf" = {
      serialiser = toINI;
      settings = {
        greeting = {
          greeter = "localhost";
        };
        payload = {
          value = "I say to you: ‘Hello’";
        };
      };
      type = …;
    };
  }
```

# Drawbacks
[drawbacks]: #drawbacks

The proposed approach increases the spreading of the related code, from package
and service module to package and configuration generator and module.

The proposed refactoring incurs a cost in terms of implementation effort across
NixOS, and likely to create a medium-term situation of partial migration.

# Alternatives
[alternatives]: #alternatives

Do nothing, continuing with the current code duplication.

Same, but put configuration generators closer to packages. This would mean
widespread use of the module system inside `pkgs/`. There is also no guarantee
that all the configuration files describing interaction of multiple software
packages will have a clear choice of reference package.

There also have been many solutions proposed based on a significant rework of the module system.

Abstract generation of configuration files with package-like flat arguments and
plain text file outputs. This approach will need less code as long as it we do
not want type checks, or ease of overriding values.

Implement a complete service abstraction not tied to global system-wide
assumptions.

# Unresolved questions
[unresolved]: #unresolved-questions

Currently none.

# Future work
[future]: #future-work

Define generic service abstraction for non-`systemd` systems, possibly with a
convertor from `systemd` units.

Consider some  way of referring from package to related configuration file
generators via `meta` or `passthru`, in a way similar to `passthru.tests`.
