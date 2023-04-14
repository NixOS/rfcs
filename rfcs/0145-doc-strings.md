---
feature: doc-comment-standard
start-date: 2023-03-27
author: hsjobeki
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (@DavHau, ... ? If you are interested, please PM the author on matrix or comment)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Propose a standard format for Doc-comments.

This RFC includes two concerns that define a doc-comment:

- Outer format rules to allow distinction between regular comments and doc-comments
- Inner format rules that describe the required format of the content. 

However, both concerns relate closely to each other; We thought it made sense and reduced bureaucracy to address that in a single RFC.

# Motivation
[motivation]: #motivation

The following are the envisioned goals.

- be able to generate documentation from code for any nix expression.
- be able to distinguish between documentation-relevant comments and unrelated comments.
- make doc comments easy to write and read
- be able to parse and render doc comments nicely
- standardize a format for doc comments that further RFCs can extend

This RFC is a significant change to the existing documentation convention
but allows distinguishing between regular and doc comments. Having distinction is essential because arbitrary code comments should not end up in generated documentation.

> Hint: Generating static documentation is controvert topic in nixpkgs. We found that it is impossible to generate accurate documentation statically. A correct solution would involve the evaluation of expressions in some way. This already goes deeply into implementation details and is thus not discussed further in this document. However, we envision solutions to solve this issue.

## Current State

