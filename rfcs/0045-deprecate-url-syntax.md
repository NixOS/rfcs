---
feature: deprecate_url_syntax
start-date: 2019-04-28
author: Michael Raskin
co-authors: 
shepherd-leader: Eelco Dolstra
shepherd-team: Eelco Dolstra, zimbatm, Silvan Mosberger
related-issues:
category: feature
---

# Summary
[summary]: #summary

Discourage and eventually remove the use of unquoted URL syntax in Nix code and especially
Nixpkgs.

# Motivation
[motivation]: #motivation

The Nix language has a special syntax for URLs even though quoted strings can also be used to represent them. Unlike paths, URLs do not
have any special properties in the Nix expression language
that would make the difference useful.
Moreover, using
variable expansion in URLs requires some URLs to be quoted strings anyway. So
the most consistent approach is to always use quoted strings to represent URLs.
Additionally, a semicolon immediately after the URL can be mistaken for a part
of URL by language-agnostic tools such as terminal emulators.

Tools
targeting only Nixpkgs codebase can ignore URL syntax once Nixpkgs phases out
its use.

# Detailed design
[design]: #detailed-design

Add a note in the Nix manual that the special unquoted URL syntax is
discouraged and may be removed in a future edition of the Nix language.

Add a note in the Nixpkgs manual that the unquoted URL syntax should not be used anymore.

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

Currently none.
