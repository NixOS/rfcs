---
feature: nix_formatting
start-date: 2021-08-17
author: piegamesde
co-authors: infinisil
pre-RFC reviewers: tomberek, 0x4A6F
shepherd-team: das_j, tomberek, 0x4A6F, infinisil
shepherd-leader: infinisil
related-issues: https://github.com/serokell/nixfmt/pull/118, https://github.com/piegamesde/nixpkgs/pull/4
---

# Nix formatting

## Summary

The RFC consists of these main parts, see the [detailed design section](#detailed-design) for more information:

- Define the initial _standard Nix format_
- Establish the _Nix formatter team_
- Create the _official Nix formatter_ implementation
- Reformat Nixpkgs with the official Nix formatter
- Require that any default formatting in the Nix CLI must use the official Nix formatter

## Motivation

Currently, there is no authoritative formatting style guide for Nix code, including in Nixpkgs.
The current code style in Nixpkgs has evolved organically over time, leading to inconsistencies both across files and language features.
Things are occasionally improved as people touch old files, at the cost of muddying the diff with cosmetic changes.
There are several auto-formatters for Nix code, each with their own style, and none currently used for Nixpkgs.

The goals of this RFC are:

- People should not be bothered with formatting.
- We want to prevent future debate around how things should be formatted.
- We want to make it as easy as possible for contributors (especially new ones) to make changes without having to worry about formatting.
- Conversely, reviewers should not be bothered with poorly formatted contributions.
- We want a unified Nix code style that's consistent with itself, easily readable, accessible and results in readable diffs.

Non-goals of this RFC:

- Code style aspects that are not purely syntactic (e.g. optional/redundant parentheses, adding `inherit` statements, swapping argument order with `flip`, ...)
- Nixpkgs-specific tweaks to the format (e.g. using attribute names and other context for heuristics about how to best format the contents)
- Extended Nixpkgs-specific linting like nixpkgs-hammering
- Formatting non-Nix files in Nixpkgs (that's for [treefmt](https://github.com/numtide/treefmt))
- Applying the format to other repositories within the NixOS organization containing Nix code.
  It is up to their respective maintainers to make the transition.

## Goals and approach

There are several goals that the formatting style should match.
These are inherently in conflict with each other, requiring prioritisation and making trade-offs.
The resulting choice is always a compromise.

In general, we want the code to be (in no particular order):

- **Short and concise.** Code should not be spread across too many lines, but also without being crammed
- **Readable.** The output format should reflect the semantic flow of the program.
  It should be clear where expressions start and end.
  The amount of information per line should be limited.
- **Consistent.** Similar syntax constructs should be formatted similarly.
    - The number of special cases in the formatting rules should be minimized.
- **Diffable and stable.** Small changes to the code should not result in excessive changes in the output.

The general approach taken here is to liberally expand expressions by default, with the goal of being stable, diffable and consistent.
Then, special cases with more compact output for the most common patterns are introduced as needed,
sacrificing those properties in favor of conciseness.
The idea is that this results in a format that is spread-out by default but compact where it matters.

The interactions between different language features are complex and producing a style that matches the expectations involves a lot of special cases.
Any attempt at creating an exhaustive rule set would be futile.
Therefore, the formatting rules are intentionally under-specified, leaving room for the formatter implementation.
However, the most important or potentially controversial rules are included, as well as some general meta-rules.

When deciding between two *equally good* options, currently prevalent formatting style in Nixpkgs should be followed.
The emphasis here is on "equally good".
We should not fear making radical changes to the current style if there are sufficient arguments in favor of it.

*Bad code does not deserve good formatting.*

## Detailed design

### Standard Nix format

The _standard Nix format_ defines the officially recommended way that Nix code should be formatted.

The initial version of the standard Nix format is defined in a section towards the end:

[Initial standard Nix format](#initial-standard-nix-format).

Significant changes to the standard Nix format must go through another RFC.

The latest version of the standard Nix format must be in a file on the main branch of the [official Nix formatter](#official-nix-formatter).

### Nix formatter team

The _Nix formatter team_ is established, it has the responsibility to
- Maintain the [official Nix formatter](#official-nix-formatter)
- Regularly [reformat Nixpkgs](#reformat-nixpkgs) with it

See the linked sections for more information.

Initially the team consists of these members:
- @piegames (author of this RFC, shepherd of the original formatting RFC)
- @infinisil (from Tweag, co-author of this RFC, shepherd of the original formatting RFC)
- @tomberek (from Flox, shepherd of the original formatting RFC)
- @0x4A6F (shepherd of the original formatting RFC)
- @Sereja313 (from Serokell, original sponsors of nixfmt)
- @dasJ (from Helsinki Systems, writes Nix)

Team member updates are left for the team itself to decide.

### Official Nix formatter

The Nix formatter team is given the authority and responsibility of
creating and maintaining the _official Nix formatter_ implementation.
This is a repository in the NixOS GitHub organisation.
The repository will initially be based on [this nixfmt pull request](https://github.com/serokell/nixfmt/pull/118).
This pull request has been developed along with this RFC and is already reasonably close to the proposed initial standard format.

Any release of the official Nix formatter must conform to the latest version of the [standard Nix format](#standard-nix-format).

The latest release of the official Nix formatter should support the Nix language syntax of the latest Nix release.
The Nix formatter team should be consulted before the Nix language syntax is changed.

### Reformat Nixpkgs

For formatting Nixpkgs itself, a pinned release version of the official Nix formatter must be used.
CI must generally enforce all Nix files in Nixpkgs to be formatted with this version at all times.
Automatically generated files may be handled differently, see [this sub-section](#automatically-generated-files).

For every bump of the pinned formatter,
the files of Nixpkgs must thus be re-formatted accordingly.
Commits that reformat Nixpkgs will be added to `.git-blame-ignore-revs`,
which can then be [ignored in tooling](#git-blames).
The Nix formatter team is responsible for this task.

In order to minimize conflicts especially when back-porting,
the pinned formatter should preferably only be updated shortly before the release branch-off.
This should be done in coordination with the NixOS release managers,
so this information must be added to the [NixOS release wiki](https://nixos.github.io/release-wiki/).

#### Nix code in documentation

Nix code in Nixpkgs documentation, such as the Nixpkgs manual, the NixOS manual, NixOS options, `CONTRIBUTING.md` and co. should also be formatted with the pinned release version of the official Nix formatter.

#### Automatically generated files

There are automatically generated files in Nixpkgs, with a potentially different format.
This RFC makes no decisions on how to handle such cases, but there are some options:
- Exclude them from the CI via some tooling (e.g. treefmt if that is being used)
- Format them anyway, either after-the-fact or ideally already in the generator tooling itself

#### Contributor doc updates

The [Nixpkgs contributor documentation](https://github.com/NixOS/nixpkgs/blob/master/CONTRIBUTING.md) should be updated to contain all relevant information.
All formatting-specific guidance is removed and replaced with instructions on how to automatically format Nixpkgs instead.

### Default Nix CLI formatting

In case the Nix CLI ever gets support for running a default Nix formatter,
the official Nix formatter must be used.

## Examples and Interactions

### Git blames

Reformatting commits that get added to `.git-blame-ignore-revs` [won't get shown](https://docs.github.com/en/repositories/working-with-files/using-files/viewing-a-file#ignore-commits-in-the-blame-view) in blames on GitHub,
and can be ignored in the `git blame` command using [`--ignore-revs-file`](https://www.git-scm.com/docs/git-blame#Documentation/git-blame.txt---ignore-revs-fileltfilegt).

### Formatting gotchas requiring manual intervention

Some code patterns in Nixpkgs will result in a sub-optimal format,
because an auto-formatter cannot do exceptions based on context.
A lot of the times though, the same program can be equivalently expressed in a prettier way.

#### CLI argument flags

It is common to pass in CLI flags (e.g. to builders) like this:

```nix
[
  "--some-flag" "some-value"
]
```

However, this will be formatted sub-optimally:

```nix
[
  "--some-flag"
  "some-value"
]
```

If the CLI also accepts GNU-style flags, a more structured helper can be used instead:

```nix
lib.cli.toGNUCommandLine { } {
  some-flag = "some-value";
}
```

#### Singleton lists

Sometimes a list only needs a single element
and there's no expectation to add more in the future.
This would be formatted like this:

```nix
{
  list = [
    {
      foo = 10;
      bar = 20;
    }
  ];
}
```

In this case one level of indentation can be saved using [`lib.singleton`](https://nixos.org/manual/nixpkgs/stable#function-library-lib.lists.singleton):

```nix
{
  list = lib.singleton {
    foo = 10;
    bar = 20;
  };
}
```

## Drawbacks

- No automatic code format can be as pretty as a carefully crafted manual one. There will always be "ugly" edge cases.
  - However, we argue that on average the new format will be an improvement,
    and that contributors should not waste their time making the code slightly more pretty.
- Every formatter will have bugs, but the Nix formatter team will be able to make fixes.
- Having a commit that changes the formatting, can make git blame harder to use.
  - This can be [worked around in interfaces](#git-blames).

## Alternatives

- Keep the status quo of not having an official formatter.
  The danger is that this creates discord within the Nix community.
  The current friction and maintainer churn due to bad formatting may arguably be small, but not negligible.
- Specify a different format.
- Specify a format, but don't enforce it in CI, to allow manually tweaking the output if necessary.
- Apply the format incrementally, i.e. only changed files get formatted, to make a more graceful transition.
  However, such an approach would not reduce the amount of merge conflicts,
  and increase the workload for contributors during that time significantly.

## Unresolved questions

## Future work

- General style guidelines beyond AST reformatting
- Making widespread use of linters like Nixpkgs-hammering
- Enforcing the format to other official repositories

-----

## Terms and definitions:

- **Brackets:** `[]`
- **Braces:** `{}`
- **Parentheses**: `()`
- **Expressions:**
  All syntax nodes that would be a syntactically correct Nix program on their own.
- **Terms:** The follwoing expressions are called terms
  - Variables, int, float, string, path, list, set, selection, all parenthesised expressions
  - As a rule of thumb: Expressions which can be used as list items (without parentheses)
- **Absorption:**
  A multiline expression can have an alternative layout depending on the context.
  In that case, it will start on the end of the current line instead of a new line,
  potentially saving a level of indentation of its content.
  ```nix
  {
    # The right-hand side of bindings is an example of a situation where absorption improves the style.
    absorbed = with bar; [
      1
      2
      3
    ];
    notAbsorbed =
      with bar; # Placing a comment here will force the non-absorbed, multiline layout.
      [
        1
        2
        3
      ];

    # In this case, absorption does not reduce the indentation level of the set.
    absorbed' =
      let
        qux = 1;
      in
      # { is absorbed
      bar: baz: {
        # <-- same level
      };

    notAbsorbed' =
      let
        qux = 1;
      in
      way:
      too:
      many:
      arguments:
      {
        # <-- same level
      };
  }
  ```
- **Absorbable Terms:**
  Attribute sets, lists, and multiline `''` strings are called absorbable terms. Parenthesized absorbable terms are absorbable terms again too.

## Initial standard Nix format

- Line breaks may be added or removed, but empty lines must not be created. Single empty lines must be preserved, and consecutive empty lines must be collapsed into a single empty line.
  This allows the formatter to expand or compact multi-line expressions, while still allowing grouping of code.

  For example, formatting this code:
  ```nix
  [
    0 10

    (
      20 + 1
    )


    30
  ]
  ```

  turns into this:
  ```nix
  [
    0  # Line break added
    10

    (20 + 1) # Line breaks removed
             # Consecutive empty lines turned into a single empty line
    30
  ]
  ```

- Expressions of the same kind that can be treated as a sequence of expressions on the same level should be treated as such, even though they are technically parsed as a nested tree.
  - This applies to else-if chains, functions with multiple arguments, some operators, etc.
  - Example:
    ```nix
    # This is treated as a sequence of if-then-else chains, instead of indenting the second if as part of the else body
    if cond1 then
      foo
    else if cond2 then
      bar
    else
      baz
    ```

- Indentation should reflect the expression structure.
  Example:
  ```nix
  # Bad, the indentation misleads the user
  {
    foo = {
    bar = if
    baz == null then 10
      else 20
    ;
  }; }

  # Good
  {
    foo = {
      bar =
        if baz == null then
          10
        else
          20;
    };
  }
  ```

### Editor Config

This [editor config](https://editorconfig.org/) specifies the basic details about Nix files:

```editorconfig
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true
charset = utf-8
indent_style = space
```

### Single-line common ancestor expression rule

For any two (sub-)expressions that are fully on a common single line, their smallest common ancestor expression must also be on the same line.

**Example**

```nix
# Bad, expressions cond and foo are fully on the same line,
# but their smallest common ancestor expression is the entire if-then-else, which spans multiple lines
if cond then foo
else bar

# Okay, cond, foo and bar have the if-then-else as a common ancestor expression,
# which is also fully on the same line
if cond then foo else bar

# Bad, due to function application precedence, the smallest common ancestor expression
# of foo and bar is `foo || bar baz`, which spans two lines
foo || bar
  baz
```

**Rationale**

This rule has turned out to be very practical at catching code that could be potentially hard to understand or edit.

### Line length

- There should be a configurable _soft_ line length limit, limiting the number of characters on one line without counting the leading indentation.
  The default should be 100 characters.
- There may also be a configurable _hard_ line length limit, which includes the leading indentation.
- String-like values such as strings, paths, comments, urls, etc. may go over the hard line length limit.

### Indentation

- Two spaces must be used for each indentation level.
  - This may be revisited should Nix get proper support for [using tabs for indentation](https://github.com/NixOS/nix/issues/7834) in the future.
- Vertical alignment must be ignored, both at the start of the line and within lines.
  - Examples:
    ```nix
    {
      # Bad, vertical alignment Within lines
      linux    = { execFormat = elf;     families = {              }; };
      netbsd   = { execFormat = elf;     families = { inherit bsd; }; };
      none     = { execFormat = unknown; families = {              }; };
      openbsd  = { execFormat = elf;     families = { inherit bsd; }; };

      # Bad, vertical alignment at the start of line
      optExecFormat =
        lib.optionalString (kernel.name == "netbsd" &&
                            gnuNetBSDDefaultExecFormat cpu != kernel.execFormat
                           )
                           kernel.execFormat.name;
    }
    ```
- Increasing indentation levels must not be "skipped": On subsequent lines, indentation can only increase by at most one level, but may decrease arbitrarily many levels.
  - Examples:
    ```nix
    buildInputs = [
        foo # <-- Bad, indentation increases by 2 levels
      ] // lib.optionals cond [
        bar
      ];

    attribute = { args }: let
        foo = "bar" # <-- Bad, indentation increases by 2 levels
      in
        foo;

    (callFunction {
        foo = "bar"; # <-- Bad, indentation increases by 2 levels
      }
      arg
    )

    # This is okay, indentation increases only one level per line
    let
      x = {
        a = foo
          bar
          baz;
      }; # <-- The decrease by two levels here is okay
    in
    null
    ```

### Expansion of expressions

Unless stated otherwise, any expression that fits onto one single line must be trivially formatted as such.

For list elements, attributes, and function arguments, the following applies:

- If expanded into multiple lines, each item must be on its own line.
  - Grouping similar items together can be done by adding blank lines or comments between the groups instead.
  - This also applies to the first item, so e.g. `[ firstElement` in a multi line list is not allowed.
- Long sequences of items should be liberally expanded, even if they would fit onto one line character-wise.
  - The motivation is to keep the information per line manageable. Usually "number of elements" is a better metric for that than "line length".
  - The cutoff is usually determined empirically based on common usage patterns.

**Examples:**

```nix
{
  buildInputs = [
    foo
    bar
    baz

    somethingElse
  ];

  systemd.services = {
    foo = { };
    bar = { };
  };

  inherit
    lib
    foo
    bar
    baz
    ;
}
```

### Function application

- In a function application chain, the first element is treated as the "function" and the remaining ones as "arguments".
- As many arguments as possible must be fit onto the first line.
  - If all but the last argument do fit, then the last argument may get absorbed, i.e. also start on the first line.
  - If an earlier argument does not fit onto the first line, then that argument and all the following ones must start on their own line.
  - All arguments that are not on the same line as the function must be indented by one level.

**Examples:**

```nix
# All arguments fit onto the first line
function arg1 arg2

# The line length limit is reached, so the remaining arguments need to be on their own lines
function arg1 arg2 arg3
  arg4
  arg5

# The last argument is a multiline expression, so it doesn't fit on the first line,
# but it can still start on the first line
function arg1 arg2 {
  more = "things";
}

# The second argument doesn't fit on the first line, but it's not the last argument,
# so it needs to start on a new line
function arg1 arg2
  {
    more = "things";
  }
  arg3

# Same with more multiline arguments
function
  {
    a = 1;
    b = 2;
  }
  {
    c = 1;
    d = 2;
  }
```

**Drawbacks**

- This style sometimes forces lists or attribute sets to start on a new line, with additional indentation of their items.

**Alternatives**

- Compacting multiline arguments like this:
  ```nix
  function arg1 {
    # stuff
  } arg3

  function {
    # ...
  } {
    # ...
  }
  ```
  - This violates the guideline of the indentation representing the expression structure, and thus reduces readability.

### Function declaration

- The body of the function must not be indented relative to its first arguments.
- A small number of ("simple") identifier arguments can be written onto the same line.
  - Otherwise they're each on their own line.
  - The body may get absorbed here
- Attribute set arguments must always start on a new line and they must not be mixed with identifier arguments.
  - If they have few attributes, the argument may be written on a single line
  - Otherwise each attribute must be on its own line with indentation, followed by a trailing comma.
- Due to structural similarity and for consistency reasons, attribute set arguments with a default value follow the same rules as [bindings](#bindings).

**Examples**

```nix
#1
name: value: name ++ value

#2 absorption
name: value: ''
  ${name} = ${value};
''

#3
name: value:
name
++ value
++ more stuff making the line too long

#4
{ pkgs }: pkgs.hello

#5
args@{
  some,
  argument,
  default ? value,
  ...
}:
{
  # body
}

#6
{ pkgs }:
name: value: 
{
  # body
}

#7: These would be over the line length limit on a single line
aaaa:
bbbb:
cccc: 
dddd:
eeee:
null

#8: @ patterns can also come afterwards
{ pkgs }@args: pkgs.hello
```

**Alternatives**

- Have leading commas for parameters in attribute set arguments, like currently done in Nixpkgs.

  - This makes attribute set arguments less likely to be confused with lists.
  - It's easier to see where arguments start and end.
  ```nix
  { some
  , arg
  }:
  
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
  # ...
  ```

  Problems with this alternative:
  - Moving items around with this style may require editing lines.
  - Inconsistent with the [expression expansion guidelines](#expansion-of-expressions), which disallows forms like `{ some`; `some` should start on a new line instead.
  - This does not work well with leading `@` bindings.
  - It's unclear whether comments belong to the next or the previous argument.
  - The leading comma style was a lesser-evil workaround for the lack of trailing commas in the Nix language. Now that the language has this feature, there is no reason to keep it that way anymore.

### Operators

From the [list of operators](https://nixos.org/manual/nix/stable/language/operators.html#operators), this section focuses on binary operators.
Function application and attribute selection are not treated as an "operator" in the sense of this section, see [function application](#function-application) instead.

#### Non-chainable operators

Operators with no associativity are non-chainable.
Each invokation will always have exactly one left-hand side and one right-hand side.

The right-hand side must always be attached to the operator on the same line.
The operator must either be attached to the left-hand side as well, or start on a new line.

```nix
shortVariable == 42

stringLength (drvName (toString oldDependency))
== stringLength (drvName (toString newDependency))

some complicated calculation {
  # arguments
} == other stuff {
  # which may be multiline
}

some complicated calculation {
  # arguments
}
== "some very long string"
```

#### Chainable operators

Chained binary associative [operators](https://nixos.org/manual/nix/stable/language/operators.html#operators) with the same or monotonically decreasing precedence must be treated together as a single operator chain.

If an operator chain does not fit onto one line, it must be expanded such that every operator starts a new line:
- If the operand can also fit on the same line as the operator, it must be put there
- Otherwise, the operand must either be absorbed or start a new line with indentation

Operator chains in bindings may be compacted as long as all lines between the first and last one are indented.

**Examples**

```nix
# These chained associative operators have increasing precedence, so they're _not_ treated the same
foo
-> # <- The operator starts on a new line, but right operand is all of the below lines, they don't fit here, so indent
  bar
  ||
    baz
    && qux # <- The operand fits on this line

# These chained associative operators have decreasing precedence, so they're treated the same
foo
&& bar # <- All of these operands are just identifiers, they fit on the same line
|| baz # <- We shouldn't indent these lines, because it misleads into thinking that || binds stronger than &&
-> qux

[
  some
  flags
]
++ ( # <- Parenthesized expressions get absorbed
  foo
)
++ optionals condition [ # <- As are some multiline function applications
  more
  items
]
++
  runCommand name # <- Function application which cannot be absorbed start on a new line with indentation
    ''
      echo hi
    ''
    test

# In bindings we can use a more compact form as long as all in-between lines are indented.
{
  foo = bar // {
    x = 10;
    y = 20;
  } // baz;
}

# Bad, we can't use the more compact form because an intermediate line is not indented.
{
  foo = {
    x = 10;
    y = 20;
  } // bar // {
    z = 30;
    w = 40;
  };
}

# Good, this is the non-compact operator form
{
  foo =
    {
      x = 10;
      y = 20;
    }
    // bar
    // {
      z = 30;
      w = 40;
    };
}
```

### if-then-else

- `if` and `else` keywords must always start on a new line.
- The `if` and `else` bodies must always be indented.
- If the condition does not fit onto one line, then it will start on the next line with indentation, and `then` will be on the start of the line following the condition.
- `else if` chains are treated as one long sequence, with no indentation creep on each step.
- `else if` chains must not be on a single line.

**Examples**

```nix
# Condition fits on one line
if builtins.length matches != 0 then
  { inherit path matches; }
else if path == /. then
  [
    1
    2
  ]
else
  go (dirOf path);

# Condition doesn't fit onto one line
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

**Alternatives**

- The bodies could be absorbed in some cases, saving an indentation level:
  ```nix  
  #1a
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
  #1b
  if builtins.length matches != 0
    then { inherit path matches; }
  else if path == /.
    then [
      1
      2
    ]
  else go (dirOf path);

  #1c
  if builtins.length matches != 0
  then { inherit path matches; }
  else if path == /.
  then [
    1
    2
  ]
  else go (dirOf path);
  ```

### assert

- `assert`s must always start on their own line and the body also starts on its own line without any additional indentation.

```nix
# Good
assert foo;
[
  bar
  baz
]

# Bad
assert foo; [
  bar
  baz
]

# Good
{
  vendor ?
    assert false;
    null,
    
  vendor ? null,
}:
null

let
  # Good
  x =
    assert foo;
    bar;
   
  # Bad
  y = assert foo;
    bar;
in
x
```

**Alternatives**
- Treat it the [same as `with`](#with). The reasons not to do that:
  - `assert`'s stand on their own and could be removed without breaking anything. Comparatively, `with`'s can't be removed without breaking the code
  - `assert`'s are a bit like `if-then-else` statements, which are also spread out over multiple lines

### with

- In any situation where a term would get absorbed, the term with a `with` prepended to it may get absorbed as well.
- Otherwise, the body of `with attrs;` must start on a new line without any additional indentation.

**Examples**

```nix
{
  # Good
  foo = with bar; [
    # multiline
    baz
  ];
  
  # Good
  foo =
    with foo;
    with bar;
    [
      # multiline
      baz
    ];
  
  # Good
  foo =
    with bar;
    baz foo {
      # multiline
      qux = 10;
    };

  # Good
  foo =
    with bar;
    if cond then
      foo
    else
      bar;
  
  # Bad
  foo = assert qux; with bar; [
    # multiline
    baz
  ];
  
  # Bad
  foo = with bar;
    [
      # multiline
      baz
    ];

  # Bad
  foo =
    with bar; [
      # multiline
      baz
    ];
    
  # Good
  [
    qux
    quux
  ]
  ++ (with pkgs; [
    baz
    blorp
  ]);
}
```

### let-in

Let bindings must always have this form:
```
let
  <name1> = <value1>;
  <name2> = <value2>;
  ...
in
<body>
```

- Let bindings are *always* multiline.
- Each binding is indented and starts on its own line.
  For more details, see the [bindings section](#bindings).
- The `<body>` always starts on a new line and is not indented.

**Examples**

```nix
let
  foo = "bar";
in
func foo;

let
  foo = "bar";
in
{
  inherit foo;
  baz = "smth";
}

let
  foo = "bar";
in
if foo == "bar" then
  "hello"
else
  "world"
```

**Alternatives**

- To allow having the `<body>` be absorbed after the `in`:
  ```
  let
    <name1> = <value1>;
    <name2> = <value2>;
    ...
  in <body>
  ```

  In particular when `<body>` is an identifier, list, attribute set and/or others.

  Problems with this alternative:
  - It leads to larger diffs when inserting something after the `in`
  - The formatting can change when `<body>` is updated
  - It's less consistent, since the formatting depends on the `<body>`

- The body could be indented by a level
  ```
  let
    <name1> = <value1>;
    <name2> = <value2>;
    ...
  in
    <body>
  ```
  
  Problems with this alternative:
  - Leads to indentation creeps
  - Inconsistent with other expressions that have a `<body>` that is "returned"
  - Favors a style where the body starts on the same line as the in for some values (e.g. attribute sets) to reduce an indentation level, see above.

### Attribute sets and lists

- Brackets and braces must always have a space (or line break) on the inside, like `[ `, ` ]`, `{ ` and ` }`.
  - Empty lists and attribute sets are written as `[ ]` and `{ }`, respectively.
- Lists and attribute sets with multiple items should be liberally expanded.
  - They can only be on a single line if they fit on the line and contain few enough elements.
  - As described under [bindings](#bindings) below, nested attribute sets are always expanded.

**Examples**

```nix
[
  { }
  { foo = "bar"; }
  {
    foo = {
      bar = "baz";
    };
  }
  { foo.bar = "baz"; }
]

[
  [ 1 ]
  [
    2
    3
  ]
]

[
  [
    1
    2
    3
  ]
]

[
  {
    mySingletons = [
      [
        ({
          # stuff in there
        })
      ]
    ];
  
    mySingletons' = [
      [
        (function call)
      ]
    ];
  }
]
```

**Drawbacks**

- Singleton lists may use a lot of indentation

**Alternatives**

- Have a special compact form for singleton lists, to reduce the indentation level and remove two additional lines
  ```nix
  foo = [ {
    # content
  } ];
  ```

### Bindings

Let bindings, attribute sets and default function arguments share the same syntax for their items, which is discussed here together.

Within bindings, if the first and last line are not indented, the absorbed style is used, otherwise newline and indent

Bindings have the most special cases to accommodate for many common Nixpkgs idioms.
Generally, the following styles exist, which are used depending on the kind and size of the value:

```nix
#1 The entire binding fits onto a single line
foo = "bar";

#2 The body fits onto a single line, but the binding is too long
length limit
very.long.foo =
  function arg1 arg2 arg3;

#3 Where possible, the body should be absorbed
foo = function {
  # args
};
add = x: y: {
  result = x + y;
};

#4 If neither single-line nor absorbable, start on a new line with indentation
foo =
  function
    arg1
    arg2
    arg3;

```

Notable special cases are:

- Single line values that would not benefit from style #2 keep using #1, even if this makes it go above the line limit. This mostly applies to simple strings and paths.
- Attribute set values must always be expanded. This has the consequence of always forcing nested attribute sets to be multiline (even if they would be single line otherwise because they only contain a single item), which usually is desired.
  ```nix
  {
    foo.bar.baz = "qux";
    foo' = {
      bar.baz = "qux";
    };
  }
  ```
- As described in the [`with` section](#with), `with` expressions of absorbable terms should be treated the same way as absorbable terms.
  - This means that the attribute set force-expansion also applies to them here.
  - This also means that (multi-line) `with` expressions will use style #3 or #4, depending on their body.
  ```nix
  # Force-expand short attrset
  meta = with lib; {
    maintainers = [];
  };
  # Don't absorb since the body of `with pkgs;` is `with pyPkgs; ...`, which is not absorbable.
  buildInputs =
    with pkgs;
    with pyPkgs;
    [
      some
      dependencies
    ];
  ```

**Alternatives**

Function calls could always be absorbed. This would reduce indentation of their arguments in some cases. However, this may look really weird in other cases, especially when the binding is very long:

```nix
some.very.long.attr = callFunction
  arg1
  arg2
  arg3;
```

Consistent with this would be to also absorb `let` bindings and other expressions, however this might result in double indentation.

```nix
suff = let
   foo = "bar"; # <-- double-indentation
  in
  foo;
```

#### Bindings semicolon placement

The semicolon in bindings must always be placed on the same line as the expression it concludes.

**Examples**

```nix
{
  attr1 = bar;
  attr2 = function call {
    # stuff
  };
  attr3 =
    function call
      many
      arguments;
  attr4 =
    let
      foo = "bar";
    in
    some statement;
  attr5 =
    if foo then
      "bar"
    else
      "baz";
  attr6 =
    let
      foo = false;
    in
    if foo then "bar" else "baz";
  attr7 = function (
    if foo then
      "bar"
    else
      "baz"
  );
  attr8 =
    cond1
    || cond2
    ||
      some function call
      && cond3;
}
```

**Alternatives**


1. On a new line without indentation.
  - This clearly marks a separation between attributes, however it is wasteful of space.
  ```nix
  attr3 =
    function call
      many
      arguments
  ;
  attr3 =
    let
      foo = "bar";
    in
    some statements
  ;
  ```
2. On a new line with one indentation level.
  - Just as wasteful on space as (1), but a bit less clear about signaling the end of the binding.
  ```nix
  attr3 =
    function call
      many
      arguments
    ;
  ```
3. A mix of (1) and (2), where usually the semicolon is placed directly at the end of the binding.
   But with exceptions in which the semicolon is placed onto the following line instead in cases where the value is a multiline `if` expression or nested operator.
   These are the only syntax elements that may result in the semicolon being placed on a line with arbitrarily deep indentation.
   
   ```nix
   attr4 =
     if foo then
       "bar"
     else
       "baz"
   ;

   attr5 =
     let
       foo = false;
     in
     foo || bar;
       
   attr7 =
     cond1
     || cond2
     ||
       some function call
       && cond3
   ;
   ```

### inherit

The items must either be all on the same line, or all on a new line each (with indentation),
in which case the semicolon must be on its own line with indentation.

**Examples**

```nix
inherit foo bar baz;
inherit
  foo'
  bar'
  baz'
  ;
```

#### inherit from


For a fragment like this:
```
inherit (<source>) <attr1> ... <attrn>;
```

- If the entire fragment fits in the first line, it must be formatted as such.
- Otherwise if only `inherit (<source>)` fits into the first line, it must be formatted as such,
  with the same style as the normal `inherit` for the attributes.
- Otherwise the `(<source>)` must also be on its own line.

**Examples**

```nix
inherit (pkgs) ap1 ap2 ap3;
inherit (pkgs)
  app1
  app2
  # ...
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
