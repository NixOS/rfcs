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

Propose a standard format for Docblocks


# Motivation
[motivation]: #motivation

This RFC aims to improve the consistency of in-code documentation. (aka Doc-strings/Doc-blocks)

> Doc-strings and Doc-blocks aren't technicially indentical. But for simplicity the phrase `Doc-string` is used througout this document.

## Current State

We are currently utilizing a `doc-string`-like functionality to build a subset of documentation for nix functions. (e.g., nixpkgs.lib documentation via: [nixdoc](https://github.com/nix-community/nixdoc))

Currently there are many inconsistently written comments that document specific parts of nixpkgs and other nix-frameworks. (see [references](#references))
We use some of them to generate documentation automatically. (e.g., nixpkgs/lib via [nixdoc](https://github.com/nix-community/nixdoc)

This solution requires a lot of handwork to setup, more specifically *nixdoc* is a custom tool, that works only for that purpose.

Here is an example how the format used in *nixdoc* works:

```nix
#attrsets.nix (simplified)

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

## Drawbacks 

##### Unspecified format

The format for writing documentation-strings in general is **not specified**. The only place where it is applied is: *nixpkgs/lib/**

*nixdoc* only applies to places in nixpkgs/lib. But extending the scope of *nixdoc* is not the primary goal. Instead we should find formal rules how to write *doc-strings*. Tools like *nixdoc* can then implement against this rfc. Instead of the format relying on nixdoc implementation details.

##### Only specific places

The placement of those comments requires to be exactly at the attribute-set that contains the function declarations. Which is not usable for general purpose documentation-strings. 

e.g., 

- file that directly exports the lib-function without wrapping it in an attribute-set.
- file that exports a constant
- files outside of lib are not / cannot be rendered

##### Differentiate from regular comments

The format doesnt allow any distinction between doc-strings or regular comments.

Having a distinction would allow to

1. Find all comments that are part of the documentation
2. Render them into the documentation format
3. Connect the documentation to exact places in the nix-code. This is already done, but only for nixpkgs/lib.

##### 

##### References 

###### nixpkgs - Dosctrings examples

- [lib/attrsets](https://github.com/NixOS/nixpkgs/blob/master/lib/attrsets.nix)
- [trivial-builders](https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/trivial-builders.nix)
- [stdenv/mkDerivation](https://github.com/NixOS/nixpkgs/blob/master/pkgs/stdenv/generic/make-derivation.nix)
- [nixos/lib/make-disk-image](https://github.com/NixOS/nixpkgs/blob/master/nixos/lib/make-disk-image.nix)
- more ...

###### frameworks

- [dream2nix/utils](https://github.com/nix-community/dream2nix/blob/main/src/utils/config.nix)
- [dream2nix/templates/builder](https://github.com/nix-community/dream2nix/blob/main/src/templates/builders/default.nix)
- more ... 

###### Other tools

Other tools that work directly with the nix AST and comments:

- [noogle](https://noogle.dev) - Nix API search engine. It allows you to search functions and other expressions.
- [nix-doc](https://github.com/lf-/nix-doc) - A Nix developer tool leveraging the rnix Nix parser for intelligent documentation search and tags generation
- [manix](https://github.com/mlvzk/manix) - A fast CLI documentation searcher for Nix. 

## Proposed Improvement - Doc-blocks

In general I thought we do need two kinds of doc-strings:

> The format is not final yet. Discussion may still ongoing.

#### A doc-string referencing the subsequent expression

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

#### A Doc-string referencing the file expression

Example: Uses `#|` instead of `##` to reference the whole file. Must be at top of the file.
 
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

# Alternatives
[alternatives]: #alternatives

In general we need:

1. General format for doc-strings.
2. Format for headings and the allowed content.

> It would be nice if this can be close to the markdown format.
> Because markdown is considered the easiest and most accepted format 
> for writing and rednering documentation.


#### Find a suitable decision in - the follwing matrix

| General / Section | 0 `##` | 1 `/** */`   | 2 `other`   |
|---|---|---|---|
| 0 `# {Keyword}` | `## # Example` | `/** # Example */` |  `?` |
| 1 `@{Keyword}:`  | `# @Example:` |`/** @Example: */` | `?` |
| 2 `other`  | `?` | `?` | `?` |

It is also possible to not implement this rfc:

- By not implementing this feature, nix loses the ability for tool-generated documentation.
- Documentation within code will remain unstable / only determined by nixdoc.

## The different formats considered

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

| Pro | Con |
|---|---|
| Saves vertical space | Needs Autocompletion (Language Server) to continue the next line. Hustle otherwise to start every line by hand |
|  | Changes the existing convention |
| Doesn't need termination (e.g. */) | Can break when interrupted with newlines / non-docstring line beginnings |
| Easier to read / Indentation is clear | Multiple comment tokens must be concatenated (Might be more complex) |
| Block continuation is more intuitive (With autocomplete setup properly) |  |
| Uses fewer punctuations and special characters; thus is visually more clear and requires less finger spread movements for reaching / and * and @ (for sections) |  |
| Works nicely with Markdown content as Indentation is visually more clear | Many `#` symbols might be confusing  |
| | Starting every line with `##` creates visual conflicts with markdown headings `# {Heading}` |

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

| Pro | Con |
|---|---|
| Clear termination | Takes up more vertical space |
| Doesn't change the existing convention by much | doesn't visually stand out by much (just one more `*` ) |
| Mostly stays compatible with existing implementations | Multiple blocks are not concatenated. They need to be continued |
| No configuration required (LSP for autocompletion on newlines) |  |
|  | Indentation needs to be clarified / more complex. |

## Candidates not considered

Javadoc style

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

Although this has already sneaked into some nix comments. This format is not considered best practice for a variety of good reasons.

1. Essentially combines the cons of both worlds.
2. It Takes up more space and needs autocompletion to fill missing `*` beginnings when extended.
3. Starting every line with `*` creates visual conflicts with the markdown bullet list also starting with `*`.
4. Pro: Indentation within is clear.
5. Most nix users cannot identify with java or javascript. They like predictable behavior.

## Section headings considered

### Markdown headings

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

| Pro | Con |
|---|---|
| Markdown is simple | doesn't visually distinguish from `##` starting the doc-string |
| Using headings feels natural | Users may accidentally use those headings within natural language |
| | Markdown recommends using newlines before and after headings which takes up a lot of vertical space |
| | Markdown headings do not visually stand out from lines that already started with `##` |

### Custom headings `@{Keyword}:`

Example:

```nix
# somefile.nix

    ## <Description or Tagline>
    ## 
    ## @Example:
    ##
    ## <Comprehensive code>
    ## 
    ## @Type:
    ##    
    ## <Type Signature>
    mapAttrs = f: s: #...
```

| Pro | Con |
|---|---|
| Visually stands out | Is new syntax. Where Markdown could be more intuitive. Doc-strings already are Markdown. So why not use markdown |
| Follows more closely the current convention |  |
| Needs less vertical space | |
| doesn't need newlines, everything could be even within a single line, allowing compression (may not be needed ?) | |

## Alternative approach - just comments

There is the idea from python that doc-strings are just strings, not even special ones. Comments will be docstrings if they follow specific placement rules. However, we thought this was a bad idea to follow. Such complex placement rules require the users to understand where those places are; with nix syntax, this is slightly more complex than with python. Because we don't have keywords such as `class MyClass():` or `def function():` where placement would be obvious

# Detailed design
[design]: #detailed-design

## Proposed Solution (0,0) => `##` For docstring body and markdown headings `# H1`

The following abstract rules describe how to write doc-strings.

> I would be pleased if you comment about whether we should use `## {content}` or `/** {content} */`
> I did write this RFC tailored towards `##` but using `/** */` is still an open discussion.

### Format Rules (When choosing (0,0) )

- [F100] - doc-string are all comments. That start with `##` or `#|` e.g. `## {content}`

This RFC is a significant change to the existing documentation convention. This is because it is better to do it right when always being downward compatible holds you back. We created a pro-con list in the [alternatives](#alternatives) section below.

We finally need to distinguish between regular comments and doc strings. We found this format to be the most distinguishable.

- [F200] - Doc-strings always document / relate to an expression.

- [F201] - Doc-strings starting with `##` relate to the expression in the following line / or, more precisely, to the next node in the AST. (Details follow, as this might be non-trivial)
- [F202] - Doc-strings that are at the top of a file and that start with `#|` describe the expression exported from the whole file. (Previous node in AST)

In comparison, rustdoc uses `//!`. But using `#!` is considered a bad idea, as it can be confused with identical bash shebangs `#!`. 

The `|` (pipe) is also avaiable in symbols used for the nix grammar. 

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

- [F300] - The docstring is continued in the following line if it also starts with `##` / `#|`. Leading whitespace is allowed.

Example: docstring continuation

```nix
## Doc-string A
##  ....
## This block has no expression in the next line. 
## Therefore it doesn't have any effect
##  ....
## Doc-string A


## Doc-string B
## -- this block documents the purpose of '1'
## Doc-string B
1
```

### Structural Rules

- [S010] - The content of a doc-string is Markdown.

It allows for intuitive usage without knowledge of complex syntax rules.

- [S011] - predefined heading `keywords` may start a section.
- [S021] - Content before the first [optional] section is called `description`.

This allows for quick writing without the need to use sections.

- [S022] - Headings H1 are reserved markdown headings. Which are specified in [this list](#keywords). Users are allowed to only use H2 (or higher) headings for their free use.

H1 headings start a section to keep it extendable in the future. Users are not allowed to choose them freely, so we keep track of all allowed H1 headings.

This may also be checked from the doc-tool that may evolve from this rfc (e.g. future versions of nixdoc)

- [S012] - Every [optional] section started by an H1 heading is continued until the next heading starts. To the very end of the comment, otherwise.
- [S014] - Every section may define its own rules. They must be compatible with the formal requirements of doc-strings (this RFC) that can override formal rules locally. (e.g., disable Markdown, use custom syntax, etc.)
- [S017] - Only the H1-sections (`Keywords`) described in [this list](#keywords) are valid.
  
- [S018] - In case of [future] extensions, every new section `Keyword` must first be added to this RFC.
- [S030] - If sections follow complex logic, it is embraced to specify that logic in a separate sub-RFC.
- [S040] - Usage of the described sections is OPTIONAL.
- ... more tbd.

## Keywords
[keywords]: #keywords

We wanted to keep the list of initial keywords short. So by the time this RFC focuses on the formal aspects of doc-strings first. More keywords and features for them can be added later on.

| Keyword     |  Description  | Note |
| ---         |  ---          | --- |
| `Example`   | Starts the Example-block. Often contains comprehensive code examples | |
| `Type`      | Start the Type-block; it is any free text | Syntax may eventually be specified in the future. [preview](https://typednix.dev). |

## Why change the existing section specifiers?

First of all: There are no actual block specifiers within nix or nixpkgs. The existing blocks heavily depend on a tool called `nixdoc` and not vice versa.

-> See [github:nix-community/nixdoc](https://github.com/nix-community/nixdoc)

> `nixdoc` MUST be changed to support this RFC. (See [Future work](#future-work))

The sequence `Example:` has some drawbacks when it comes to syntax:

1. It is possible that this sequence occurs in a natural text without the intention to start a new doc-string section.
2. It doesn't visually stand out.
3. It is bad that the line needs to start with `Example:` to be valid syntax. Although it is a good practice while writing comments. This shouldn't be syntactically required. > (`nixdoc` requires it).
4. It neither follows the `@param` (c/c++/java,...) convention nor the markdown headings convention (rust), instead is nixdoc-home-cooked.

## Interactions

Doc-strings can be attached to AST nodes without affecting the actual compile-, evaluation- or build-time because they are just comments. Specialized tools can handle those comments and create static documentation from them. Also, integration with LSP is possible.

Many files within nixpkgs contain detailed comments we cannot currently use.
An example: [make-disk-image.nix](https://github.com/NixOS/nixpkgs/blob/master/nixos/lib/make-disk-image.nix)

Following this RFC means refactoring for existing comments, but it also means that **we can finally use all comments (automated!) that were intended to be doc-strings**

# Drawbacks
[drawbacks]: #drawbacks

Drawbacks of this rfc.

- Changes the existing comments inside the code base.

This could mostly be automated. (e.g via codemod)

Also, this affects only the `lib` folder and a few other places that are currently used to build the documentation.

# Unresolved questions
[unresolved]: #unresolved-questions

- `nixodc` offers comments to describe function arguments. This is currently not compatible until some sections for `args` are defined.

- Will `nix` itself implement native support like in rust -> `cargo doc`

- How can a tool keep the connection from where a docstring was defined and where the attribute was exposed (lib/default.nix exposes mapAttrs which is defined at lib/attrsets.nix)
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

- When extending nixdoc and/or writing dedicated parsers the following persons can assist: [@hsjobeki]

- There is an RFC under construction, that specifies the used syntax within the `Type`-Block. It depends on this RFC, as this RFC is the groundwork to provide a standardized field where additional rules can apply. Core-Team: [@hsjobeki]

- `NixOS/nix` should implement native support for doc-strings. That way our users don't have to rely on nixpkgs or external tools. Those tools can still exist and provide more custom functionality, but it should be natively possible to document your nix expressions.

- Every existing and future tool can implement against this RFC and rely on it.

# References

- [Rustdoc](https://doc.rust-lang.org/rustdoc/how-to-write-documentation.html)
- [Nixdoc](https://github.com/nix-community/nixdoc)

## 

We considered this possible solution because the following reasons:

- Good visual distinction between doc-strings and comments
- Clear rules and structure
- Saves vertical space
- Doesn't need termination (*/)
- Clear indentation rules. Following the __markdown__ convention.
