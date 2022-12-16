---
feature: nix-language-version
start-date: 2022-12-12
author: @fricklerhandwerk
co-authors: @thufschmitt @Ericson2314
shepherd-team: 
shepherd-leader: 
related-issues: https://github.com/NixOS/nix/issues/7255
---

# Summary
[summary]: #summary

Introduce a convention to determine which version of the Nix language grammar to use for parsing a Nix file.

# Motivation
[motivation]: #motivation

Currently it's impossible to introduce backwards-incompatible changes to the Nix language without breaking existing setups.
This proposal is first step towards overcoming that limitation.

# Detailed design
[design]: #detailed-design

Introduce a magic comment in the first line of a Nix file:

    #? Nix <version>

where `<version>` is a released version of Nix the given file is intended to work with.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

```nix
#? Nix 2.12
"nothing"
```

# Arguments
[advantages]: #advantages

* (+) Makes explicit what can be expected to work.
* (+) Enables communicating language changes systematically.
* (+) Backwards-compatible
  * (+) Allows for gradual adoption: opt-in until semantics is implemented in Nix *and* the first backwards-incompatible change to the language is introduced.
* (+) Visually unintrusive
* (+) Self-describing and human-readable
* (+) Follows a well-known convention of using [magic numbers in files](https://en.m.wikipedia.org/wiki/Magic_number_(programming)#In_files)
* (-) May make the appearance that changing the language is harmless.
  * (+) The convention itself is harmless and independent of the development culture around the language.
* (-) The syntax of the magic comment is arbitrary.
* (-) There is a chance of abusing the magic comment for more metadata in the future. Let's avoid that.
* (-) At least one form of comment is forever bound to begin with `#` to maintain compatibility.
* (-) It requires significant additional effort to implement and maintain an appropriate system to make use of the version information.

# Alternatives
[alternatives]: #alternatives

- Never introduce backwards-incompatible changes to the language.

  * (+) No additional effort required.
  * (-) Requires additions to be made very carefully.
  * (-) Makes solving some well-known problems impossible.

- Use the output of [`builtins.langVersion`] for specifying the version of the Nix language.

  * (+) This would serve other Nix language evaluators which are not and should not be tied to the rest of Nix.
  * (-) `builtins.langVersion` is currently only internal and undocumented.
    * (+) Documentation is easy to add.
      * (-) Requires adding another built-in to the public API.
    * (-) Using a language feature requires an additional steps from users to determine the current version.
      * (+) We can add a command line option such that it is not more effort than `nix --version`.
        * (-) Requires adding another command line option to the public API.
  * (+) The Nix language version is decoupled Nix version numbering.
    * (+) It changes less often than the Nix version.
      * (-) That was probably due to making changes being so hard.
    * (-) There are two version numbers to keep track of.
  * (-) The magic comment should reflect that it's specifying the *Nix language* version, which would make it longer.
    * (-) Renaming the Nix language will be impossible once the mechanism is part of stable Nix.

[`builtins.langVersion`]: https://github.com/NixOS/nix/blob/26c7602c390f8c511f326785b570918b2f468892/src/libexpr/primops.cc#L3952-L3957

- Use a magic string that is incompatible with evaluators prior to the feature, e.g. `%? Nix <version>`.

  * (+) Makes clear that the file is not intended to be used without explicit handling of compatibility.
    * (-) Cannot be introduced gradually.
  * (+) Such a breaking change could also be reserved for later iterations of the Nix language.

# Prior art

- [Rust `edition` field]

  Rust has an easier problem to solve. Cargo files are written in TOML, so the `edition` information does not have to be part of Rust itself.

- [Flakes `edition` field]

  There had been an attempt to include an `edition` field into the Flakes schema.
  It did not solve the problem of having to evaluate the Nix expression using *some* version of the grammar.

[Rust `edition` field]: https://doc.rust-lang.org/cargo/reference/manifest.html#the-edition-field
[Flakes `edition` field]: https://discourse.nixos.org/t/nix-2-8-0-released/18714/6

# Unresolved questions
[unresolved]: #unresolved-questions

- Is the proposed magic number already in use in [other file formats](https://en.m.wikipedia.org/wiki/Magic_number_(programming)#In_files)?
- Should we allow multiple known-good versions in one line?

# Future work
[future]: #future-work

- Define semantics, that is, what exactly to do with the information given in the magic comment.
- Define rules deciding when a change to the language is appropriate to avoid proliferation and limit complexity of implementation.
