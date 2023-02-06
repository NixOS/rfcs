---
feature: private-derivations
start-date: 2023-02-03
author: poscat
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

This RFC proposes to add a special type of derivation called private derivation, which, upon being built, will have their file permissions set to 000/111 instead of the usual 444/555.

# Motivation
[motivation]: #motivation

In short: This RFC mainly concerns with how to safely manage credentials using nix (as opposed to using impure methods like manually copying them over) on NixOS.

The world readability of nix store means that, to safely store credentials, they must first somehow be encrypted before written into the store. They also need to be decrypted before the services are started.

This is less than ideal because one needs to setup a key (which is stored as plaintext on disk) on every machine just to prevent unauthorized users from seeting the credentials.

Furthermore, if encryption is done before the evaluation of the system configuration (as is the case with [agenix](https://github.com/ryantm/agenix) and [sops-nix](https://github.com/Mic92/sops-nix)), then the nixos module system cannot be utilized to generate configs that contain credentials and one must write them manually.

All of this can be prevented if we added the ability to make derivation outputs as not readable by anyone other than root, by setting the file mode to 111 (directories and executables) or 000 (regular files). We can then use a trustworthy credential manager, for example systemd with its `LoadCredential=`, to distribute these derivations to the consumers safely.

# Detailed design
[design]: #detailed-design

We propose adding a `noReadAccess` option to `builtins.derivation`, which, when set to true, makes this derivation a private derivation.

The only difference between a private derivation and a normal derivation, apart
from the hash, is that upon instantiation and after building, the read bit of
the `.drv` file and the output path will be removed.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

## Intended usage in NixOS modules
On NixOS there are many modules where configurations that might contain sensitive
information get written into nix store in plaintext (for example the wpa_supplicant module). Private derivations can solve this issue by

1. Writing a helper function `writeTextPrivate` that functions similar to
`writeText`, but instead outputs a private derivation
2. Replace the `writeText` function with `writeTextPrivate` inside the module
3. Use `LoadCredential=` to load the private derivation
4. Replace the derivation output path with `%d/<credName>` (see systemd.exec)

# Drawbacks
[drawbacks]: #drawbacks

- Adding private derivations further complicates the nix store model.

# Alternatives
[alternatives]: #alternatives

- Supporting more complicated ACLs as described in [this](https://github.com/NixOS/nix/issues/8) Nix issue.
- Storing private derivations in a separate store path, for example
  `/nix/private-store` that have its executable bit removed so that the hashes
  are not visible to non-root users.

# Unresolved questions
[unresolved]: #unresolved-questions

## Binary caches and copying
How do we prevent the attacker from using `nix copy` to simply copy out the
private derivation to another machine?

What changes are needed for binary cache providers such as `nix-serve` to handle
private derivations?

## Leaking metadata
The hash is still exposed to the attacker, which opens up some possible attacks.
How does this impact the security?

## Content-Addressed paths
It is not yet known how this might interact with content addressed paths.

# Future work
[future]: #future-work

What future work, if any, would be implied or impacted by this feature
without being directly part of the work?
