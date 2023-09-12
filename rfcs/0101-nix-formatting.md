---
feature: nix_formatting
start-date: 2021-08-17
author: \@piegamesde
co-authors: \@infinisil
shepherd-team:
shepherd-leader:
related-issues: https://github.com/serokell/nixfmt/pull/118
---

# Summary

[summary]: #summary

- Decide on basic Nix formatting style guidelines and pick a default formatter for Nix code.
- `nix fmt` (or any future replacement) has to use this formatter as a default
- Automatically format Nixpkgs and enforce the format using CI from then on.
- Establish a formatter team to take care of the long-term maintenance of the code style and formatter.

## Motivation

[motivation]: #motivation

Currently, there is no authoritative formatting style guide for Nix code, including in Nixpkgs.
The current code style in Nixpkgs has evolved organically over time, leading to inconsistencies both across files and language features.
Things are occasionally improved as people touch old files, at the cost of muddying the diff with cosmetic changes.
There are several auto-formatters for Nix code, each with their own style, and none currently used for Nixpkgs.

The goals of this RFC are:

- We want to prevent future debate around how things should be formatted.
- We want to make it as easy as possible for contributors (especially new ones) to make changes without having to worry about formatting.
- Conversely, reviewers should not be bothered with ill-formatted contributions.
- We want a unified Nix code style that's consistent with itself, easily readable, accessible and results in readable diffs.

Non-goals of this RFC:

- Code style aspects that are not purely syntactic (e.g. optional/redundant parentheses, adding `inherit` statements, swapping argument order with `flip`, …)
- Nixpkgs-specific tweaks to the output format (e.g. using attribute names and other context for heuristics about how to best format the contents)
- Extended Nixpkgs-specific linting like nixpkgs-hammering
- Formatting non-Nix files in Nixpkgs
- Applying the format to other repositories within the NixOS organization containing Nix code. It is up to their respective maintainers to make the transition.

## Detailed design

[design]: #detailed-design

There are four main parts to this RFC:
- Establish basic formatting guidelines
- Pick a formatter implementation
- Migrate Nixpkgs to the format and enforce it in CI
- Create a process for future maintenance of the implementation

### Terms and definitions

- Brackets: `[]`
- Braces: `{}`
- Parentheses: `()`

### Formatting style goals and approach taken

There are several goals that the formatting style should match.
These are inherently at conflict with each other, requiring priorisation and making trade-offs.
The resulting choice is always a compromise.

In general, we want the code to be (in no particular order):

- **Short and concise.** Code should not be spread across too many lines, but also without being crammed
- **Readable.** The output format should reflect the semantic flow of the program. It should be clear where expressions start and end. The amount of information per line should be limited.
- **Consistent.** Similar syntax constructs should be formatted similarly.
    - The number of special cases in the formatting rules should be minimized.
- **Diffable and stable.** Small changes to the code should not result in excessive changes in the output.

The general approach taken here is to liberally expand expressions by default, with the goal of being stable, diffable and consistent.
Then, special cases with more compact output for the most common patterns are introduced as needed,
sacrificing those properties in favor of conciseness.
The idea is that this results in a format that is wide by default but compact where it matters.

The interactions between different language features are complex and producing a style that matches the expectations involves a lot of special cases.
Edge cases abound.
Any attempt at creating an exhaustive rule set would be futile.
Therefore, the formatting rules are intentionally under-specified, leaving room for the formatter implementation.
However, the most important or potentially controversial rules are included.
The test suite of the formatter implementation specifies the exact formatting, it is up to the formatter team to adjust it as needed while staying within the design of this RFC.

### General notes

- When deciding between two *equally good* options, currently prevalent formatting style in Nixpkgs should be followed.
- Any two expressions that are fully on a single line must have a common (transitive) parent expression which is also fully on that line.
  - Equivalently: If a maximally parenthesized form of a line fully contains a parenthesis pair, there must be a single outermost pair on that line, meaning it contains all of the others.
  - Example:
    ```nix
    # Bad, because cond and foo are two expressions but they don't have a common parent on the same line
    if cond then foo
    else bar
    ```
