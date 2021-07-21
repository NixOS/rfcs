---
feature: commonmark-docs
start-date: 2020-07-05
author: mboes
shepherd-team: garbas, zimbatm, Kloenk
shepherd-leader: Infinisil
---

# Summary
[summary]: #summary

Nixpkgs and NixOS documentation is currently in Docbook format.
We propose to migrate all existing content to CommonMark, a flavour of
Markdown.

# Motivation
[motivation]: #motivation

Documentation ought to be easy to write, easy to maintain, easy to
make pretty, and its format be so boring as to seldom be the object of
future RFC's. But beyond that, the significance of the documentation
format is in its very real impact on the perception of the project.
Documentation is the storefront of any project online in addition to
its front page. Modern looking documentation that can be edited at the
click of a button sends a signal: that the Nix* projects are forward
looking, are welcoming to novice contributors and feel familiar.

The motivation to switch away from Docbook is that it's unfamiliar.
None of the [top 100 projects on Github][gitstar-rankings] use
Docbook. The motivation to switch to CommonMark is that among these
projects, roughly 10 times more projects use Markdown (or some
variation thereof) than all other documentation formats combined, it
can be considered the default. It's worth considering alternatives,
but the burden ought to lie with the proponents of other format/tool
combinations to convince this community that following the precedent
set by the overwhelming majority of communities larger than ours won't
work well for us.

Increasing the number of contributors to the documentation, increasing
its coverage and improving its quality are social goals, not technical
requirements. To recruit more writers and users, should we make
support for callouts, admonitions and a precise taxonomy (like Docbook
has) requirements? Should literate programming and the ability to do
transclusions also be requirements? Does reducing documentation build
times from seconds to milliseconds matter? Maybe meeting these
requirements helps us reach our social goals. Maybe they are
immaterial. What we can go by is the following piece of evidence:
nearly all of the most beautifully laid out, high-quality and
easy-to-navigate documentation in the GitHub Top 100 are in
CommonMark. The only notable exception is the [Tensorflow
documentation][tensorflow-docs], which uses Jupyter notebooks for
everything.

Consider the following 5 examples of great Markdown documentation in
terms of breadth, presentation and richness (cross references,
definition lists, tables, callouts, integration with playgrounds,
etc):

- [GatsbyJS documentation][gatsby-docs] (using Gatsby with [MDX][mdx])
- Facebook's [React documentation][react-docs] (using Gatsby with
  plain CommonMark)
- Microsoft's [VS Code documentation][vscode-docs] (using Jekyll)
- [Kubernetes documentation][kubernetes-docs] (using Hugo)
- The [Rust book][rust-docs] (using mdBook)

The goal of this RFC is to change the *form* of the current
documentation for Nixpkgs and NixOS to look similar to any one of
the above 5 projects (see requirements in the next section). We submit
that the least effort route to do so is to use the same toolchain as
they do (CommonMark or MDX input and one of Gatsby, Jekyll or Hugo to
generate a static site).

What all of the projects cited above have in common is a large
contributor base with heterogeneous skillsets and multiple
subcommunities. Just like in Nixpkgs, they cannot leverage the
hegemony of RST in Python, because not all their users are Python
programmers. They prefer not to count on writers learning Docbook or
Asciidoc, because many documentation patches are from casual
contributors. The *lingua franca* across subcommunities for both
humans and their toolchains is Markdown. It's all the more easy to
create good looking documentation with Markdown that the tools
available to process it are plentiful and flexible (JavaScript
converters with plugin support like [Remark][remark], [static site
generators][staticgen] by the dozen, [MDX][mdx] to extend CommonMark
with arbitrary React components, etc).

[gatsby-docs]: https://www.gatsbyjs.org/docs/
[gitstar-rankings]: https://gitstar-ranking.com/repositories
[kubernetes-docs]: https://kubernetes.io/docs/home/
[react-docs]: https://reactjs.org/docs/getting-started.html
[rust-docs]: https://doc.rust-lang.org/book/
[tensorflow-docs]: https://github.com/tensorflow/docs
[vscode-docs]: https://code.visualstudio.com/docs
[mdx]: https://github.com/mdx-js/mdx
[remark]: https://remark.js.org/
[staticgen]: https://www.staticgen.com/

# Detailed design
[design]: #detailed-design

## Documentation website requirements