We currently utilize a `doc-comment`-like functionality to build a subset of static documentation for nix functions. (e.g., nixpkgs.lib documentation via: [nixdoc](https://github.com/nix-community/nixdoc))
Many inconsistently written comments document specific parts of nixpkgs and other nix-frameworks (see [references-to-this](#references-to-the-problems-above)).

We use some of them to generate documentation automatically. (e.g., nixpkgs/lib via [nixdoc](https://github.com/nix-community/nixdoc) )

This solution requires much manual work; more specifically, *nixdoc* is a custom tool that works only for that purpose.

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

The *nixdoc*-tool enforces a somewhat consistent format, but the basic format was never specified and cannot be enforced in parts of nixpkgs where nixdoc is currently not applied.

Extending the scope of *nixdoc* is not the primary goal. Instead, we should find formal rules for writing *doc-comments*. Tools like *nixdoc* can then implement against this RFC instead of the format relying on nixdoc implementation details.

### Only specific placements work

The placement of those comments requires precisely commenting at the attribute set containing the function declarations, which is not usable for general-purpose documentation strings.

e.g.,

- file that directly exports the lib-function without wrapping it in an attribute set.
- file that exports a constant expression.
- files outside of lib cannot be rendered due to missing conventions.

### Some multiline comments are doc-comments (implicitly)

Many places (outside /lib) currently utilize the multiline comment `/* */` to write multiline comment documentation.
However, this is also inconsistent across nixpkgs and was never specified as the doc-comment format.

- There is no respective single-line comment, that would allow documentation rendering
- Inconsistent usage of multiline comments prevents us from using them directly.

### Impossible to differentiate from regular comments

The format does not allow any distinction between doc-comments and regular comments.

Having a distinction would allow us to

1. Find all comments that are part of the documentation
2. Render them in the documentation format
3. Connect the documentation to the exact places in the Nix code. 

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

- [noogle](https://noogle.dev) - Nix API search engine. It allows searching functions and other expressions.
- [nix-doc](https://github.com/lf-/nix-doc) - A Nix developer tool leveraging the rnix Nix parser for intelligent documentation search and tags generation
- [manix](https://github.com/mlvzk/manix) - A fast CLI documentation searcher for nix.

# Detailed design
[design]: #detailed-design


Each subsection here contains a decision along with arguments and counter-arguments for (+) and against (-) that decision.


## `/**` to start a doc-comment

**Observing**: Doc-comments' outer format should be a distinctive subset of regular comments. Nevertheless, it should allow native writing without needing an ide or full-blown-language servers.

**Considering**: `/** {content} */` where `{content}` is the inner format which is discussed later.

**Decision**: use `/** {content} */` as the outer format.

<details>
<summary>Arguments</summary>

- (+) Stays mostly compatible with the currently used multiline comments.
- (+) Is a strict subset of multiline comments, which allows multiline documentation natively.
- (+) Does not need Language Server (LSP) support for productive usage. (In contrast to e.g., `##`)
- (+) Allows copy-pasting content without the need for re-formatting.
- (-) Is visually less distinctive.
- (-) Indentation is more complex and visually less present.
    - (+) If its indentation logic implements nix's magic multiline strings, it would be most intuitive.
- (-) Takes up more vertical space
- (+) Takes up less horizontal space. (In contrast to e.g., `##` lines don't have to be prefixed)
- (+) Only one single character to change the semantics of the whole comment. 
    - (+) Allows for quickly adding and removing things from the documentation.
    - (-) Accidentally adding/removing could happen.
    
</details>


## CommonMark as the content of doc-comments

**Observing**: Doc-comments' content should be intuitive to read and write and straightforward to render. The nixdoc convention is not widely adopted outside certain places (e.g /lib) in nixpkgs. This may also come from a lack of understading the current self-cooked format.

**Considering**: CommonMark as the content format.

**Decision**: CommonMark is the content of all doc-comments.

<details>
<summary>Arguments</summary>

- (+) CommonMark is the official format in nix; Decided in [RFC72](https://github.com/NixOS/rfcs/blob/master/rfcs/0072-commonmark-docs.md).
    - (+) It Would be consistent if this RFC builds upon the previous one.
    - (+) Further Arguments for CommonMark, in general, can be found in RFC72
- (+) Allows copy-paste from and to markdown files. Allowing easy refactoring if documentation grows and needs to be splitted in separate files.
- (-) Strictly binding doc-comments' content to commonMark might restrict users.
    - (+) Users/Tools can still use regular comments or develop alternative solutions.
- (-) CommonMark does not specify the current rich features from nixdoc such as predefined sections and structures that could be used as source for automated toolings. Such as types for type-checking or examples to run automated-tests
    - (+) future tools can still build their conventions on top of this RFC. They might not directly specify them in an RFC but instead, be a tool developers choose for a specific codebase. However, we have yet to get that tools. So it is good when rich features remain unspecified.    
   
> Markdown is the most straightforward and most accepted format
> for writing and rendering documentation.
    
</details>

## Place doc-comments before the referenced expression 

**Observing**: Doc-comments currently are placed above the expression they document. More precisely, currently, only named attribute bindings `foo = <expr>` can be documented. There is also the need to support anonymous functions where they are implemented, not where they get names. More generally, there is the need to document unnamed expressions.

**Considering**: General reference logic between doc-comments and expressions.

**Decision**: Doc-comments always relate to the expression in the next AST-Node.

<details>
<summary>Arguments</summary>

- (+) Doc-comments should have only one variant if possible to reduce complexity. Referencing the next node seems straight forward. 
- (-) A variant that references the pevious node in the AST should be avoided if possible to reduce complexity.
- (+) Relation between documentation and the referenced implementation is clear and back-trackable.
- (-) Concrete Implementation might be complex.
- (-) Unclear if complete documentation might also need backwards references. 
    - (-) e.g. rust uses backwards references only at top of file comments.
    - (+) Nix files can only have ONE expression, the next AST Node in case of top-of-file comments is thus always only that one expression. (Unlike in Rust)
- (-) Tools need to be smart enough to understand asignments `=` and other forms of creating names for anonymous expressions. (e.g `callPackage` and `import` )
    - (+) Tools can still come up with other solutions, that dont involve calculating everything dynamically from nix code, but could also involve a static configuration.
    - (+) The whole `tool point` is an implementation detail. As long as it is not impossible to implement. The current tool `nixdoc` already proves that it is possible to have static documentation to a certain degree.

</details>

## Doc-comment examples

The following examples demonstrates the concrete usage scenarios:

`somefile.nix`

~~~nix
{
  /**
  Documentation for mapAttrs
  
  # Example
  
  ```
  mapAttrs {attr = "foo"; } ...
  ```
  
  # Type
  
  ```
  mapAttrs :: a -> b -> c
  ```
  
  */
  mapAttrs = f: s: <...>;
}
~~~

## Examples

This section contains examples for the different use-cases we would end up with; Visualize them and emphasize the previously discussed characteristics.

### Attribute bindings 

`somefile.nix`

~~~nix
{
  /**
  mapAttrs is a well known function 
  
  # Examples
  
  ```nix
  some code examples
  ```
  
  */
  mapAttrs = f: s: #...
}
~~~

### NixOS Module documentation 

> This is an example of what is possible. The future conventions may still evolve from the nix-community

NixOS Modules also can produce documentation from their interface declarations. However, this does not include a generic description and usage examples.

`myModule.nix`
~~~nix
/**
  This is a custom module.
  
  It configures a systemd service
  
  # Examples
  
  Different use case scenarios
  how to use this module
  
*/
{config, ...}:
{
  config = f: s: f s;
}
~~~

### Anonymous function documentation 

> This is an example of what is possible. The future conventions may still evolve from the nix-community

`function.nix`
~~~nix
/**
  This is an anonymous function implementation.
  
  It doesn't have a name yet. 
  But documentation can be right next to the implementation.
  
  The name gets assigned later:
  
  ```nix
  {
     plus = import ./function.nix;
  }
  ```
  
  (future) native nix or community tools provide 
  implementations to track doc-comments within the nix evaluator.
  Documentation of `sum` can then be inferred. 
  This still needs to be specified/implemented!

*/
{a, b}:
{
  sum = a + b;
}
~~~

### Anonymous expression documentation 

> This is an example of what is possible. The future conventions may still evolve from the nix-community

`exp.nix`
~~~nix
/**
  This is an anonymous string.
 
  Its purpose can be documented.
  
  Although this example is quite superficial, there might be use cases.
*/
"-p=libxml2/include/libxml2"
~~~

# Drawbacks
[drawbacks]: #drawbacks


## Changes the existing comments inside the code base.

This could mainly be automated. (e.g. via codemod)

Also, this affects only the `lib` folder and a few other places currently used to build the documentation.

## Changes in the `nixdoc`tooling is required. 

It remains an open question that needs to be tried;

Can we still build the current nixos manuals with the new standard?

- We can wait to change everything.
- Migration can happen in small steps.

# Alternatives
[alternatives]: #alternatives

## All considered outer formats
    
| Property / Approach | `##` | `/** */` | `Javadoc` | `/*\|` or `/*^`  |
|---|---|---|---|---|
| Inspired by | Rust | Current nixpkgs.lib | C++/Java/Javascript | Haskell Haddock |
| Changes the existing code by | Much | Less | Even More | Less |
| Needs Termination | No | Yes | Yes | Yes |
| Indentation | Clear | like Nix's multiline strings, thus **Intuitive** | Poor | ? |
| Needs vertical space  | No | Yes | Yes | Yes | 
| Visual distinction from comments | High | Low | Medium | Medium |
| Needs Autocompletion (Language Server) to continue the next line. | Yes | No | Yes | No |
| Punctuation Variations / Amount of different special characters | 1 (Less) | 2 (Medium) | 2 (Medium) | 3 (More) |
| Markdown compatibility (also depends on indentation clarity) | Good, but visual conflicts with headings` #` | Good | Medium | Good |
| breaks when interrupted with newlines | Yes | No | ? | No |
| Simplicity (Brainload) | Medium | Simple | Complex | More Complex | 
    
### Refactoring note
    
**Observing**: From a refactoring perspective, it might also be interesting to see how many conflicts the different formats would cause.
    
nixpkgs comments:

- `##` ~4k usages (most of them for visual separation e.g., `###########`)
- `#` ~20k usages
- `/*` ~6k usages
- `/**` 160 usages (most empty ?)
    
Choosing `/**` or subsets would cause minor conflicts within current nixpkgs. While this is NOT the main reason for the final decision, it MUST be considered.


## Just free text as a content format

While this allows the most freedom, it is usually considered the best option, not creating any restrictions. 

But nix/rfc72 defines commonMark as the official documentation format. 
This is why we decided to follow this convention.

## Consequences of not implementing this

- By not implementing this feature, nix gains no ability for tool-generated documentation.
- Documentation will be defined by nixdoc, not by the nix community.
- Many existing comments written for documentation will remain un-discoverable.

# Unresolved questions
[unresolved]: #unresolved-questions

- `nixodc` offers comments to describe function arguments, and this is currently discarded once they are directly described in prose by the user.

- Will `nix` itself implement native support like in rust -> `cargo doc`?

- How can a tool keep the connection from where a docstring was defined and where the attribute was exposed (lib/default. nix exposes mapAttrs which is defined at lib/attrsets.nix)
  - There are more complicated things.

**Answer**: This is a tooling question; implementation details won't be discussed in detail. It is possible to track comments in the AST. As shown before in this PR: [nix/#1652](https://github.com/NixOS/nix/pull/1652)

# Future work
[future]: #future-work

## Editor support

- Implement displaying the related documentation when hovering over an expression. (lspAction/hover)

Nix already offers a bunch of LSP's e.g. [nil](https://github.com/oxalica/nil), [rnix-lsp](https://github.com/nix-community/rnix-lsp) are the most common ones.


## Nixodc

Nixdoc must be changed to differentiate between regular comments and doc-comments.
There might be an intermediate phase of transition, where the old syntax and features are supported in parallel to allow a phase of transition and refactoring of existing documentation comments.

## Documentation generators

- Future nixdoc could have a static `map.json` that contains the scope for every discovery file/path in nixpkgs.

As this second approach is much easier, We propose this is how we should initially start to extend the scope.

Generating documentation from doc-comments dynamically would still be excellent but remains a challenge.
If we want the fully automated approach, we need something to evaluate nix expressions. 

We solve such concerns in `tvix` or in `nix`, which could provide a `nix-analyzer` that pre-evaluates expressions and their respective documentation. 

## Type

- An RFC under construction specifies the used syntax within the `# Type` Heading.
- The `type` feature should belong in the nix syntax. Try them within the comments first; This is still possible.

- see a [preview](https://typednix.dev) of an eventual future doc-type-syntax.

## Native support in Nix

- `NixOS/nix` should implement native support for doc-comments so that our users do not have to rely on nixpkgs or external tools. Those tools can still exist and provide more custom functionality, but documenting nix expressions should be natively possible.

# References

## Other Conventions

- [Rust](https://doc.rust-lang.org/stable/reference/comments.html#doc-comments)
- [Python](https://peps.python.org/pep-0257/)
- [JSDoc](https://jsdoc.app/)

## Related tools

- [Nixdoc](https://github.com/nix-community/nixdoc)
- [Rustdoc](https://doc.rust-lang.org/rustdoc/how-to-write-documentation.html)
- [Doxygen](https://www.doxygen.nl/)

## Related discussions

### About doc-comments/doc-comments in general.

- [@documentation-team (meet @ 13.Apr 2023)](https://discourse.nixos.org/t/2023-04-13-documentation-team-meeting-notes-41/27264)
- [@flokli](https://github.com/flokli) - one of the [tvix](https://tvl.fyi/blog/rewriting-nix) authors
- [@tazjin](https://github.com/tazjin) - Original Author of `nixdoc`, one of the `tvix` authors

- There is an actual but rather old PR (@roberth) that uses just comments to show documentation in the nix repl for functions. -> https://github.com/NixOS/nix/pull/1652

### About documentation approaches on independent frameworks.

- [@davHau](https://github.com/davHau) - Author of [dream2nix](https://github.com/nix-community/dream2nix), (And many other nix-frameworks)

### About using comments as weak sources for typed nix.

- [@roberth](https://github.com/roberth) - nixpkgs Architecture Team / nix core team ?
- [@aakropotkin](https://github.com/aakropotkin/) - nixpkgs Architecture Team