- Expressions of the same kind that can be treated as a sequence of expressions on the same level should be treated as such, even though they are technically parsed as a nested tree.
  - This applies to else-if chains, functions with multiple arguments, some operators, etc.
  - Example:
    ```nix
    # This is treated as a sequence of if-then-elsa's chains
    if cond1 then
      foo
    else if cond2 then
      bar
    else
      baz
    ```
- Bad code does not deserve good formatting.

### Indentation

- Two spaces are used for each indentation level.
  - This may be revisited should Nix get proper support for [using tabs for indentation](https://github.com/NixOS/nix/issues/7834) in the future.
- There is no vertical alignment, neither at the start of the line nor within lines.
  - Example:
    ```nix
    {
      # No good!
      foo    = "foo";
      foo123 = arg:
               # This is also no good!
               [ 
                 1
                 2
               ];
    }
    ```
- Indentation levels *must* not be "skipped", i.e. on subsequent lines, indentation can only increase by at most one level, but may decrease arbitrarily many levels.
  - In other words: a line on indentation level 6 could be followed by a line on indentation level 1, but not the other way around.
  - Example:
    ```nix
    buildInputs = [
        # No good!
        foo
      ] // lib.optionals cond [
        bar
      ];

    # No good, indentation increases by two levels in following lines
    (callFunction {
        foo = "bar";
      }
      arg
    );
      
    
    # This is okay, indentation increases only one level per line
    let
      x = {
        a = foo
          bar
          baz;
      }
      # The above decrease by two levels is okay though
    in
    null
    ```
- The indentation level reflects the nested structure of the expression.
  - It should be visibly clear where multi line expressions start and end.
  - Avoid compact position of brackets and braces, i.e. avoid lines like `} {`, `] ++ [` or `] else [`
  - Example:
    ```nix
    let
      # Indentation reflects that we're inside the let in bindings
      myAttr = foo // {
        # …
        # This does not reflect the structure, but a necessary evil to not have too much indentation
      } // someFunction {
        # …
      };
    in
    if foo then
      # The indentation shows that this is the result of the if expression
      {
        # Indentation shows that this is inside an attribute set.
        foo = 10;
      }
    else
      concatMapStringsSep "\n"
        # Indentation shows that these are function arguments
        (str: ''
          ${str}
        '')
        input
    ```

// TODO
<!-- remove-according-to-infinisil>
- Some expressions have an "outer" part and one or more "inner" parts.
  - Tokens of the outer part should not be indented, and preferably on the same vertical height (i.e. start of line)
    - For example starting a line with `] else` is invalid
      ```nix
      if foo then
        {
          # items
        }
      else
        null
      ```
- Some expressions have a "head" and a "body" part.
  - Both are on the same indentation relative to each other.
  ```nix
  with pkgs;
  concatMapStringsSep "\n"
    (str: ''
      ${str}
    '')
    input
  ```

  Expression reference:
  - Atom: Int, Float, String, Path
  - Atom: Variable
  - Outer/Inner: Attrs, List
  - Outer/Inner: Function, Apply
  - Outer/Inner: If/Then/Else
  - Outer/Inner/Body: Let
  - Head/Body: With, Assert
  - Atom: SelectAttr (`.`, `or`), HasAttr (`?`)
  - Atom: `!`
  - Atom: `==`, `!=`, `&&`, `||`, `->`
  - Atom: `//`, `++`, `+`


- Most syntax features have an "outer" part and one or more "inner" parts. The segmentation between these should be clear.
  - Tokens of the outer part should not be indented, and preferably on the same vertical height (i.e. start of line)
  - The inner part may be one of:
    1. Indented by (at least) one level on all lines
    2. Unindented on the first lines then indented on all the remaining ones
    3. Indented by (at least) one level on all lines except the first and last one
      ```nix
      stdenv.mkDerivation {
        # …
      }
      ```
    - Notably, having lines on the same indentation level as the outer part in the middle of the inner part should be avoided, to not obfuscate the boundaries of the outer part.
      ```nix
      # invalid according to rules below, but a necessary evil in this case
      myAttr = foo // {
        # …
      } // someFunction {
        # …
      };
      ```
- Generally the "body" of an expression should not be indented.
- Instead of reducing indentation by starting expressions on the end of the previous line, it is reduced by not indenting the body of some expressions where possible.
  - Example:
    ```nix
    # 1
    let
      foo = 1;
    in
      {
        inherit foo;
      }

    # 2
    let
      foo = 1;
    in {
      inherit foo;
    }

    # 3
    let
      foo = 1;
    in
    {
      inherit foo;
    }
    ```
    In this 
  - This applies for example to `with`, `let … in` (only the in part), function declarations.
  - This reduces complexity in the implementation and special casing.
  - Most of the time, this yields the same indentation level for the body as the alternative, with the only difference being in the first line of the expression.
</remove-according-to-infinisil -->


### Expansion of expressions (TODO)

Unless stated otherwise, any expression that fits onto one single line will be trivially formatted as such.

For expressions which contain a list of sub-expressions, like lists, attribute sets or function calls and declarations, the following applies:

- Expressions containing many sub-expressions inside should be liberally expanded, even if they would fit onto one line.
  - The motivation is to keep the information per line manageable. Usually "number of elements" is a better metric for that than "line length".
  - The cutoff is usually determined empirically based on common usage patterns.
- If formatted with multiple lines, each item should be on its own line.
  - Grouping similar items together can be done by adding blank lines or comments between the groups instead.
  - This also applies to the first item, so e.g. `[ firstElement` in a multi line list is not allowed.

**Examples:**

```nix
{
  # This is on multiple lines, even if it would fit into one
  buildInputs = [
    foo
    bar
    baz
  ];
  
  nativeBuildInputs = [
    # No good! These need to be on their own line!
    foo bar baz
    
    foobarbaz
  ]
}
```

### Attribute sets and lists

- Brackets and braces are generally written with a space on the inside, like `[ `, ` ]`, `{ ` and ` }`.
  - Empty lists and attribute sets are written as`[ ]` and`{ }`, respectively.
- Lists/attrsets can only be on a single line if:
  - They contain at most one element
  - Fit on the line
- Lists with a single element which is a list or attribute set may be written compactly
  - Example:
    ```nix
    mySingletons = [ [ ({
      # stuff in there
    }) ] ];

    mySingletons = [ [
      (function call)
    ] ];
    ```

### Function application

**Description:**

- In a function application chain, the first element is treated as the "function" and the remaining ones as "arguments".
- The last argument receives special treatment, to better represent common coding patterns.
- As much arguments as possible are fit onto the first line.
  - If all but the last argument do fit, then the last argument may start on the same line.
  - If an earlier argument does not fit onto the first line, then itself and all the following ones start on a new line. This is called the expanded form.
  - All arguments that are not on the same line as the function are indented by one level.

**Examples:**

```nix
#1
function arg1 arg2

#2
function arg1 arg2 {
  more = "things";
}

#3
function arg1 arg2 arg3 # reached line limit here
  arg4
  arg5
  [
    1
    2
  ]
  arg7

#4
function arg1
  {
    # stuff
  }
  arg3

#5
function
  {
   # …
  }
  {
   # …
  }

#6
function arg1 (
  function2 args
)
```

**Drawbacks**

- This style sometimes forces lists or attribute sets to start on a new line, with additional indentation of their items.

**Rationale and alternatives**

- Not indenting the arguments, to save some indentation depth. This would be consistent with other constructs like function declarations and let bindings.
- Compacting multiline arguments like this:
  ```nix
  #4b
  function arg1 {
    # stuff
  } arg3

  #5b
  function {
    # …
  } {
    # …
  }
  ```
  - This violates the guideline of the indentation representing the expression structure, and thus reduces readability.
  - This does not work well with line length limits on short arguments like in example #3.

### Function declaration

**Description**

- The body of the function is not indented relative to its arguments.
- Multiple ("simple") identifier arguments are written onto the same line if possible.
- Attribute set arguments always start on a new line; they are not mixed with identifier arguments.
  - If they have few attributes, the argument may be written on a single line, otherwise the expanded form is used.
- Attribute set arguments have their attributes on a new line each with indentation, followed by a trailing comma.

**Examples**

```nix
#1
name: value: name ++ value

#2
name: value:
{
  "${name}-foo" = value;
}

#3
{ pkgs }: pkgs.hello

#4
args@{
  some,
  argument,
  default ? value,
  ...
}:
{
  # body
}

#5
{ pkgs }:
name: value: 
{
  # body
}
```

**Rationale and alternatives**

- Have leading commas for parameters in attribute set arguments, like currently done in Nixpkgs
  ```nix
  #6
  { some
  , arg
  }:
  #7
  args@{
    some
  , argument
  # Single line comment
  , commentedArgument
  , # Comment on the value
    # multiline comment
    default ? value
  , ...
  }:
  # …
  ```
  - This leads to problems with the first argument, as leading commas are not allowed. `{ some` is discouraged by the the style guidelines; `some` should start on a new line instead. Also, this does not work well with `@` bindings.
  - The currently suggested style for commenting items in the Nixpkgs manual (depicted here in `#7`) is not great. However, there are no other good solutions with leading comma style that don't run into other problems.
  - The leading comma style was a lesser-evil workaround for the lack of trailing commas in the Nix language. Now that the language has this feature, there is no reason to keep it that way anymore.

### Operations

**Description**

Chained operations of an operator with the same binding strength are treated as one.
If an operation chain does not fit onto one line, it is expanded such that every operator starts a new line.
Usually, the operands start on the same line as their operator.
Notable exception to this are other nested operators and wide function calls.
The right hand side of an operation (or, if chained, all but the first operand) is indented.

Binary operators (which cannot be chained) use a more compact representation,
where the operator is not required to start a new line even when the operands span multiple lines.

The `//` operator is special cased to such a more compact representation too,
even though this results in multiple violations of the style guidelines.
The motivation for this is that it is often used in places that are very sensitive to the indentation of large attribute sets.

**Examples**

```nix
```

**Drawbacks**

**Rationale and alternatives**

### if

**Desciption**

`if` and `else` keywords always start a line, the if and else bodies are indented.
If the condition does not fit onto one line, then it will start on the next line with indentation, and `then` will be on the start of the line following the condition.
`else if` chains are treated as one long sequence, with no indentation creep on each step.
Only simple `if` statement can be single-line, no `else if` chains.

**Examples**

```nix
#1
if builtins.length matches != 0 then
  { inherit path matches; }
else if path == /. then
  [
    1
    2
  ]
else
  go (dirOf path);

#2
if
  matches != null
  && builtins.length matches != 0
then
  { inherit path matches; }
else if path == /. then
  null
else
  go (dirOf path);
```

**Rationale and alternatives**

- Attribute sets and lists could start on the same line as the if keywords, saving an indentation level on their body:
  ```nix  
  #1
  if builtins.length matches != 0 then {
    inherit path matches;
  } else if path == /. then [
    1
    2
  ] else
    go (dirOf path);
  ```
  - This results in inconsistent vertical start of the keywords, making the structure harder to follow
- Have the `then` on the start of the next line, directly followed by the if body:
  ```nix
  if builtins.length matches != 0
    then { inherit path matches; }
  else if path == /.
    then null
  else go (dirOf path);

  if builtins.length matches != 0
  then { inherit path matches; }
  else if path == /.
  then null
  else go (dirOf path);
  ```

### with, assert

The body after the statement starts on a new line, without indentation.
For `with` expressions there may be exceptions for common idioms, in which the body already starts on the same line.

### In let bindings and attribute sets

Let bindings and attribute sets share the same syntax elements, which are discussed here together.

#### Binders

TODO sort in

- Attribute sets should be force-expanded even if they contain only one element in binders. 
  - Example:
    ```nix
    {
      # Bad
      foo = { bar.baz = "qux"; };
      # Good
      foo = {
        bar.baz = "qux";
      };
    }
    ```

**Description**

Binders have the most special cases to accomodate for many common Nixpkgs idioms.
Generally, the following styles exist, which are used depending on the kind and size of the value:

```nix
#1 single line
foo = "bar";

#2 single line, on a new line
very.long.foo =
  function arg1 arg2 arg3;

#3 multi line, starting on the same line
foo = function {
  # args
};

#4 multi line, starting on a new lien
foo =
  function
    arg1
    arg2
    arg3
;
```

Notable special cases are:

- Single line values that would not benefit from style #2 keep using #1, even if this makes it go above the line limit. This mostly applies to simple strings and paths.
- Attribute set values are *always* expanded. This has the consequence of always forcing nested attribute sets to be multiline (even if they would be single line otherwise because they only contain a single item), which usually is desired.
- "statement-like" expressions like "let", "if" and "with" always use #4 (or #1).
- If the value is a `with` followed by a function application, try to use #3.

**Alternatives**

One could eliminate style #2 by having #4 always start on the first line. This would even reduce indentation in some cases. However, this may look really weird in some cases, especially when the binder is very long.

#### inherit

**Description**

The items are either all on the same line, or all on a new line each (with indentation).

**Examples**

```nix
inherit foo bar baz;
inherit
  foo
  bar
  baz
;
```

#### inherit from

**Description**

If the inherit target is single-line, it is placed on the same line as the `inherit`, even if the following items do not fit onto one line.
Otherwise, it starts on a new line with indentation, like the others.
In that case, the remaining items are force-expanded too, even if they would have fit onto one line in the first place.

**Examples**

```nix
inherit (pkgs) app1 app2 app3;
inherit (pkgs)
  app1
  app2
  # …
  app42
;
inherit
  (pkgs.callPackage ./foo.nix {
    arg = "val";
  })
  attr1
  attr2
;
```

#### Semicolon placement

**Description**

Barring some exceptions, on multiline items, the closing semicolon is on its own line and without indentation.

**Examples**

```nix
foo = bar;
foo = function call {
  # stuff
};
foo =
  let
   foo = "bar"
  in
  some statement
;
```

**Rationale and alternatives**

There are three possible locations to put the semicolon:
Always directly at the end of the content, always on a new line with one indentation level, always on a new lien without indentation.

On a new line with indentation is out, as it looks inferior to without indentation: Without indentation, the semicolon acts as a closing token which visually ends the statement.

Having the semicolon at the end of the statement results in some weird placements, especially since it may be at an arbitrary indentation level depending on the content.

### let

Let bindings are always multiline.
The "let" part is indented one level, but not the "in" part.

### Attribute sets

As per the style guidelines, attribute sets with more than one item are always expanded.
As described under binders, nested attribute sets are always expanded.

### Lists

**Description**

As per the style guidelines, lists with more than one item are always expanded, each item starting on a new line with indentation.

Singleton lists may have a compact form if that single line is another list or attribute set.

**Examples**

```nix
#1
[
  { }
  {
    foo = "bar";
  }
  {
    foo = "bar";
  }
]

#2
[
  [ 1 ]
  [
    2
    3
  ]
]

#3
[ [
  1
  2
  3
] ]

#4
[ {
  foo = "bar";
} ]
```

**Drawbacks**

This special casing of singleton lists can result to weird spacing when combined with parentheses: `([ [`

**Rationale and alternatives**

- Don't have a special compact form for singleton lists, at the cost of an indentation level and two additional lines

### Parentheses

**Description**

TODO

### Formatter tooling

There currently are three automatic formatters in the Nix ecosystem,
[alejandra](https://github.com/kamadorueda/alejandra),
[nixfmt](https://github.com/serokell/nixfmt)
and [nixpkgs-fmt](https://github.com/nix-community/nixpkgs-fmt).

The goal is to end up with one "blessed" formatter, which will officially be used by nixpkgs
and which fills in the details of all the gaps left in the formatting rules.

In order to pick a formatter, we looked at all of the existing implementations and had the following criteria:

- Output malleability: Capability of matching the desired output style
- Maintainability: The code base needs to be updated over time
  - The language the formatter is written in matters
  - The quality of the codebase
  - The libraries the formatter depends on and their maintaindness
  - Maintainability is more important than current maintenance situation, since this is a very long-term project

In contrast, these are not criteria:

- Current output style: Of course starting close to the target goal is preferable, but this is of little worth if the output style can't be easily adjusted if necessary.
- Diff size when applied to current Nixpkgs: As noted in the formatting recommendations, the desired output does take into account existing Nixpkgs idioms and preferred format, but the size of the treewide change is not significant
- Current usage metrics / Popularity
- Performance: Beyond a certain threshold optimizing for this will detract from other criteria.

We looked at all the potential formatter tools and tried to modify them, in order to get a feeling for the code base.

nixpkgs-fmt uses a rule-based approach, where incremental changes are made to the input towards the output.
It advertizes itself as being respectful towards the whitespace choices of the of the developer
(e.g. never compact lists once expanded) and causing fairly minimal diffs. TODO

alejandra has an output style pretty close to our formatting rules out of the box,
not least because there is some overlap between the people involved in its development and the people involved in this RFC.
It works as a pretty-printer, walking over the parsed AST and emitting equivalent code in the desired ouput.
Some aspects of the original input are preserved, mainly the placement of empty lines.
Its code base is pretty easy to get used to, many modifications are pretty easy to make.
However, the code is extremely verbose due to the way comments are handled among other things,
which makes development tedious, with lots of code duplication.
More importantly though, we quickly ran into limitations where it was not easily possible to resolve some issues
or to implement the desired output format.

nixfmt is written in Haskell, and has a slightly steeper learning curve for multiple reasons.
It too is an AST pretty printer (also respecting empty newlines),
however it uses a powerful intermediate representation which then gets rendered,
instead of directly emitting text tokens.
This allows working on the format itself without bothering with some of the details like code comments.
Thanks to that, the format is extremely flexible, and allowed us to implement a lot of changes in little time.
nixfmt has by far the smallest code base, more intricate rules and at the same time less basic indentation errors.

nixpkgs-fmt was quickly set aside because TODO.
Our initial focus was on alejandra, mostly because it was actively maintained and had the aspiration of being a community project.
nixfmt on the other hand received little attention, because of its higher barrier to entry,
and because its output was pretty opinionated towards extreme code compactness.
But after actually trying all of them out (from a developer perspective),
it is pretty clear that nixfmt is the easiest one to modify and to maintain.

### Formatting Nixpkgs

Once the tooling fully conforms to the style guide, Nixpkgs will be fully reformatted. The output of the chosen formatter will be authoritative for Nixpkgs.

The Nix Formatter Team is responsible for the migration of Nixpkgs, and will do so in close coordination with the release managers.

CI will enforce the formatting on every pull request. The formatting hook will pin a version of the formatter for reproducibility, which is independent from the one provided by Nixpkgs. In order to minimize conflicts, the format used for Nixpkgs may only be updated shortly before release branch-off, at which point old pull requests will need to be rebased.

In order to not clutter the history, formatting will be done all at once and the respective commit will be added to `.git-blame-ignore-revs`. In order to not cause any conflicts with back-porting, this will have to be done shortly before a release branch-off. Merge conflicts are unavoidable for most open pull requests.

#### Handling of staging branches

Coordinate with release managers to merge the formatting PR in between two staging runs to avoid conflicts there.

Other long-running branches (haskell, python, etc.) will not be considered, there will however be an announcement so that contributors can coordinate to not have any of these branches in use at that time either.

In case a separate branch can't be merged into master again due to a formatting conflict, `git filter-branch` and a `git rebase` can still be used to resolve it without trouble.

### Maintenance

To help maintaining the formatter, a team is created.
It is given commit access the formatter repository living in the NixOS GitHub organization and has the authority to change the formatting rules.
It is bound to the style guide and rules specified in this RFC.

Should new syntax features be introduced into Nix, the formatter team should be consulted prior to their introduction.

The team initially consists of:
- @infinisil
- @tomberek
- @piegames
- @0x4A6F
- @kamadorueda (if available, TODO: @tomberek sent a message)

The team has the authority to remove and add members as needed.

## Examples and Interactions

[examples-and-interactions]: #examples-and-interactions

### Documentation

TODO move up to detailed design section?

Update [Section 20.1 (Coding conventiones → Syntax)](https://nixos.org/manual/nixpkgs/stable/#sec-syntax) of the Nixpkgs manual. All formatting-specific guidance is removed and replaced with instructions on how to automatically format Nixpkgs instead.

### Automatically generated files

There are automatically generated files in Nixpkgs, with a potentially different format.
This RFC makes no decisions on how to handle such cases, but there are some options:
- Exclude them from the CI via some tooling (e.g. treefmt if that is being used)
- Format them anyway, either after-the-fact or ideally already in the generator tooling itself

### Formatting gotchas requiring manual intervention

Some code patterns in Nixpkgs will result in a sub-optimal format,
because an auto-formatter cannot do exceptions based on context.
A lot of the times though, the same program can be equivalently expressed in a prettier way.

#### CLI argument flags

It is ommon to pass in CLI flags (e.g. to builders) like this:

```nix
[
  "--some-flag" "some-value"
]
```

However, this will be formatted sub-optimally:

```
[
  "--some-flag"
  "some-value"
]
```

The solution is to use a more structured helper function:

```
lib.cli.toGNUCommandLine {} {
  some-flag = "some-value";
}
```

#### Badly placed comments

TODO

#### Long second-to-last function argument

TODO


## Drawbacks

[drawbacks]: #drawbacks

- No automatic code format can be as pretty as a carefully crafted manual one. There will always be "ugly" edge cases.
    - However, we argue that on average the new format will be an improvement, and that contributors should not waste their precious time making the code slightly more pretty.
- Every formatter will have bugs, but the formatter team will be able make fixes
- Having a commit that changes the formatting, can make git blame harder to use. It will need the `--ignore-rev` flag.
    - GitHub also has [builtin functionality](https://docs.github.com/en/repositories/working-with-files/using-files/viewing-a-file#ignore-commits-in-the-blame-view) for this

## Alternatives

[alternatives]: #alternatives

- Keep the status quo of not having an official formatter. The danger is that this creates discord within the Nix community. The current friction and maintainer churn due to bad formatting may arguably be small, but not negligible.
- Pick a different formatter, or a different format
- Pick a formatter and/or format, but don't enforce it in CI, to allow manually tweaking the output if necessary.
- Apply the format incrementally, i.e. only changed files get formatted, to make a more graceful transition. However, such an approach would not improve the amount of merge conflicts, and increase the workload for contributors during that time significantly.

## Unresolved questions

[unresolved]: #unresolved-questions

## Future work

[future]: #future-work

- General style guidelines beyond AST reformatting
- Making widespread use of linters like Nixpkgs-hammering
- Applying the formatter to other repositories within the Nix community
