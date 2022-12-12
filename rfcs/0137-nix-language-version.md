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

Add a mechanism to determine which version of the Nix language grammar to use for parsing Nix files.

# Motivation
[motivation]: #motivation

Currently it's impossible to introduce backwards-incompatible changes to the Nix language without breaking existing setups.
This proposal is an attempt to overcome that limitation.

# Detailed design
[design]: #detailed-design

Introduce a magic comment in the first line of a Nix file:

    #? Nix <version>

where `<version>` is a released version of Nix the given file is known to work with.

It is left to the implementation how to use this information.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

```nix
#? Nix 2.12
"nothing"
```

# Advantages
[advantages]: #advantages

- Backwards compatible
- Visually unintrusive
- Self-describing and human-readable
- Opt-in until the feature is implemented in Nix *and* the first backwards-incompatible change to the language is introduced.
- Follows a well-known convention of using [magic numbers in files](https://en.m.wikipedia.org/wiki/Magic_number_(programming)#In_files)
- Encourages, but does not require the Nix evaluator to deal with backwards-incompatible changes in a principled manner.

# Drawbacks
[drawbacks]: #drawbacks

- The syntax of the magic comment is arbitrary.
- At least one form of comment is forever bound to begin with `#` to maintain compatibility.
- There is a chance of abusing the magic comment for more metadata in the future.
  Let's avoid that.
- It requires effort to implement an appropriate system to make use of the version information.

# Alternatives
[alternatives]: #alternatives

- Never introduce backwards-incompatible changes to the language.

  This is what has been happening so far, and required additions to be made very carefully.

- Use a different versioning scheme for the Nix language that is decoupled from the rest of Nix.

  Although this can be done at any point in the future, because it's the evaluator that will read this information.

- Use a magic string that is incompatible with evaluators prior to the feature, e.g. `%? Nix <version>`.

  This would make clear to users that the file is not intended to be used without explicit handling of compatibility.
  Such a breaking change could be reserved for later iterations of how Nix encodes language version information.

# Unresolved questions
[unresolved]: #unresolved-questions

- Is the proposed magic number already in use in [other file formats](https://en.m.wikipedia.org/wiki/Magic_number_(programming)#In_files)?
- Should we allow multiple known-good versions in one line?

# Future work
[future]: #future-work

Determine what exaclty to do with the information given in the magic comment.
