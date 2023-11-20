---
feature: doc-comment-standard
start-date: 2023-03-27
author: hsjobeki
co-authors: --
shepherd-team: @DavHau; @sternenseemann; @asymmetric
shepherd-leader: @lassulus
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Propose a standard format specification for doc-comments.

This RFC includes two concerns that define a doc-comment:

- Outer format rules to allow distinction between regular comments and doc-comments
- Inner format rules that describe the required format of a doc-comment.

# Definitions

For this RFC, we adopt the following definitions:

- **doc-comment**: A structured comment documenting the code's interface.
- **implementation comment**: A free-form comment to help with understanding the implementation and design concerns that aren't obvious.

The doc-comment properties are grouped into these subcategories:

- **Outer format**: Specifies rules linking code and doc-comments, regarding placement within expressions and the chosen lexical syntax of the comment within the existing Nix language.

- **Inner format**: Specifies rules affecting the comment's actual content. Utilizing content formatting within doc-comments ensures consistent rendering, akin to those achieved with CommonMark.

# Motivation
[motivation]: #motivation

The primary motivation behind doc-comments is to provide documentation for functions, types, modules, and other elements of the codebase. Good documentation is essential for understanding how to use a library or module correctly. Doc-comments allow developers to provide explanations, examples, and usage guidelines directly alongside the code, making it easier for others (and themselves) to understand and use the code effectively.

Many development tools and IDEs (Integrated Development Environments) can parse doc-comments and provide features like autocompletion, hover tooltips, and documentation pop-ups. This tooling support enhances developer productivity by making it easier to explore and use functions and modules without referring to external documentation.

Writing doc-comments also encourages developers to think about the clarity and correctness of their code. By documenting functions and modules, developers are more likely to write clean, self-explanatory code, which can lead to better code quality and maintainability. 

Overall doc-comments can serve as a vital tool for documentation, code understanding, tooling support, onboarding for new contributors and code quality.
 
# Goals
The following are the envisioned goals.

- Create distinct outer and inner formats for Nix doc-comments to enable accurate automated parsing and extraction. 
- Ensure clear differentiation from internal comments, making them accessible to tooling solutions such as documentation rendering and building. 

- Convert `Nixpkgs` comments intended for documentation into this format.

- In addition, the developer's experience and adherence to established conventions should be taken into account. Equally important is ensuring that doc comments remain effortless to compose and comprehend, though it is essential to acknowledge that this aspect may vary subjectively based on personal preferences.

## Non-goals

- Discuss in which tool doc-comments are parsed and rendered. This could be an external tool, native nix, or something else entirely, but that's out of scope for this RFC.

- How to style or format the commonmark inside of a doc-comment.

