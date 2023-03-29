---
feature: doc-strings
start-date: 2023-03-27
author: hsjobeki
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Standard for Doc-strings

Finally distinguish between doc-strings and comments.

# Motivation
[motivation]: #motivation

This RFC aims at improving consistency of in code documentation. (aka Doc-strings)

The community offers tools and methods (such as nixdoc, nix-doc, etc.) to write and process in-code documentation for functions and other code related atomic expressions.
This functionality is currently utilized to build a subset of documentation for nix functions. (e.g. nixpkgs.lib documentation via: [nixdoc](https://github.com/nix-community/nixdoc))
There is also [noogle](https://noogle.dev) that indexes subsets of nixpkgs based on the current comments.

However the format of that __docs-strings__ is itself neither well documented nor standardized.

This RFC aims at achieving consistency for docs-strings and allow to differentiate between regular comments and doc-strings.

We could envision native nix support, documentation-team or community-driven solutions for automatically generating documentation from them.

__Current issue__

> The existing doc-strings heavily depend on a tool called `nixdoc` and not vice versa.
>
> Instead we want to provide a common standard that every nix user can refer to.

Everything until now is just a draft if you can provide better ideas e.g. using different formats or syntax please let me know.

## Example of the current format:

```nix
/*
  <Description
  Example:
  <Code Examples>
  Type:
  <Some Type information>
*/
expr = 
# Describes 'arg'
arg:
# Describes 'foo'
foo: 
```

> This RFC aims for general rules for doc-strings.
> Features like: "what different sections exist" and if they might have complex rules (e.g. type: syntax) is not specified.
>
> Providing a formal skeleton, where sections can be extended by the nix community

## Proposed solution

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

This is considered a possible solution because the following reasons:

- Good visual distinction between doc-strings and comments
- Clear rules and structure
- Saves vertical space
- Doesn't need termination (*/)
- Clear indentation rules. Following the __markdown__ convention.

# Detailed design
[design]: #detailed-design

The following abstract rules describe how to write doc-strings.

> I'am very happy if you comment about whether we should use `## {content}` or `/** {content} */`
> I did write this RFC tailored towards `##` but using `/** */` is still an open discussion.

We must find one solution out of the following:

|  | 0 `##` | 1 `/** */`   |
|---|---|---|
| 0 `# {Keyword}` | `## # Example` | `/** # Example */` |
| 1 `@{Keyword}:`  | `# @Example:` |`/** @Example: */` |

Proposed Solution (0,0) => `##` For docstring body and markdown headings `# H1`

### Format Rules

- [F100] - Docs-string are all comments. That start with `##` or `#!` e.g. `## {content}`

This is a quite big change to the existing documentation convention. The reason behind this: Better do it right when always being downwards compatible holds you back. We created a pro-con list in the [alternatives](#alternatives) section below.

This provides distinction between regular comments and those who are actually doc-strings.

- [F200] - Doc-strings always document / relate to an expression.

- [F201] - Doc-strings starting with `##` relate to the expression in the next line / or more precisely to the next node in the AST. (Details follow, as this might be non-trivial)
- [F202] - Doc-strings that are at the top of a file and that start with `##?` describe the expression exported from the whole file. (Previous node in AST)

- [F300] - The docstring is continued in the next line if it starts with `##` as well. Leading whitespace is allowed.

### Structural Rules

- [S010] - The content of a doc-string is Markdown.

Allows for intuitive usage without knowledge of complex syntax rules.

- [S021] - Content before the first [optional] section is called `description`.

This allows for quick writing without the need to use sections.

- [S022] - Headings H1 are reserved markdown headings. Which are specified in [this list](#keywords). Users are allowed to only use H2 (or higher) headings to their free use.

H1 headings start a section to keep it extendable in the future. Users do not use them so we keep track of all used H1 headings.

- [S012] - Every [optional] section started by an H1 heading is continued until the next heading starts. To the very end of the comment otherwise.
- [S014] - Every section defines its own rules while they must be compatible with the formal requirements of doc-strings (this RFC) the can override formal rules locally. (e.g. disable markdown, use custom syntax etc.)
- [S017] - Only the H1-sections (`Keywords`) described in [this list](#keywords) are valid.

e.g.

```nix
```

- [S018] - In case of extension, every new section `Keyword` must be added to this RFC first.
- [S030] - If sections follow complex logic it is embraced to specify that logic in an separate sub-RFC.
- [S040] - Usage of the described sections is totally OPTIONAL.
- ... more tbd.

## Keywords
[keywords]: #keywords

We wanted to keep the list of initial keywords short. So by the time this RFC focuses on the formal aspects of doc-strings first. More keywords and features for them can be added later on.

| Keyword     |  Description  | Note |
| ---         |  ---          | --- |
| `Example`   | Starts the Example-block. Often contains comprehensive code examples | |
| `Type`      | Start the Type-block, it is any free text | Syntax may eventually be specified in the future. [preview](https://typednix.dev). |

### Blocks appear only once

This reduces complexity and avoids confusion if there is only one place for every concern.

### All Keywords live in this RFC

This ensures every keyword is documented.

### New Keywords

Ensures newly introduced keyword are discussed in this context first.

If they bring in more complex sub-features (like Types) those can be discussed in separate RFCs which are back-linked in the [keywords](#keywords) table. This helps to keep this overarching proposal clean and short.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

The following example illustrates the structure of doc-strings

- starting with `##`
- doesn't change the nix syntax

```nix
# Example - structure

##    <- Description content->
##    # Example
##    <- Some comprehensive code examples ->
##    # Type:
##    <- Type ->
```

Example: old docs-strings. (To be changed by this RFC)

```nix
# lib/attrsets.nix

/* Create a new attribute set with `value` set at the nested attribute location specified in `attrPath`.
     Example:
       setAttrByPath ["a" "b"] 3
       => { a = { b = 3; }; }
     Type:
       setAttrByPath :: [String] -> Any -> AttrSet
  */
  setAttrByPath
```

Example: After changes.

```nix
# lib/attrsets.nix

## Create a new attribute set with `value` set at the nested attribute location specified in `attrPath`.
##
## # Example
##  setAttrByPath ["a" "b"] 3
##    => { a = { b = 3; }; }
##
## # Type
##  setAttrByPath :: [String] -> Any -> AttrSet
  setAttrByPath 
```

## Why change the existing block specifiers?

First of all: There are no actual block specifiers within nix or nixpkgs. The existing blocks heavily depend on a tool called `nixdoc` and not vice versa.

-> See [github:nix-community/nixdoc](https://github.com/nix-community/nixdoc)

> `nixdoc` MUST be changed to support this RFC. (See [Future work](#future-work))

The sequence `Example:` has some drawbacks when it comes to syntax:

1. It is possible that this sequence occurs in a natural text without the intention to start a new docs-string block.
2. It doesn't visually stand out.
3. It is bad that the line needs to start with `Example:` to be valid syntax. Although it is a good practice while writing comments. This shouldn't be syntactically required. > (`nixdoc` requires it).

## Interactions

Why doc-strings are valuable

Doc-strings can be attached to AST nodes without having effect on the actual compile-, evaluation- or build-time because they are just comments. Specialized tools can handle those comments and create static documentation from them. Also integration with LSP is possible.

# Drawbacks
[drawbacks]: #drawbacks

- Changes the existing comments inside the code base.

This could mostly be automated. (e.g via codemod)

Also this affects only the `lib` folder and few other places that are currently used to build the documentation.

# Alternatives
[alternatives]: #alternatives

- By not implementing this feature, nix loses the ability for tool generated documentation.

- Documentation within code will remain unstable / only determined by nixdoc.

## Pros-Cons for the different formats

### `##` inspired from rust's `///`

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
| Easier to read / indentation is clear | Multiple comment tokens must be concatenated (Might be more complex) |
| Block continuation is more intuitive (With autocomplete properly setup) |  |
| Uses less punctuations and special characters thus is visually more clear and requires less finger spread movements for reaching / and * and @ (for sections) |  |
| Works nicely with Markdown content as indentation is visually more clear | Many `#` symbols might be confusing  |
| | Starting every line with `##` creates visual conflicts with markdown headings `# {Heading}` |

### `/** */` inspired from the current multiline strings

`/** */` In comparison arguments for using `/** */` together with `@{keyword}:` to start sections

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
|  | Indentation is not clear / more complex. |

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
2. Takes up more space and needs autocompletion to fill missing `*` beginnings when extended.
3. Starting every line with `*` creates visual conflicts with markdown bullet list also starting with `*`.
4. Pro: Indentation within is clear.
5. Most nix users cannot identify with java or javascript. They like predictable behavior.

## Pros-Cons for section headings

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
| Visually stands out | Is new syntax. Where markdown could be more intuitive. doc-strings already are markdown. So why not use markdown |
| Follows more closely the current convention |  |
| Needs less vertical space | |
| doesn't need newlines, everything could be even within a single line, allowing compression (may not be needed ?) | |

# Unresolved questions
[unresolved]: #unresolved-questions

- `nixodc` offers doc-strings to describe function arguments. This is currently not compatible until some section for `args` are defined.

- Will `nix` itself implement native support like in rust -> `cargo doc`

- How can a tool keep the connection from where a docstring was defined and where the attribute was exposed (lib/default.nix exposes mapAttrs which is defined at lib/attrsets.nix)
  - There are more complicated things.

-> Answer: A Tool might be able to keep track of a percentage of expressions. Sometimes it may be very hard or impossible. For that case the doc-string can offer a dedicated Keyword that allows to override the scope.

e.g.

The following is just an idea for a problem that will arise if tools try to track positions of doc-strings and the location in the nixpkgs tree. (Although this problem is not nixpkgs specific)

```nix
#untrackable.nix
/*!
    This file is called somewhere that cannot be automatically tracked / is impossible to analyse statically.
    The 'TreePath' override can be used by the docstring author to set a fixed path in the nixpkgs expression.
    (This behavior will not be specified in this RFC)
    @TreePath: pkgs.stdenv 
*/
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
