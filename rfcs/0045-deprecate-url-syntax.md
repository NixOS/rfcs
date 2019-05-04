---
feature: deprecate_url_syntax
start-date: 2019-04-28
author: Michael Raskin
co-authors: 
related-issues: 
---

# Summary
[summary]: #summary

Gradually deprecate the use of unquoted URL syntax in Nix code and especially
Nixpkgs.

# Motivation
[motivation]: #motivation

The Nix language has a special syntax for URLs even though quoted strings can also be used to represent them. Unlike paths, URLs do not
have any special support that would make the difference useful. Moreover, using
variable expansion in URLs requires some URLs to be quoted strings anyway. So
the most consistent approach is to always use quoted strings to represent URLs.
Additionally, a semicolon immediately after the URL can be mistaken for a part
of URL by language-agnostic tools such as terminal emulators.

In case of future breaking changes in the Nix syntax, it would be nice to make
the `x:x` snippet parse to the identity function, and not to an URL. Tools
targeting only Nixpkgs codebase can ignore URL syntax once Nixpkgs phases out
its use.

# Detailed design
[design]: #detailed-design

Add a note in the Nix manual that the special unquoted URL syntax is
deprecated.

Add a note in the Nixpkgs manual that the unquoted URL syntax is deprecated,
changes to Nixpkgs should not increase its use, and it is recommended to
convert URLs to quoted strings when changing them.

Convert all the unquoted URLs in the Nixpkgs codebase to quoted strings.

Add an ofBorg check that verifies that no new unquoted URLs have been added in
a PR.

# Drawbacks
[drawbacks]: #drawbacks

This is a minor cosmetic issue (and maybe a very minor readability issue) which
might not be worth making a specific decision.

# Alternatives
[alternatives]: #alternatives

* Do nothing; get PRs from time to time that make homepages uniformly quoted
  strings or uniformly unquoted.

* Decide to use unquoted URLs for all URLs without special characters or
  variable expansion.

# Unresolved questions
[unresolved]: #unresolved-questions

Currently none.

# Future work
[future]: #future-work

In case of future major changes in the Nix syntax, removal of special URL
syntax might be considered.

Explore options for automated tracking of the number of unquoted URLs in 
Nixpkgs.