- Implementation details are not specified. The RFC shepherd group has some (feature incomplete) POCs sufficient for a generic specification. (See [Native support in Nix](#Native-support-in-Nix) )

## Current State

A third-party tool called [nixdoc](https://github.com/nix-community/nixdoc) has emerged, which codifies its own rules as to the internal and external formats of a Nix doc-comment. This tool has seen some adoption, notably for the Nixpkgs `lib` functions.

Here is an example of the format understood by *nixdoc*:

```nix
  # Nixpkgs/lib/trivial.nix

  /* The constant function

     Ignores the second argument. If called with only one argument,
     constructs a function that always returns a static value.

     Type: const :: a -> b -> a
     Example:
       let f = const 5; in f 10
       => 5
  */
  const =
    # Value to return
    x:
    # Value to ignore
    y: x;
```

## Current problems

### Multiplicity of formats

Within Nixpkgs alone, several conventions for doc-comments have emerged; see [1], [2] and [3].

Notably, most doc-comments utilize some fraction of the CommonMark syntax, even if they are not meant to be rendered.

[1]: https://github.com/NixOS/Nixpkgs/blob/master/pkgs/build-support/trivial-builders/default.nix
[2]: https://github.com/NixOS/Nixpkgs/blob/master/pkgs/stdenv/generic/make-derivation.nix
[3]: https://github.com/NixOS/Nixpkgs/blob/master/nixos/lib/make-disk-image.nix

Generally, the format for writing documentation strings is **not formally specified**.

Among the formats encountered in the wild, the one used in `Nixpkgs/lib` is the only one intended to be rendered as part of an API documentation via the nixdoc third-party tool, whose syntax has not been standardized.

### Impossible to differentiate from internal comments

The lack of a formal definition of a doc-comment also means there is no reliable way to distinguish them from internal comments, which makes it impossible to access doc-comments from tooling. Furthermore, it makes it very hard to generate accurate and complete reference documentation.

### References to the problems above

This curated link collection highlights the Nix ecosystem's inconsistencies, a primary focus of this RFC.

#### Nixpkgs - comment examples

- [lib/attrsets](https://github.com/NixOS/Nixpkgs/blob/5323fbf70331f8a7c47f1b4f49841cf74507f77f/lib/attrsets.nix)
- [trivial-builders](https://github.com/NixOS/Nixpkgs/blob/5323fbf70331f8a7c47f1b4f49841cf74507f77f/pkgs/build-support/trivial-builders/default.nix)
- [stdenv/mkDerivation](https://github.com/NixOS/Nixpkgs/blob/5323fbf70331f8a7c47f1b4f49841cf74507f77f/pkgs/stdenv/generic/make-derivation.nix)
- [nixos/lib/make-disk-image](https://github.com/NixOS/Nixpkgs/blob/5323fbf70331f8a7c47f1b4f49841cf74507f77f/nixos/lib/make-disk-image.nix)

# Design
[design]: #detailed-design

In the following, we give a comprehensive overview of the decisions that we've made. Detailed arguments for and against every decision can be found in the [Decisions](#Decisions) section

## CommonMark

**CommonMark according to [RFC 72](https://github.com/NixOS/rfcs/blob/master/rfcs/0072-commonmark-docs.md) is the content of all doc-comments.**

Adopting CommonMark as the content for all doc-comments brings the benefits of widely accepted and understood documentation format in tech projects while maintaining profitability and consistency within the Nix ecosystem by aligning with existing [NixOS/RFC-72](https://github.com/NixOS/rfcs/blob/master/rfcs/0072-commonmark-docs.md).

## `/** */` is the doc-comment format

The decision to use /** to start a doc-comment ensures a unique distinction from regular comments while still allowing seamless writing without IDE or editor support. A single choice provides the best developer experience and simplifies tooling.

## Placement

**The placement describes the relationship between doc-comments and the documentable node.**

A **documentable node** can be:

- Expression 
- Binding 
- Lambda Formal

The following rules apply in descending order of precedence:

- Doc-comments are placed before the **documentable node**. Only whitespace or non-doc comments are allowed in between. ([Examples](#basic-examples)) 

- The documentation present before the `attribute path` describes the body of the attribute. ([Examples](#Attributes))
    - In case placement is ambiguous, the one closer to the body has higher precedence. ([Examples](#ambiguous-placement))

### Examples

#### Basic examples

Only whitespaces between the `documentable node` and the `doc-comment`

```nix
/**Doc for anonymous lambda function*/
↓
x: x;
```

```nix
listToAttrs [
  { name = "foo"; value = /**Documentation for '1'*/1; }
]
```

#### Attributes 

It is allowed to write the documentation before the attribute instead of placing it right before the body.

```nix
/**Doc for lambda function bound to a variable*/
           ↓
assigned = x: x;
```

```nix
{
    /**This documents the specialisation `map (x: x)` */
          ↓
    foo = map (x: x);          
}
```

### Attribute path

```nix
{
  /** Doc 1 bound to 'c' */
      ↓   ↓
  a.b.c = 1;
}

# Documents only the expression bound to 'c'. NOT the attribute set bound to 'a' or 'b'.
```

#### Ambiguous placement

```nix
/**Doc B*/
int = /**Doc A*/1;

# Documentation is 'Doc A' because it is directly next to the documentable body.
```

#### Dynamic attribute

```nix
{
    /** Documentation for '2' */
                                   ↓
    ${let name = "bar"; in name} = 2;
}
# Dynamic attribute
```

#### `Let .. in ..` binding

```nix
let
 /** Documentation for the id function*/
     ↓
 a = x: x;
in
 a

# Documentation can still be retrieved.
```

#### Lambda formals

```nix
/**Doc for the whole lambda function*/
{
 /**Doc for formal 'a'*/
 a
}:
 a              
```

# Decisions

Each subsection here contains a decision along with arguments and counter-arguments for (+) and against (-) that decision.

> Note: This RFC does not promote any tool; It focuses only on the format, not implementation. At the same time, this RFC must be technically feasible.

## `/**` to start a doc-comment

**Observing**: The use of `/**` to initiate a doc-comment is a widely accepted convention in many programming languages. It indicates the beginning of a comment block specifically meant for documentation purposes.

**Considering**: Doc-comments' outer format should be a distinctive subset of regular comments. Nevertheless, it should allow native writing without an IDE or editor support.

**Decision**: `/** {content} */` where `/**` is used to start the doc-comment.

`Example`

````nix
{
  /**
  The identity function

  Describes in every detail why 
  this function is important and how to use it.

  # Examples

  ```
  id "foo"
  ->
  "foo"
  ```

  */
  id = x: x; 
}
````

<details>
<summary>Arguments</summary>

- (+) It is mostly compatible with the currently used multiline comments.
- (+) Is a strict subset of multiline comments, which allows multiline documentation natively.
- (+) Does not need editor support for productive usage. (In contrast to, e.g., `##`)
- (+) Allows copy-pasting content without the need for re-formatting.
  - (-) Partially re-formatting just like in multiline Nix strings (`''`) might still be needed.
- (-) Is visually less distinctive.
- (-) Indentation is more complex and visually less present.
    - (+) It would be most intuitive if its indentation logic implements Nix's magic multiline strings.
- (-) Takes up more vertical space
- (+) Takes up less horizontal space. (In contrast to, e.g., `##` lines do not have to be prefixed)
- (+) Only one character to change the semantics of the whole comment. 
    - (+) Allows to add and remove things from the documentation quickly.
    - (-) Accidentally adding/removing could happen.
    
</details>


## CommonMark as the content of doc-comments

**Observing**: The use of CommonMark, a widely recognized and standardized format for documents, is prevalent in the documentation of code and software libraries.

**Considering**: Doc-comments' content should be intuitive to read and write and straightforward to render. Furthermore it should follow established conventions in the nix ecosystem.

**Decision**: CommonMark is the content of all doc-comments.

> Markdown is the most accepted and understood format for writing documentation in tech projects. Also, following the existing RFC-72 is highly profitable and consistent for the Nix ecosystem.

<details>
<summary>Arguments</summary>

- (+) CommonMark is the official format for Nix documentation; Decided in [RFC72](https://github.com/NixOS/rfcs/blob/master/rfcs/0072-commonmark-docs.md).
    - (+) It Would be consistent if this RFC builds upon the previous one.
    - (+) Further Arguments for CommonMark, in general, can be found in RFC72
- (+) Allows copy-paste from and to markdown files. We allow easy refactoring if documentation arises and needs to be split into separate files.
- (-) Strictly binding doc comments content to commonMark might restrict users.
    - (+) Users/Tools can still use regular comments or develop alternative solutions.
- (-) CommonMark does not specify the current rich features from nixdoc, such as predefined sections and structures that could be used as a source for automated toolings. Such as types for type-checking or examples to run automated tests
    - (+) Future tools can still build their conventions on top of this RFC. They might not directly specify them in an RFC but be a tool developers choose for a specific codebase. However, we have yet to get those tools. So, it is good when rich features remain unspecified.
  
</details>

# Drawbacks
[drawbacks]: #drawbacks

## Changes the existing comments inside the code base

This could be (partially) automated. (see our [codemod](https://github.com/nix-community/docnix/tree/3c0531cb5b4c9f3e9069b73d19e6c4be8508d905/codemod) )

Also, the migration could be performed piecemeal, starting perhaps with Nixpkgs `lib`.

See future work.

## Breaking the Nixpkgs manual

This is a breaking change to the current Nixpkgs manual tooling Nixpkgs library function documentation.

Please take a look at future work.

# Alternatives
[alternatives]: #alternatives

## All considered outer formats

| Property / Approach | `##` | `/** */` | `Javadoc` | `/*\|` or `/*^`  | All comments are doc-comments |
|---|---|---|---|---|---|
| Inspired by | Rust | Current Nixpkgs `lib` | C++/Java/JavaScript | Haskell Haddock | Current Nixpkgs.lib |
| Changes the existing code by | Much | Less | Even More | Less | ? |
| Needs Termination | No | Yes | Yes | Yes | ? |
| Indentation | Clear | like Nix's multiline strings, thus **Intuitive** | Clear | ? | ? |
| Needs vertical space  | No | Yes | Yes | Yes | ? |
| Visual distinction from comments | High | Low | Medium | Medium | No distinction at all |
| Needs Autocompletion (Language Server) to continue the next line. | Yes | No | Yes | No | ? |
| Punctuation Variations / Amount of different special characters | 1 (Less) | 2 (Medium) | 2 (Medium) | 3 (More) | None |
| Markdown compatibility (also depends on indentation clarity) | **Visual conflicts with headings `# Title`** | Good | Medium | Good | Only with multiline comments |
| breaks when interrupted with newlines | Yes | No | ? | No | |
| Simplicity (Brainload) | Medium | Simple | Complex | More Complex | |

### Refactoring note

**Observing**: From a refactoring perspective, it might also be interesting to see how many conflicts the different formats would cause.

Nixpkgs comments:

- `##` ~4k usages
- `#` ~20k usages
- `/*` ~6k usages
- `/**` 160 usages
   - `/**{content}*/` 10 usages. Need to be migrated, if using different convention.
   - `/**/` 35 usages. They still are non-doc-comments

Choosing `/**` or subsets would cause minor conflicts within current Nixpkgs. While this is NOT the main reason for the final decision, it must be considered.

## Just free text as a content format

While this allows the most freedom, it is usually considered the best option, not creating any restrictions.

- [RFC72](https://github.com/NixOS/rfcs/blob/master/rfcs/0072-commonmark-docs.md) defines commonMark as the official documentation format.
This is why we decided to follow this convention. Writing plain text is still possible.

# Unresolved questions
[unresolved]: #unresolved-questions

- Migration path for Nixpkgs comments. 
- How to document the `arguments`. Should there be some markdown equivalent to `@param`, i.e. `# Params`?  This RFC intentionally leaves this question unanswered, allowing for further discussion and decision-making in the future.

# Future work
[Future]: #future-work

## Single-line doc-comments 

Single-line doc-comment remained unspecified by this RFC. It might be an option to specify how they behave in the future.

## Migrate existing Nixpkgs comments

Reformatting existing doc-comments in Nixpkgs.

Action points:

- [ ] Change comments to markdown.
- [ ] Migrate nixdoc 'argument documentation' format.

### Migration Example

The following shows one of the many possible ways to migrate the current Nixpkgs `lib` comments.

> We managed to partially automate this effort with a [codemod](https://github.com/nix-community/docnix/tree/3c0531cb5b4c9f3e9069b73d19e6c4be8508d905/codemod)

> Note: The current `nixdoc` feature 'Function arguments' uses a different mental model than this RFC. Arguments must now be explicitly documented inside of the lambda documentation.

`lib/attrsets.nix (old format)`
````nix
/* Filter an attribute set by removing all attributes for which the
   given predicate return false.

   Example:
     filterAttrs (n: v: n == "foo") { foo = 1; bar = 2; }
     => { foo = 1; }

   Type:
     filterAttrs :: (String -> Any -> Bool) -> AttrSet -> AttrSet
*/
filterAttrs =
  # Predicate taking an attribute name and an attribute value, which returns `true` to include the attribute or `false` to exclude the attribute.
  pred:
  # The attribute set to filter
  set:
  listToAttrs (concatMap (name: let v = set.${name}; in if pred name v then [(nameValuePair name v)] else []) (attrNames set));
````

->

`lib/attrsets.nix (new format)`
````nix
/**
  Filter an attribute set by removing all attributes for which the
  given predicate return false.

  # Example

  ```nix
  filterAttrs (n: v: n == "foo") { foo = 1; bar = 2; }
  => { foo = 1; }
  ```

  # Type

  ```
  filterAttrs :: (String -> Any -> Bool) -> AttrSet -> AttrSet
  ```

  # Arguments

  - [pred] Predicate taking an attribute name and an attribute value, which returns `true` to include the attribute, or `false` to exclude the attribute.
  - [set] The attribute set to filter
*/
filterAttrs =
  pred:
  set:
  listToAttrs (concatMap (name: let v = set.${name}; in if pred name v then [(nameValuePair name v)] else []) (attrNames set));
````

## Tooling

All current rendering tooling solutions should support displaying the specified doc-comment format.

Currently, at least:

### Nixpkgs Manual renderer

The current Nixpkgs manual needs to be adapted to this change.

We expect changes in the following to be necessary:

- [nixos_render_docs](https://github.com/NixOS/Nixpkgs/tree/e4082efedb483eb0478c3f014fa851449bca43f9/pkgs/tools/nix/nixos-render-docs/src) 
- [nixdoc](https://github.com/nix-community/nixdoc)

## References

### Other Conventions

- [Rust](https://doc.rust-lang.org/stable/reference/comments.html#doc-comments)
- [Python](https://peps.python.org/pep-0257/)
- [JSDoc](https://jsdoc.app/)
- [Go Doc Comments](https://go.dev/doc/comment)

### Related tools

- [Nixdoc](https://github.com/nix-community/nixdoc)
- [Rustdoc](https://doc.rust-lang.org/rustdoc/how-to-write-documentation.html)
- [Doxygen](https://www.doxygen.nl/)

## Related discussions

- https://discourse.nixos.org/t/2023-04-13-documentation-team-meeting-notes-41/27264

- https://github.com/NixOS/nix/issues/3904
- https://github.com/NixOS/nix/issues/228


- https://github.com/NixOS/nix/pull/5527
- https://github.com/NixOS/nix/pull/1652 

[#1652](https://github.com/NixOS/nix/pull/1652) gets closest to what this RFC imagines, implementation is almost done. It has some limitations but was not merged due to uncertainty and complexity. 
