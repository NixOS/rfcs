---
feature: pipe-operator
start-date: 2023-05-23
author: @piegamesde
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Introduce a new "pipe" operator, `|>`, to the Nix language, defined as `f a` = `a |> f`.
Additionally, elevate `lib.pipe` to a built-in function.

As a reminder, `pipe a [ f g h ]` is defined as `h (g (f a))`.

# Motivation
[motivation]: #motivation

Creating advanced data processing like transforming a list is a thing commonly done in nixpkgs.
Yet the language has no support for function concatentation/composition,
which results in such constructs looking unwieldy and difficult to format well.
`lib.pipe` may be the most powerful library function with that regard,
but it is unknown and overlooked by many because it is not easily discoverable:
Despite its great usefulness, it is currently used in less than 30 files in Nixpkgs
(`rg '[\. ]pipe .* \['`).
Additionally, it is not accessible to Nix code outside of nixpkgs,
and due to Nix's lazy evaluation debugging type errors is really difficult.

Let's have a look at an arbitrarily chosen snippet of Nixpkgs code:

```nix
defaultPrefsFile = pkgs.writeText "nixos-default-prefs.js" (lib.concatStringsSep "\n" (lib.mapAttrsToList (key: value: ''
  // ${value.reason}
  pref("${key}", ${builtins.toJSON value.value});
'') defaultPrefs));
```

It is arguably pretty hard to read and reason about. Even when applying some more whitespace-generous formatting:

```nix
defaultPrefsFile = pkgs.writeText "nixos-default-prefs.js" (
  lib.concatStringsSep "\n" (
    lib.mapAttrsToList
    (
      key: value: ''
        // ${value.reason}
        pref("${key}", ${builtins.toJSON value.value});
      ''
    )
    defaultPrefs
  )
);
```

One can observe the following issues:

- If you want to follow the data flow, you must read it from bottom to top,
  from the inside to the outside (the input here is `defaultPrefs`).
- Adding a function call to the output would require wrapping the entire
  expression in parentheses and increasing its indentation.

Compare this to the equivalent call with `lib.pipe`:

```nix
defaultPrefsFile = pipe defaultPrefs [
  (lib.mapAttrsToList (
    key: value: ''
      // ${value.reason}
      pref("${key}", ${builtins.toJSON value.value});
    ''
  ))
  (lib.concatStringsSep "\n")
  (pkgs.writeText "nixos-default-prefs.js")
];
```

The code now clearly reads from top to bottom in the order the data is processed,
it is easy to add and remove processing steps at any point.

With a dedicated pipe operator, it would look like this:

```nix
defaultPrefsFile = defaultPrefs
  |> lib.mapAttrsToList (
    key: value: ''
      // ${value.reason}
      pref("${key}", ${builtins.toJSON value.value});
    ''
  )
  |> lib.concatStringsSep "\n"
  |> pkgs.writeText "nixos-default-prefs.js";
```

The artificial distinction between the first input and the functions via the list now is gone,
and so are the parentheses around the functions.
With the lower syntax overhead, using the operator becomes attractive in more situations,
whereas a `pipe` pays for its overhead only in more complex scenarios (usually three functions or more).
Having a dedicated operator also increases visibility and discoverability of the feature.

# Detailed design
[design]: #detailed-design

## `|>` operator

A new operator `|>` is introduced into the Nix language.
Semantically, it is defined as the reverse of function application: `f a` = `a |> f`.
It is left-associative and has a binding strength one weaker than function application:
`a |> f |> g b |> h` = `h ((g b) (f a))`.

## `builtins.pipe`

`lib.pipe`'s functionality is implemented as a built-in function.
The main motivation for this is that it allows to give better error messages
like line numbers when some part of the pipeline fails.
Additionally, it allows easy usage outside of Nixpkgs and increases discoverability.

While Nixpkgs is bounds to minimum Nix versions and thus `|>` won't be available until
several years after its initial implementation,
it can directly benefit from `builtins.pipe` and its better error diagnostic by overriding `lib.pipe`.
Elevating a Nixpkgs library function to a builtin has been done several times before,
for example `bitAnd`, `splitVersion` and `concatStringsSep`.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

