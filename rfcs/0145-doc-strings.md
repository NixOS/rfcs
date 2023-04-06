---
feature: doc-comment-standard
start-date: 2023-03-27
author: hsjobeki
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Propose a standard format for Doc-comments.

# Motivation
[motivation]: #motivation

The following are the envisioned goals

- be able to generate documentation from code for any nix expression.
- be able to distinguish between documentation-relevant comments and unrelated comments.
- make doc comments easy to write and read
- be able to parse and render doc comments nicely
- standardize a format for doc comments that can be extended by further RFCs

This RFC is a significant change to the existing documentation convention
but allows to distinguish between regular comments and doc comments. This is important because arbitrary code comments should not end up in generated documentation.

> Hint: Generating static documentation is controvert topic in nixpkgs. It was found that is impossible to generate accurate documentation statically. A correct solution would involve evaluation of expressions in some way. This already goes deeply into implementation details and is thus not further discussed in this document. Although we envision solutions to solve this issue.

## Current State

We currently utilize a `doc-comment`-like functionality to build a subset of static documentation for nix functions. (e.g., nixpkgs.lib documentation via: [nixdoc](https://github.com/nix-community/nixdoc))
Many inconsistently written comments document specific parts of nixpkgs and other nix-frameworks (see [references-to-this](#references-to-the-problems-above)).

We use some of them to generate documentation automatically. (e.g., nixpkgs/lib via [nixdoc](https://github.com/nix-community/nixdoc) )

This solution requires a lot of handworks; more specifically, *nixdoc* is a custom tool that works only for that purpose.

Here is an example of the format understood by *nixdoc*:

```nix
# nixpkgs/lib/attrsets.nix

{
  /* <Description Field>
     Example:
     <Comprehensive Code example>
     Type:
     <Type signature>
  */
  AttrFunc =
    # <Desribe arg1>
    arg1:
    # <Describe arg2>
    arg2:
    
    # ... implementation
}
```

## Current problems

### Inconsistent usage outside /lib folder

Those comments are only used and parsed consistently in the /lib folder. Outside of this folder the format doesn't follow the convention strictly. Also the comments outside /lib are not used to generate any output.

### Unspecified format

In general, the format for writing documentation strings is **not specified**.

The *nixdoc*-tool enforces a somewhat consistent format but the actual format was never specified and is not enforced in parts of nixpkgs where nixdoc is currently not applied.

Extending the scope of *nixdoc* is not the primary goal. Instead, we should find formal rules for writing *doc-comments*. Tools like *nixdoc* can then implement against this RFC instead of the format relying on nixdoc implementation details.

### Only specific placements work

The placement of those comments requires precisely commenting at the attribute set containing the function declarations, which is not usable for general-purpose documentation strings.

e.g.,

- file that directly exports the lib-function without wrapping it in an attribute set.
- file that exports a constant expression
- files outside of lib cannot be rendered due to missing conventions

### Differentiate from regular comments

The format doesn't allow any distinction between doc-comments or regular comments.

Having a distinction would allow us to

1. Find all comments that are part of the documentation
2. Render them in the documentation format
3. Connect the documentation to the exact places in the nix code. This is already done, but only for nixpkgs/lib.

### References to the problems above

#### nixpkgs - Dosctrings examples

- [lib/attrsets](https://github.com/NixOS/nixpkgs/blob/master/lib/attrsets.nix)
- [trivial-builders](https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/trivial-builders.nix)
- [stdenv/mkDerivation](https://github.com/NixOS/nixpkgs/blob/master/pkgs/stdenv/generic/make-derivation.nix)
- [nixos/lib/make-disk-image](https://github.com/NixOS/nixpkgs/blob/master/nixos/lib/make-disk-image.nix)
- more...

#### frameworks

- [dream2nix/utils](https://github.com/nix-community/dream2nix/blob/main/src/utils/config.nix)
- [dream2nix/templates/builder](https://github.com/nix-community/dream2nix/blob/main/src/templates/builders/default.nix)
- more... 

#### Other tools

Other tools that work directly with the nix AST and comments:

- [noogle](https://noogle.dev) - Nix API search engine. It allows to search functions and other expressions.
- [nix-doc](https://github.com/lf-/nix-doc) - A Nix developer tool leveraging the rnix Nix parser for intelligent documentation search and tags generation
- [manix](https://github.com/mlvzk/manix) - A fast CLI documentation searcher for nix.

# Detailed design
[design]: #detailed-design

**Proposed Solution:**

Use `##` For doc-comment body and markdown within

The content of all doc-comments is rendered using markdown.
Following the [commonmark-specification](https://spec.commonmark.org/)

## Doc-comments

The following exampple demonstrates the concrete usage scenario.

### A doc-comment referencing the subsequent expression

`somefile.nix`

```nix
{
  ## <Description or Tagline>
  ## Documentation for 'mapAttrs'
  ## 
  ## # Example
  ##
  ## <Comprehensive code>
  ## 
  ## # Type
  ##    
  ## <Type Signature>
  mapAttrs = f: s: <...>;
}
```

## Format Rules

The following abstract rules describe how to write doc-comments.

### doc-comments are all comments. That start with `##` e.g. `## {content}`

```nix
## Documentation
## follows simple rules
## and can span multiple lines
```

### Doc-comments always document / relate to an expression

In detail: `##` relates to the next AST-Node. However technical details for tracking names and aliases is not part of this document.

> Vision: Implement a custom evaluator that specializes in tracking references of doc-comments within the nix expression tree. This is however a technical concrete solution that may be build after this rfc is accepted.

### Doc-comments start with `##`

Doc-comments start with `##` (leading whitespaces are allowed).

Doc-comments relate to the expression in the following line or, more precisely, to the next node in the AST.

The docstring is continued in the following line if it also starts with `##`.
Leading whitespace is allowed.

Example: docstring continuation

```nix
## doc-comment A
##  ....
## This block has no expression in the following line. 
## Therefore, it doesn't have any effect
##  ....
## doc-comment A


## doc-comment B
## -- This block documents the purpose of '1'
## doc-comment B
1
```

It is common using the same indentation as the referenced expression.

```nix

```

### The content of a doc-comment is Markdown

The content of a doc-comment is parsed using Markdown following the commonmark specification. Thus it allows for intuitive usage without knowledge of complex syntax rules.

Top level H1 headings, starting with a single `#`, indicate sections. Some of which might be specified in future rfcs.

Common Sections:

- `# Examples`
- `# Type`

Sections that might be specified in future rfcs:

- `# Type`
- `# Arguments`
- `# Meta`

Until they are actually specified.

Future RFCs may specify sub-headings of `# Meta`. Its usage is reserved.

## Keywords
[keywords]: #keywords

The following keywords start reserved markdown sections

> I wanted to keep the list of initial keywords short. So by the time this RFC focuses on the formal aspects of doc-comments first. More keywords and features for them may be added later on.

| Keyword     |  Description  | Note |
| ---         |  ---          | --- |
| `# Examples`   | Starts the Example-block. Often contains comprehensive code examples | |
| `# Type`      | Start the Type-block; Just any free text; but we recommend following the existing convention of the current `Type:` field | Syntax may eventually be specified in the future. |
| `# Meta`   | Under this section future rfcs may specify their sub-sections. | Sub-sections within meta will avoid namespace collisions in future RFCs |
| `# Arguments`   | Needed for describing the functions arguments. Is just any free text until specified | |

## Why change the existing section specifiers?

First, there are no actual block specifiers within nix or nixpkgs. The existing blocks heavily depend on a tool called `nixdoc` and not vice versa.

> `nixdoc` MUST be changed to support this RFC. (See [Future work](#future-work))

The sequence `Example:` has some drawbacks when it comes to syntax:

1. It is possible that this sequence occurs in a natural text without the intention to start a new doc-comment section.
2. It doesn't visually stand out.
3. It is terrible that the line needs to start with `Example:` to be valid syntax. However, it is a good practice while writing comments; it should be optional.
4. It neither follows the `@param` (c/c++/java,...) convention nor the markdown headings convention (rust); instead is nixdoc-home-cooked.

## Interactions

doc-comments can be attached to AST nodes without affecting the actual compile-, evaluation- or build-time because they are just comments. Specialized tools can handle those comments and create static documentation from them. Also, integration with LSP is possible. (See [@flokli's nix lsp-whishlist](https://hackmd.io/@geyA7YL_RyiWJO6d5TbC-g/Sy6lVrgW3) for inspirations)

Following this RFC means refactoring for existing comments, but it also means that **we can finally use all comments (automated!) that were intended to be doc-comments**

# Drawbacks
[drawbacks]: #drawbacks

Drawbacks of this rfc.

- Changes the existing comments inside the code base.

This could mostly be automated. (e.g via codemod)

Also, this affects only the `lib` folder and a few other places that are currently used to build the documentation.

# Alternatives
[alternatives]: #alternatives

While designing this RFC multiple alternative formats where considered. They can be found in the following section to understand the overall decisions that where made in the sections earlier.

In general, we needed the following:

1. General format for doc-comments.
2. Format for headings and the allowed content.

> It would be nice if this could be close to the markdown format.
> Markdown is the most straightforward and most accepted format
> for writing and rendering documentation.

## General Formats

| Property / Approach | `##` | `/** */` | `Javadoc` |
|---|---|---|---|
| Inspired by | Rust | Current nixpkgs.lib | C++/Java/Javascript |
| Changes the existing code by | Much | Less | Even More |
| Needs Termination | No | Yes | Yes |
| Indentation | Clear | Poor | Poor |
| Needs vertical space  | No | Yes | Yes |
| Visual distinction from comments | High | Low | Medium |
| Needs Autocompletion (Language Server) to continue the next line. | Yes | No | Yes |
| Punctuation Variations / Amount of different special characters | Less | More | More |
| Markdown compatibility (also depends on indentation clarity) | Good, but visual conflicts with headings` #` | Poor | Medium |
| breaks when interrupted with newlines | Yes | No | ? |

**Proposed format:**

Use `##` to start a doc-comment. This allows clear visual separation from regular comments.
And provides a good compatibility with the strived markdown content.

### Refactoring note

nixpkgs comments:

- `##` ~4k usages (most of them are used for visual separation e.g. `###########`)
- `#` ~20k usages
- `/*` ~6k usages
- `/**` 160 usages (most of them are completely empty ?)

## General Headings

| Property / Approach | `# <Heading>` | `@<Heading>:` |
|---|---|---|
| Inspired by | Markdown | Doxygen |
| Changes the existing code by | Minor | Minor |
| Needs vertical space  | Recommended | No |
| Visual distinction from comments | Low | High |
| Markdown compatibility | Best | None |

**Proposed headings:**

Use markdown headings `# <Heading>`. This allows best compatibility with the already specified markdown/commonmark format. Allowing for easy and intuitive usage for comments.

## Consequences to not implementing this

- By not implementing this feature, nix gains no ability for tool-generated documentation.
- Documentation will not defined by nixdoc, instead the community-implementation solution to the standard.

## Examples

This section contains examples for the different formats to visualize them and emphasize the previously discussed characteristics.

### `##` inspired from rust's `///` 

with `Markdown` Headings

`somefile.nix`

```nix
    ## <Description or Tagline>
    ## 
    ## # Example
    ##
    ## <Comprehensive code>
    ## 
    ## # Type
    ##    
    ## <Type Signature>
    mapAttrs = f: s: #...
```

### `/** */` inspired by the current multiline strings 

With `@{keyword}:` Headings

```nix
    /** 
        <Description or Tagline>
     
        @Example:
    
        <Comprehensive code>
     
        @Type:
        
        <Type Signature> 
    */
    mapAttrs = f: s: #...
```


## Javadoc style

```java
  /**
    * A short description
    * @author  Stefan Schneider
    * @version 1.1
    * @see    https://some.url
    */
    public class Product {
     ...
    }
```

## Alternative approach - just comments

There is the idea from python that doc-comments are just strings, not even special ones. Strings will be docstrings if they follow specific placement rules. However, we thought this was a bad idea to follow. Such complex placement rules require the users to understand where those places are; with nix syntax, this is slightly more complex than with python. Because we don't have keywords such as `class MyClass():` or `def function():` where placement would be obvious

# Unresolved questions
[unresolved]: #unresolved-questions

- `nixodc` offers comments to describe function arguments. This is currently not compatible until some sections for `args` are defined.

- Will `nix` itself implement native support like in rust -> `cargo doc`

- How can a tool keep the connection from where a docstring was defined and where the attribute was exposed (lib/default. nix exposes mapAttrs which is defined at lib/attrsets.nix)
  - There are more complicated things.

-> Answer: A Tool might be able to keep track of a percentage of expressions, and sometimes it may be very hard or impossible. For that case, the doc-comment can offer a dedicated Keyword to override the scope.

e.g.

The following is an idea for a problem that will arise if tools try to track doc-comments' positions and the location in the nixpkgs tree. (Although this problem is not nixpkgs specific)

```nix
#| This file is called somewhere that cannot be automatically tracked/is impossible to analyze statically.
#| The 'TreePath' override can be used by the docstring author to set a fixed path in the nixpkgs expression.
#| (This behavior will not be specified in this RFC)
#| @TreePath: pkgs.stdenv 

{...}:
{
    # returns something
}
```

# Future work
[future]: #future-work

## Editor support

When starting hitting {enter} inside a doc-block the new line, should be automatically prefixed with `##` or `#|` accordingly.
This is done in rust similarly. Nix already offers a bunch of LSP's e.g. [nil](https://github.com/oxalica/nil), [rnix-lsp](https://github.com/nix-community/rnix-lsp) are the most common ones.
Those LSP's should implement the simple "line continuation" feature. (I don't know the exact name here)

## Nixodc

Nixdoc needs to be changed in order to differentiate between regular comment and doc-comments.
There might be an intermediate phase of transition, where the old syntax and features is supported for a while.

- When extending nixdoc or writing dedicated parsers, the following persons can assist: [@hsjobeki]

## Documentation generators

Generating documentation from doc-comments is still a challenge.
If we'd like the fully automated approach, we definitely need something that can also evaluate nix expressions. 
(We have such a module in `tvix` which needs to be investigated more here)

Alternatively we can use the future nixdoc together with a static `map.json` that contains the scope for every discovery file/path in nixpkgs.

As this second approach is much easier I propose this is how we should initially start to extend the scope.

## More specialized section headings

### Type

- An RFC under construction specifies the used syntax within the `Type`-Block. It depends on this RFC, as it is the groundwork to provide a standardized field where additional rules can apply.

## Native support in nix

- `NixOS/nix` should implement native support for doc-comments so that our users don't have to rely on nixpkgs or external tools. Those tools can still exist and provide more custom functionality, but documenting nix expressions should be natively possible.

## Provide a stable and reliable format

- Every existing and future tool can implement against this RFC and rely on it.

# Related Tools

- [Rustdoc](https://doc.rust-lang.org/rustdoc/how-to-write-documentation.html)
- [Nixdoc](https://github.com/nix-community/nixdoc)

## Further

We envision gradual type checking for nix.

A weak source of type constraint could be the `# Type` field in doc-comments until nix may introduce its own native type system.
Very concrete doc-typing-syntax may allow gradual type checking.

- see a [preview](https://typednix.dev) of an eventual future doc-type-syntax.

## People that I discussed with

> People mentioned here might be not yet aware of this rfc.
> I'll ping them in the next few days to make sure they are okay with being mentioned here.

About doc-comments/doc-comments in general

- [@flokli](https://github.com/flokli) - one of the [tvix](https://tvl.fyi/blog/rewriting-nix) authors
- [@tazjin](https://github.com/tazjin) - Original Author of `nixdoc`, one of the `tvix` authors

About documentation approaches on independent frameworks

- [@davHau](https://github.com/davHau) - Author of [dream2nix](https://github.com/nix-community/dream2nix), (And many other nix-frameworks)

About defining weakly typed-interfaces for nix with doc-comments

- [@roberth](https://github.com/roberth) - nixpkgs Architecture Team
- [@aakropotkin](https://github.com/aakropotkin/) - nixpkgs Architecture Team