AsciiDoc, CommonMark and RST are all formats that support basic
markup: emphasis, bold, (nested) (un)numbered lists, headings, inline
and display code, tables (using a CommonMark extension), etc. The
requirements we set below pertain to the appearance of the
documentation available on the website.

The key requirements we work towards are:

1. easy-to-find "Edit on GitHub" button to increase drive-by
   contributions,
1. good quality documentation search engine,
1. syntax highlighting of all code,
1. separate page per chapter, instead of the current monolithic page
   for each manual,
1. table of content for each chapter available in a side bar to easily
   jump through long content,
1. make warning and info boxes stand out from the rest of the content
   with colour,
1. easy to customize HTML and CSS, since tired old templates we've all
   seen too many times are best avoided. The objective is to make
   a statement to newcomers that the community takes documentation
   seriously, with both good form and good content.

## Choice of format

Satisfying all requirements above is possible with a number of
toolchains, including Asciidoc-specific or RST-specific toolchains
(not just Markdown). We propose CommonMark plus a small number of
extensions as the documentation format. The choice of toolchain is
left at the discretion of the implementers. We feature two demos below
(one uses [Gatsby][gatsby] and another uses [Sphinx][sphinx]).

The choice of CommonMark extensions is also left to the implementors.
However, this RFC stipulates the following guidelines:

* The overall number of extensions should be kept small, to facilitate
  interoperability. The goal is not perfect compliance with a standard
  (i.e. pure CommonMark), but it should nonetheless remain easy to
  switch from one toolchain to another for generating HTML from the
  CommonMark source, with minimal manual work. For example,
  * enabling an extension for tables is acceptable because few tables
  appear in the documentation and converting them by hand to a new
  format is not labour intensive;
  * YAML frontmatter for metadata is also acceptable, because nearly
    all toolchains support this.
* An extension for defining references between section should be
  supported, since this is widely used in the current manuals and
  essential for navigating around.
* CommonMark allows HTML span and block elements. These should be
  avoided in documentation source, because this complicates targeting
  multiple output formats (e.g. man pages, epub, etc).

## Transition to CommonMark

The one-time conversion from Docbook to CommonMark is lossy, because
CommonMark has far less expressive markup. It is done using
[Pandoc][pandoc], which has a reader available for Docbook and
a high-quality writer available for CommonMark. The Pandoc Docbook
reader isn't perfect, but in the process of putting together the quick
demo below, it was easy to fix 5 bugs already.

We propose to convert man pages to CommonMark as well. However, this
transition need not happen concurrently to the format transition for
the rest of the documentation. They are self-contained documents,
whose form is constrained by convention and the limits of the man page
format. When the time comes to convert the man pages as well, we can
turn here again to prior art. The Kubernetes project uses
[md2man][md2man] to generate man pages from CommonMark. This is
a small Go command with a 4.1MB closure size (including 2MB for
`tzdata`).

[gatsby]: https://gatsbyjs.org
[sphinx]: https://www.sphinx-doc.org
[pandoc]: https://pandoc.org/
[md2man]: https://github.com/cpuguy83/go-md2man

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

This RFC is *not* about vetting a single implementation choice. The
five large projects cited above use one of Hugo, Gatsby, Jekyll, or
mdBook. We can add Sphinx to the set of available implementation
choices, which likewise has excellent support for Markdown. In this
section we show how two of these choices could work in the context of
the Nix* projects. *Selecting a toolchain is left to the discretion of
the implementors. Discussing implementation choices that are
transparent to the user is out of scope for an RFC process*.

The following demo shows how to satisfy all requirements above using
CommonMark as the input format and a Gatsby-based [starter kit from
Hasura][hasura-docs-starter] to generate a ready-to-deploy static
website:

https://nixos-docs-mockup.netlify.app

It features the following sections of the Nix manual:
* introduction
* quickstart and installation
* the Nix expressions chapter
* advanced topics

The content is the unedited output of running the Pandoc conversion,
which still has bugs (in particular the handling of cross-references).

This other demo shows how to satisfy many of the same requirements
using Sphinx, again with CommonMark as the input:

https://nixpkgs-manual-sphinx-markedown-example.netlify.app

The look and feel is customizable, and indeed could be made the same
in both cases. Both are examples meant to demonstrate that choosing
CommonMark as the input format doesn't force unreasonable compromises.

[hasura-docs-starter]: https://github.com/hasura/gatsby-gitbook-starter

# Drawbacks
[drawbacks]: #drawbacks

