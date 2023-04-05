---
feature: docblock-standard
start-date: 2023-03-27
author: hsjobeki
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Propose a standard format for Docblocks.


# Motivation
[motivation]: #motivation

This RFC aims to improve the consistency of in-code documentation. (aka Doc-strings/Doc-blocks)

> Doc-strings and Doc-blocks are technically different. But for simplicity, the phrase `Doc-string` is used in this document for clarity. Because it is more common.

## Current State

We currently utilize a `doc-string`-like functionality to build a subset of documentation for nix functions. (e.g., nixpkgs.lib documentation via: [nixdoc](https://github.com/nix-community/nixdoc))

Many inconsistently written comments document specific parts of nixpkgs and other nix-frameworks. (see [references](#references))
We use some of them to generate documentation automatically. (e.g., nixpkgs/lib via [nixdoc](https://github.com/nix-community/nixdoc)

This solution requires a lot of handworks; more specifically, *nixdoc* is a custom tool that works only for that purpose.

Here is an example of how the format used in *nixdoc* works:

```nix
#attrsets. nix (simplified)

{ lib }:
# Operations on attribute sets.

let
# ...
in
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

### Unspecified format

In general, the format for writing documentation strings is **not specified**. The only place where it is applied is: *nixpkgs/lib/**

*nixdoc* only applies to places in nixpkgs/lib. But extending the scope of *nixdoc* does not work and thus is not the primary goal. Instead, we should find formal rules for writing *doc-strings*. Tools like *nixdoc* can then implement against this RFC instead of the format relying on nixdoc implementation details. 

### Only specific placements work

The placement of those comments requires precisely commenting at the attribute set containing the function declarations, which is not usable for general-purpose documentation strings. 

e.g., 

- file that directly exports the lib-function without wrapping it in an attribute set.
- file that exports a constant expression
- files outside of lib cannot be rendered due to missing conventions

### Differentiate from regular comments

The format doesn't allow any distinction between doc-strings or regular comments.

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

- [noogle](https://noogle.dev) - Nix API search engine. It allows you to search functions and other expressions.
- [nix-doc](https://github.com/lf-/nix-doc) - A Nix developer tool leveraging the rnix Nix parser for intelligent documentation search and tags generation
- [manix](https://github.com/mlvzk/manix) - A fast CLI documentation searcher for nix. 

# Detailed design
[design]: #detailed-design

**Proposed Solution:** 

Use `##` For doc-string body and markdown headings `# H1`

The content of all doc-strings is markdown. 
Following the [commonmark-specification](https://spec.commonmark.org/)

## Doc-blocks

In general, I thought we do need two kinds of doc-strings:

### A doc-string referencing the subsequent expression

Example:
 
```nix
# somefile.nix

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

### A Doc-string referencing the file expression

Example: Uses `#|` instead of `##` to reference the whole file. It must be at the top of the file.
 
```nix
#| <Description or Tagline>
#| 
#| # Example
#|
#| <Comprehensive code>
#| 
#| # Type
#|    
#| <Type Signature>

{...}:
{
  mapAttrs = f: s: <...>;
}
```

The following abstract rules describe how to write doc-strings.

> I would be pleased if you comment about whether we should use `## {content}` or `/** {content} */`
> I did write this RFC tailored towards `##` but using `/** */` may still be an open discussion.

### Format Rules

- doc-string are all comments. That start with `##` or `#|` e.g. `## {content}`

This RFC is a significant change to the existing documentation convention
but we finally need to distinguish between regular comments and doc strings. We found this format to be the most distinguishable.

- Doc-strings always document / relate to an expression. 

In detail: `##` relates to the next AST-Node `#|` to the previous one. However technical details for tracking names and aliases is not part of this document. 

> Vision: Implement a custom evaluator that specializes in tracking references of doc-strings within the nix expression tree. This is however a technical concrete solution that may be build after this rfc is accepted. 

- Doc-strings starting with `##` relate to the expression in the following line / or, more precisely, to the next node in the AST. (Implementation Details are not considered yet, maybe future versions need to narrow the scope here)

> I wont go into details here as this is would already be an implementation specification, but this is how i thought it could technically make sense. 
> 
> E.g. a "documentation generator":
> The referenced expression might be an IDENT_NODE or an expression that can be assigned to an IDENT_NODE.
> The doc-string may then be yielded from the IDENT_NODE, or from the expression that was assigned to the NODE. (Precendence is -1, which means a doc-string is always the last assignment)
> ```nix
> ## Refences the whole thing
> ## (foo bar baz) 
> foo bar baz
> ```
> Expressions would thus need a meta-wrapper that hold the necessary doc-string and preserves it during the evaluation. While rendering out the whole nix expression (recursion need to be considered e.g. in Derivation, etc.!) All references are preserved and can then be mapped into a list for each identifier in the tree.
> e.g. `foo.bar.baz` holds a refernce to the docstring that was asigned to the expression in `baz.nix`
>
> BUT this is a very concrete documentation generator, that makes eventually sense to be built after this RFC.

- Doc-strings that are at the top of a file and that start with `#|` describe the expression exported from the whole file. (Previous node in AST)

In comparison, rustdoc uses `//!`. But using `#!` is considered a bad idea, as it can be confused with identical bash shebangs `#!`. 

The `|` (pipe) is also available in symbols used for the nix grammar. 

> This is still being determined. If you have any ideas, let us know in the comments.

Example of a comment referring to the whole file:

```nix
#| <Description>
#| <Description more>
#| # Example
#| <Some comprehensive code>
#| # Type
#| The Type of the expression returned by the file
{
  id = x: x
}
```

- The docstring is continued in the following line if it also starts with `##` / `#|`. Leading whitespace is allowed.

Example: docstring continuation

```nix
## Doc-string A
##  ....
## This block has no expression in the following line. 
## Therefore, it doesn't have any effect
##  ....
## Doc-string A


## Doc-string B
## -- This block documents the purpose of '1'
## Doc-string B
1
```

- The content of a doc-string is Markdown.

It allows for intuitive usage without knowledge of complex syntax rules.

- predefined heading `keywords` may start a section.
- Content before the first [optional] section is called `description`.

This allows for quick writing without the need to use sections.

- Headings H1 are reserved markdown headings. Which are specified in [this list](#keywords). Users are allowed to only use H2 (or higher) headings for their free use.

H1 headings start a section to keep it extendable in the future. Users are not allowed to choose them freely, so we keep track of all allowed H1 headings.

This may also be checked from the doc-tool that may evolve from this RFC (e.g. future versions of nixdoc)

- Every [optional] section started by an H1 heading is continued until the next heading starts. To the very end of the comment, otherwise.
- Every section may define its own rules. They must be compatible with the formal requirements of doc-strings (this RFC) that can override formal rules locally. (e.g., disable Markdown, use custom syntax, etc.)
- Only the H1-sections (`Keywords`) described in [this list](#keywords) are valid.
  
- In case of [future] extensions, every new section `Keyword` must first be added to this RFC.
- If sections follow complex logic, it is embraced to specify that logic in a separate sub-RFC.
- Usage of the described sections is OPTIONAL.
- more tbd.

## Keywords
[keywords]: #keywords

The following keywords start new markdown sections

> I wanted to keep the list of initial keywords short. So by the time this RFC focuses on the formal aspects of doc-strings first. More keywords and features for them may be added later on.

| Keyword     |  Description  | Note |
| ---         |  ---          | --- |
| `Example`   | Starts the Example-block. Often contains comprehensive code examples | |
| `Type`      | Start the Type-block; it is any free text | Syntax may eventually be specified in the future. [preview](https://typednix.dev). |

## Why change the existing section specifiers?

First, there are no actual block specifiers within nix or nixpkgs. The existing blocks heavily depend on a tool called `nixdoc` and not vice versa.

-> See [github:nix-community/nixdoc](https://github.com/nix-community/nixdoc)

> `nixdoc` MUST be changed to support this RFC. (See [Future work](#future-work))

The sequence `Example:` has some drawbacks when it comes to syntax:

1. It is possible that this sequence occurs in a natural text without the intention to start a new doc-string section.
2. It doesn't visually stand out.
3. It is terrible that the line needs to start with `Example:` to be valid syntax. However, it is a good practice while writing comments; it should be optional.
4. It neither follows the `@param` (c/c++/java,...) convention nor the markdown headings convention (rust); instead is nixdoc-home-cooked.

## Interactions

Doc-strings can be attached to AST nodes without affecting the actual compile-, evaluation- or build-time because they are just comments. Specialized tools can handle those comments and create static documentation from them. Also, integration with LSP is possible. (See [@flokli's nix lsp-whishlist](https://hackmd.io/@geyA7YL_RyiWJO6d5TbC-g/Sy6lVrgW3) for inspirations)

Following this RFC means refactoring for existing comments, but it also means that **we can finally use all comments (automated!) that were intended to be doc-strings**

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

1. General format for doc-strings.
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
| Visual distinction from comments | High | Low | Intermediate |
| Needs Autocompletion (Language Server) to continue the next line. | Yes | No | Yes |
| Punctuation Variations / Amount of different special characters | Less | More | More |
| Markdown compatibility (also depends on indentation clarity) | Good, but visual conflicts with headings` #` | Poor | Intermediate |
| breaks when interrupted with newlines | Yes | No | ? |

**Proposed format:**

Use `##` to start a doc-string. This allows clear visual seperation from regular comments.
And provides a good compatibiliy with the strived markdown content.

### Refactoring note:

nixpkgs comments:

- `##` ~4k usages (most of them are used for visual seperation e.g. `###########`)
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

Use markdown headings `# <Heading>`. This allows best compatibility with the aleady specified markdown/commonmark format. Allowing for easy and intuitive usage for comments.

## Why we should do this

- Find all comments that are part of the documentation
- Render them using markdown
- Connect the documentation to the exact places in the nix code.

- By not implementing this feature, nix loses the ability for tool-generated documentation.
- Documentation will not defined by nixdoc, instead the community-implementation solution to the standard.

## Examples

This section contains examples for the different formats to visualize them and emphasize the previously discussed characteristics.

### `##` inspired from rust's `///` 

with `Markdown` Headings

Example:

```nix
# somefile.nix

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

Example:

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

There is the idea from python that doc-strings are just strings, not even special ones. Comments will be docstrings if they follow specific placement rules. However, we thought this was a bad idea to follow. Such complex placement rules require the users to understand where those places are; with nix syntax, this is slightly more complex than with python. Because we don't have keywords such as `class MyClass():` or `def function():` where placement would be obvious

# Unresolved questions
[unresolved]: #unresolved-questions

- `nixodc` offers comments to describe function arguments. This is currently not compatible until some sections for `args` are defined.

- Will `nix` itself implement native support like in rust -> `cargo doc`

- How can a tool keep the connection from where a docstring was defined and where the attribute was exposed (lib/default. nix exposes mapAttrs which is defined at lib/attrsets. nix)
  - There are more complicated things.

-> Answer: A Tool might be able to keep track of a percentage of expressions, and sometimes it may be very hard or impossible. For that case, the doc-string can offer a dedicated Keyword to override the scope.

e.g.

The following is an idea for a problem that will arise if tools try to track doc-strings' positions and the location in the nixpkgs tree. (Although this problem is not nixpkgs specific)

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
This is done in rust similarily. Nix already offers a bunch of LSP's e.g. [nil](https://github.com/oxalica/nil), [rnix-lsp](https://github.com/nix-community/rnix-lsp) are the most common ones. 
Those LSP's should implement the simple "line continuation" feature. (I dont know the exact name here)

## Nixodc

Nixdoc needs to be changed in order to differentiate between regular comment and doc-blocks.
There might be an intermediate phase of transition, where the old syntax and features is supported for a while.

- When extending nixdoc or writing dedicated parsers, the following persons can assist: [@hsjobeki]

## Documentation generators

Generating documentation from doc-blocks is still a challenge.
If we'd like the fully automated approach, we definetly need something that can also evaluate nix expressions. 
(We have such a module in `tvix` which needs to be investigated more here)

Alternatively we can use the future nixdoc together with a static `map.json` that contains the scope for every discovery file/path in nixpkgs.

As this second approach is much easier I propose this is how we should initially start to extend the scope.

## More specialized section headings

### Type

- An RFC under construction specifies the used syntax within the `Type`-Block. It depends on this RFC, as it is the groundwork to provide a standardized field where additional rules can apply.

## Native support in nix

- `NixOS/nix` should implement native support for doc-strings so that our users don't have to rely on nixpkgs or external tools. Those tools can still exist and provide more custom functionality, but documenting your nix expressions should be natively possible.

## Provide a stable and reliable format

- Every existing and future tool can implement against this RFC and rely on it.

# References

- [Rustdoc](https://doc.rust-lang.org/rustdoc/how-to-write-documentation.html)
- [Nixdoc](https://github.com/nix-community/nixdoc)

## People that I discussed with 

> People mentioned here might be not yet aware of this rfc.
> I'll ping them in the next few days to make sure they are okay with beeing mentioned here.

About doc-strings in general

- [@flokli](https://github.com/flokli) - one of the [tvix](https://tvl.fyi/blog/rewriting-nix) authors
- [@tazjin](https://github.com/tazjin) - Original Author of `nixdoc`, one of the `tvix` authors

About documenation approaches on independent framworks

- [@davHau](https://github.com/davHau) - Author of [dream2nix](https://github.com/nix-community/dream2nix), (And many other nix-frameworks)

About defining weakly typed-interfaces for nix with doc-strings

- [@roberth](https://github.com/roberth) - nixpkgs Architecture Team
- [@aakropotkin](https://github.com/aakropotkin/) - nixpkgs Architecture Team
