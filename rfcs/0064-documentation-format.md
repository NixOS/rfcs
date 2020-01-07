---
feature: documentation-format
start-date: 2019-12-31
author: Silvan Mosberger (infinisil)
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

The Nix community wants to move away from using Docbook as our documentation format and replace it with something else. However it is unclear what it should be replaced with. This RFC gives a concrete process for determining the new documentation format. It does NOT say what format should be used.

# Motivation
[motivation]: #motivation

The current format for documentation of NixOS projects is DocBook. The format has been a discussion for many years for multiple reasons.
This RFC describes a method for deciding on what format to use, and should allow us to decide on a format for the coming years, and improve our documentation situation.

# Detailed design
[design]: #detailed-design

The process for determining the doc format is as follows:
- A set of requirements for the doc format is decided through the RFC discussion
- Doc format candidates are collected and evaluated to see if they fulfil the requirements.
- A short objective overview of each valid candidate format is written, along with their advantages/disadvantages
- The RFC is accepted
- A [Discourse](https://discourse.nixos.org/) post is created with these overviews, along with a poll such that people can vote on the formats they prefer. This poll will be open to the whole community and should be advertised as such
- Whatever format wins in the poll is chosen as the new default documentation format. If later it is discovered that the winner is infeasible for any reason, e.g. if it doesn't meet the requirements after all, the format on second place is chosen instead, and so on.

## Poll

The poll is of the following form:
- Multiple-choice, allowing people to select all formats they agree with
- Results are only shown when the poll is closed for it to not be influenced by non-final tallies
- Answers can be changed while the poll is still active, allowing people to discuss about formats and change their opinion (this is not optional in Discourse)
- It runs for 1 month to give enough time for less-active people to see it
- Who voted for which options is made public (Only possible with bar chart in Discourse) TODO: Do we want this or not? Why would we?

## Requirements

- Can be converted to HTML and man pages
- Inter-file references for being able to link to options from anywhere
- Ability to create link anchors to most places such that we can link to e.g. paragraphs
- Widespread editor integration featuring at least highlighting and preferably live-view
- Good error detection in toolchain and editors, e.g. with a fast and good processor
- Is decently fast to fully generate, in the range of 10 seconds for the full documentation on an average machine
- Closure-size of toolchain should be [small](https://github.com/NixOS/nixpkgs/issues/63513).
- Supports syntax highlighting (with Nix support)
- Active community supporting the tooling infrastructure
- Good conversion story from Docbook

### Nice-to-have's

- Annotations/links inside code listings for e.g. linking to option docs in `configuration.nix` snippets
- Ability to make `$ `, `nix-repl>` and other prompts in command line snippets non-copyable
- Good search integration, e.g. by providing a well-functioning search field

## Format overviews

Should contain for each format:
- A short description
- Noteworthy advantages/disadvantages
- Links to tutorials, documentation and tooling
- A short sample

### Markdown (CommonMark)

Markdown is probably the most well-known markup language, used for discussions on many websites such as GitHub, StackExchange, Reddit, Bitbucket and more. While the original description of Markdown was ambiguous, in current times [CommonMark](https://commonmark.org/) provides a clear specification for it. Markdown is designed to be easy to read and write. If you don't know it already, just after a [one minute tutorial](https://commonmark.org/help/) you can be productive with it.

Links:
- [The latest CommonMark specification](https://spec.commonmark.org/current/)
- [Pandoc](https://pandoc.org/) can convert from/to Markdown to/from many other formats
- [Sphinx](https://www.sphinx-doc.org/), a popular documentation generator, known for its [readthedocs](https://readthedocs.org/) pages supports Markdown

#### Why CommonMark instead of another Markdown flavor?
- CommonMark is very near to having a 1.0 release for a standardized and unambiguous syntax specification for Markdown
- The popular Sphinx documentation generator [supports CommonMark](https://www.sphinx-doc.org/en/master/usage/markdown.html) (in addition to reStructuredText)
- GitHub's Markdown is [a strict superset of CommonMark](https://github.blog/2017-03-14-a-formal-spec-for-github-markdown/) and they are committed to having full CommonMark conformance

### reStructuredText

[reStructuredText (reST)](https://en.wikipedia.org/wiki/ReStructuredText) is a file
format originally developed as part of the Docutils project for documenting the Python language.
Since then, support was added for reST to Sphinx, a popular tool for documenting (Python) projects, and pandoc.

With Sphinx it is possible to document various languages using the concept of [domains](https://www.sphinx-doc.org/en/master/usage/restructuredtext/domains.html). E.g., if we were to have a format for documenting Nix functions, we could implement a domain in Sphinx, as well as a parser that could parse Nix functions from comments and convert them to the Sphinx domain, as is done currently with the [Nixpkgs library](https://github.com/NixOS/nixpkgs/pull/53055).

Language:
- [Specification](https://docutils.sourceforge.io/docs/ref/rst/restructuredtext.html)
- [Primer](https://www.sphinx-doc.org/en/master/usage/restructuredtext/basics.html)
- [Demo](https://docutils.readthedocs.io/en/sphinx-docs/user/rst/demo.html)

Tooling:
- [Sphinx](https://www.sphinx-doc.org/)
- [Docutils](https://docutils.sourceforge.io/)
- [Pandoc](https://pandoc.org/) can convert from/to reST to/from many other formats

Examples of users:
- Python
- Linux kernel
- CMake
- Majority of Python packages

### Asciidoc

TODO: Short overview

[Demo](https://github.com/opendevise/asciidoc-samples/blob/master/demo.adoc)

Tooling:
- [Antora](https://antora.org/)
- [Asciidoctor](https://asciidoctor.org/)

### Texinfo

TODO: Short overview

Powerful, interactive and very nice to use (check out `pinfo`), but harder to write.

### Nix EDSL

With a Nix EDSL, linking to options can become trivial and very natural. Users won't have to learn another language either. Docs could also be written directly next to the thing they document with some convenience functions for annotating values with docs.

### Docbook

TODO: Short overview

[Primer](https://docbook.rocks/)

### Comparisons

| Format | Rendered in GitHub | Adoption | Standardized | Goal |
| --- | --- | --- | --- | --- |
| Markdown | Yes | Great among websites | No | Easy to use |
| reStructuredText | Yes | Great among tech docs | Yes | Easy to use, customizable |
| Asciidoc | Yes | ? | Yes | Easy to use, customizable |
| Docbook | No | ? | Yes | Semantic structure |

Cheatsheet comparison: http://hyperpolyglot.org/lightweight-markup

- Linux kernel, why Sphinx/reStructuredText (2016): https://lwn.net/Articles/692704/
- Why not Markdown: https://mister-gold.pro/posts/en/asciidoc-vs-markdown/

TODO: More online comparisons?

### Comparison of tools

For the following comparison NixOS 19.09 is used.

| Name         | Attribute             | Closure size |
|--------------|-----------------------|--------------|
| Sphinx       | `python3.pkgs.sphinx` | 195 MB       |
| Pandoc       | `pandoc`              | 2.4 GB       |
| Asciidoctor  | `asciidoctor`         | 1.0 GB       |

# Drawbacks
[drawbacks]: #drawbacks


# Alternatives
[alternatives]: #alternatives


# Unresolved questions
[unresolved]: #unresolved-questions


# Future work
[future]: #future-work