The current DocBook format is semantically richer. There are specific
tags for definitions, environment variables, user accounts, various
types of callouts, etc. CommonMark's data model isn't nearly as rich,
so in converting to CommonMark, even with extensions, some information
is lost. However, experience in other very large ecosystems with many
users tells us that authors are happy to make do with an inexpressive
but familiar format, which in any case *can* be extended with the wise
use of `<span>`-like HTML tags and custom tags that expand to HTML.
That appears to be seldom necessary in practice (see e.g. the five
documentation examples in [Motivation][motivation]).

# Alternatives
[alternatives]: #alternatives

Other formats share the desirable properties of the various flavours
of Markdown (of which CommonMark is but one):

- textual format that is easy to diff,
- reuses familiar conventions from decades of plain text emails,
- terseness of the markup and consistent levels of indentation.

The main two other contenders are AsciiDoc and RST. There are
technical reasons to prefer either of them to CommonMark, despite
social factors in favour of CommonMark.

## AsciiDoc

AsciiDoc has the same data model as Docbook - just a different syntax.
This makes the two formats interchangeable in principle. The markup
language is arguably better designed than CommonMark and is more
expressive. However, AsciiDoc is not as precisely specified as
CommonMark. It has only two extant toolchains ([Asciidoc][asciidoc]
and [Asciidoctor][asciidoctor]) for transforming into HTML, one of
which is infrequently maintained (3 releases in 7 years). In the top
100 projects on GitHub, only one project uses Asciidoc for their
documentation format.

Asciidoc is also effectively a format transformer dead-end:
round-tripping via Docbook using `asciidoc` and `docbookrx` doesn't
work and Pandoc does not support Asciidoc as an input.

[asciidoc]: https://asciidoc.org/
[asciidoctor]: https://asciidoctor.org/

## reStructuredText

Pros:

- reStructuredText (RST) has wider adoption than Asciidoc.
- Most Python projects use it. The Python ecosystem is deep and wide.
- Good and mature toolchains like Sphinx exist to process RST files.

Cons:

- the syntax for simple things like links or inline code is
  non-standard. Inline code requires double backticks, but single
  backticks is legal syntax and used for links, so it's easy to get
  things wrong that don't lead to build errors.
- RST constructs do not compose nearly as well as they should. What is
  trivial in CommonMark is impossible in RST. For example, links with
  inline code in the title are not expressible. Links with italics in
  the title are not expressible either. In general, inline markup does
  not concatenate well. Backslashes are required in common constructs
  like the following:
  ```
  Python ``list``\s use square bracket syntax.
  This is a long\ *ish* paragraph
  ```
- nesting block elements suffers from gotchas (like [this
  one][rst-nested-lists]).

[rst-nested-lists]: https://stackoverflow.com/questions/44557957/unexpected-indentation-with-restructuredtext-list

## Are they popular?

The extra expressiveness of Asciidoc or RST over CommonMark was not
deemed to be a crucial requirement by many other large projects. In
the GitHub Top 100 (projects ranked by number of stars), only one
project (Spring Boot) uses Asciidoc, and only two projects (Ansible
and Linux) use RST other than the predominantly Python projects. Swift
uses a mix of RST and Markdown, what with being in the middle of
a transition to full Markdown (grep for `[Gardening] De-RST` in [the
history][swift-docs-history]).

[swift-docs-history]: https://github.com/apple/swift/tree/master/docs

# Unresolved questions
[unresolved]: #unresolved-questions

We propose to take CommonMark as a baseline. This is sufficient to
support all the markup we need. It's also a stepping stone towards
[MDX][mdx], which enables embedding custom widgets if so desired. For
example, Gatsby uses MDX to include newsletter signup forms, embed
videos from third-party training websites, or to generate
documentation sitemaps within a section (e.g. the bottom of [this
page][gatsby-graphql]). It's unclear that custom widgets are worth the
trouble at this stage.

The choice of toolchain to publish the documentation on the website
and as man pages is left open.

[gatsby-graphql]: https://www.gatsbyjs.org/docs/graphql/

# Future work
[future]: #future-work

- Build out the documentation demo above into a full replacement for
  each of the Nix, Nixpks and NixOS user manuals online.
- Fix all Pandoc bugs encountered along the way, in particular to get
  working cross-references.
- Customize the CSS and layout of the demo to be more in line with Nix
  branding.
- Integrate the result into the Nix and Nixpkgs repositories and hook
  into their respective CI/CD pipelines.