## Tooling support

Like any language extension, this will require the available Nix tooling to be updated.
Updating parsers should be pretty easy, as the syntax changes to the language are fairly minimal.
Tooling that evaluates Nix code in some way or does static code analysis should be easy to support too,
since one may treat the operator as syntactic sugar for function application.
No fundamentally new semantics are introduced to the language.

# Prior art

Nickel has `|>` too, with the same name and semantics.

F# has `|>`, called "pipe-forward" operator, with the same semantics.
Additionally, it also has "pipe-backward" `<|` and `>>`/`<<` for forwards and backwards function composition.
`<|` is equivalent to function application, however its lower binding order allows removing parentheses:
`g (f a)` = `g <| f a`. All these operators have the same precedence and are left-associative.

Elm has the same operators as F#.

Haskell has the (backwards) function composition operator `.` in its prelude: `(g . f) a` = `g (f a)`.
It also has "reverse application" `&`, which is roughly equivalent to `|>`,
and `$`, which is function application again but right-associative and very weakly binding.
`.` binds stronger than both.

`|>` is definable as an infix function in several other programming languages,
and in even more languages as macro or higher-order function (including Nix, that's `lib.pipe`).

# Alternatives
[alternatives]: #alternatives

For each change this RFC proposes, there is always the trivial alternative of not doing it. See #drawbacks.

## More operators

We could use the occasion and introduce more operators like those mentioned above.

Function composition is mostly interesting for the so-called "point-free" programming style,
where partially applied compositions of functions are preferred over the introduction of lambda terms.
However, Nix is not well suited for that programming style for various reasons,
nor would that point-free style have nearly as many applications in real-world Nixpkgs code.

F#'s reverse-pipe operator has a lot less use due to its left-associativity,
but a right-associative version of it more similar to Haskell's `$` might be an alternative:

```nix
defaultPrefsFile = 
  pkgs.writeText "nixos-default-prefs.js" <|
  lib.concatStringsSep "\n" <|
  lib.mapAttrsToList (
    key: value: ''
      // ${value.reason}
      pref("${key}", ${builtins.toJSON value.value});
    ''
  )
  defaultPrefs
  ;
```

Adding both pipe directions raises questions about how these two interact when used together.
F# has the same binding strength for both, but this only works well because both are left-associative.
Haskell has `&` stronger than `$`, which is very sensible but unlikely to be intuitive to a new user.
Given that we want to call them `|>` and `<|` instead, then users might equally well to assume both have
equal strength.

Given these restrictions and the fact that situations where one needs both in Nix are expected to be fairly rare,
it is recommended to choose either one of `|>` and `<|`, but not have both in the language.

## Change the `pipe` function signature

There are many equivalent ways to declare this function, instead of just using the current design.
For example, one could flip its arguments to allow a partially-applied point-free style (see above).
One could also make this a single-argument function so that it only takes the list as argument.

# Drawbacks
[drawbacks]: #drawbacks

- Introducing `|>` has the drawback of adding complexity to the language, and it will break older tooling.
- The main purpose of `builtins.pipe` is as a stop-gap until Nixpkgs can use `|>`. After that, it will be mostly redundant.

# Unresolved questions
[unresolved]: #unresolved-questions

- Who is going to implement this in Nix?
- How difficult will the implementation be?
- Will this affect evaluation performance in some way?
  - There is reason to expect that replacing `lib.pipe` with a builtin will reduce its overhead,
    and that the builtin should have little to no overhead compared to regular function application.

# Future work
[future]: #future-work

Once introduced and usable in Nixpkgs, existing code may benefit from being migrated to using these features.
Automatically transforming nested function calls into pipelines is unlikely,
as doing so is not guaranteed to always be a subjective improvement to the code.
It might be possible to write a lint which detects opportunities for piping, for example in nixpkgs-hammering.
On the other hand, the migration from `pipe` to `|>` should be a straightforward transformation on the syntax tree.
