---
feature: pure-object-prototypes
start-date: 2021-04-08
author: Francois-Rene Rideau (@fare)
co-authors:
shepherd-team:
shepherd-leader:
related-issues: [lib.experimental](https://github.com/NixOS/rfcs/pull/82)
---

# Summary
[summary]: #summary

We propose to add Pure Object Prototypes, or POP, an object system, to the nixpkgs library.
POP improves upon current Nix extension systems
by supporting multiple inheritance and default values.
These improvements solve modularity issues with existing extension systems.
We actually use POP in production in a fork of nixpkgs to support
local changes to some packages, by multiple people, with dependencies between changes.

POP can be also made to interoperate both ways with existing extension systems,
with simple adapters.


# Motivation
[motivation]: #motivation

## A maze of twisty little extension systems, all alike

Nixpkgs features too many mutually incompatible variants
of what is essentially the same extension system.
Just between `lib.fixedPoints` and `lib.customisation`, there are already
`fix'`, `makeExtensibleWithCustomName`, `makeExtensible`,
`makeOverridable`, `makeScope`, `makeScopeWithSplicing`,
plus add-ons like `overrideDerivation`.
Then, many languages and subsystems invent their own variant extension system.
And while I haven't looked at modules in details,
I'm told they also include a more elaborate variant in the same family.

This maze of mostly similar yet subtly different yet incompatible constructs
raises the barrier to entry to learning and using Nix.
Therefore, to end this anarchy... let's create another extension system!
But this time, to ensure that it's for good,
let's make it noticeably better than the previous ones.

## Extension systems are object systems

First, let's notice that these extension systems, that are equivalent to each other,
are also equivalent to Jsonnet's 2014 object system.
Jsonnet, itself a clean reformulation of the older internal Google Configuration Language (GCL),
can be viewed as a recent pure functional variant
in the long tradition of (heretofore stateful) “classless” or “prototype” object systems.
This tradition dates back to at least Yale T Scheme's 1981 object system,
with roots in knowledge or constraint representation systems of the 1970s;
it has many notable members such as SELF, CECIL, and, most famous of all, JavaScript.

This equivalence is not a mere curiosity:
by embracing the fact that Nix extension systems are object systems,
we can then improve upon the limitations of these extension systems, using proven solutions.
We have a large ready pool of Other People's Experience (OPE);
thus we don't need to rediscover problems and solutions the hard way,
and re-explore all the same dead-ends as our intellectual forefathers.
We can “just” adopt established designs and apply well-understood techniques
that have been discovered and refined over several decades
of academic research and industrial practice.

## Dependencies between extensions

One case in point is that Nix extension systems, like Jsonnet,
cannot express *dependencies* between extensions.

If extension `x` depends on extension `z`,
then the author of `x` might be tempted to not define `x`,
but instead define `zx = composeExtensions Z X`,
so his users (starting with himself) don't have to
manually do the composition every time they use `x`.
However, if, independently, the author of extension `y` also depends on `z`,
and also defines `zy = composeExtensions z y`,
and if some later poor user wants to use both `zx` and `zy`,
he can't use `composeExtensions zx zy`, because `z` is then applied twice,
which in general will redo some changes in `z` and/or undo some of the changes in `x`,
defeating the purpose.
The current "solution" is therefore that the author of `x` must expose `x` and not just `zx`,
and that the combining user must explicitly `composeManyExtensions [z x y]`.

But in practice, users may want to choose many optional extension in a large set,
each with its own list of direct dependencies, each of which may have more dependencies.
Then, it can become a great pain for the user to manually maintain
this *precedence list* of extensions, such that each is applied once and only once
in a topologically sorted dependency order.

For instance, if an extension `z` depends on *super* extensions `k3`, `k2`, `k1`
being present before it in the list of extensions to be composed in that order,
we'll say that `z` *inherits from* from these super extensions,
or that they are its direct super extensions.
But what if `k1`, `k2`, `k3` themselves inherit from super extensions `a`, `b`, `c`, `d`, `e`,
e.g. with `k1` inheriting from direct supers `c b a`,
`k2` inheriting from direct supers `e b d`, and
`k3` inheriting from direct supers `a d`, and what more
each of `a`, `b`, `c`, `d`, `e` inheriting from a base super object `o`?

With the basic extension systems offered by Nix, as in Jsonnet,
these dependencies couldn't be represented in the extensions themselves.
If you naively “always pre-mix” its dependencies into an extension,
then `a` would be a pre-mix `o a`, `b` would be `o b`... `e` would be `o e`,
`k1` would be `o c o b o a k1`,
`k2` would be `o e o b o d k2`,
`k3` would be `o a o d k3`,
`z` would be `o a o d k3 o e o b o d k2 o c o b o a k1 z`.
That's a lot of at-best needless and usually harmful repetitions
that the users would have to resolve by hand.
Instead the user would have to somehow remember and track those dependencies,
topologically sort them into a *precedence list* such as `o e c b a d k3 k2 k1 z`.

## A Modularity Nightmare

Requiring users to manually track dependencies then sort them
not only entails a lot of tedious and error-prone bookkeeping and sorting,
it is not *modular*.

If these various extensions are maintained by different people as part of separate libraries,
each extension's author must keep track not just of their direct dependencies,
but all their transitive indirect dependencies, with a proper ordering.
Moreover, any change they make, they must not only propagate to their own extensions,
but also to all extensions that depend on theirs;
they must thus somehow fix other people's code,
or notify the authors of these downstream extensions that depend on theirs,
and wait for these authors to propagate the change.

To get a change fully propagated might required hundreds of modifications
being sent and accepted by tens of different maintainers, some of whom might not be responsive.
Even when sets of dependencies are properly propagated, inconsistencies between
the orders chosen by different maintainers at different times may cause subtle miscalculations
that are hard to detect or debug.
In other words, while possible, manual maintenance of precedence lists is a modularity nightmare.

## Multiple inheritance to the rescue

The obvious solution to this nightmare is: to automate it away.
Happily, this automation is a well-known problem,
with a well-known solution in the context of object systems,
*multiple inheritance*.

With multiple inheritance, programmers only need declare the dependencies
between objects and their direct super objects:
the object system will automatically compute
a suitable precedence list in which order to compose the objects.
Thus, defining objects with dependencies becomes modular.

The algorithm that computes this precedence list is called a *linearization*:
It considers the dependencies as defining a directed acyclic graph (DAG),
or equivalently, a partial order, and
it completes this partial order into a total (or linear) order,
that is a superset of the ordering relations in the partial order.
The algorithm can also detect any ordering inconsistency or circular dependency
whereby the dependencies as declared fail to constitute a DAG;
in such a situation, no precedence list can satisfy all the ordering constraints,
and instead an error is raised, which can carry a helpful diagnostic message to help with debugging.
Recent modern object systems, including those of
Dylan, Python, Raku, Parrot, Solidity, and PGF/TikZ,
seem to have settled on the [C3 linearization algorithm](https://en.wikipedia.org/wiki/C3_linearization)
initially introduced [in Dylan](https://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.19.3910).

## A Real Use Case

Over the last year, I have been using Nix to build and deploy the language Glow,
itself written on top of Gerbil Scheme, that itself compiles to Gambit Scheme,
that itself compiles to C, itself compiled via GCC.
I have been maintaining Gerbil and Gambit in nixpkgs, and recently added Glow
to the many Gerbil libraries included in nixpkgs.

Gambit, Gerbil, and the many libraries it works with all change fast, with loose coupling:
some libraries work on the latest stable release, but
many depend on the latest (unstable) version of Gerbil and/or Gambit.
For instance, you could have the stable Gerbil on the unstable Gambit or vice versa,
but Glow requires the latest “unstable” Gambit and Gerbil;
and a development variant of Glow not yet in nixpkgs may or may not require
a version of gerbil-utils or gerbil-ethereum not yet in nixpkgs.
And so, when I build Glow, I want to be able to override any of the Gerbil libraries in Nixpkgs,
but only if needed, and then not with a wrong date in its name.
Moreover, Glow also depends on some Haskell libraries to interface with the Cardano ecosystem,
which also requires another independent set of customizations.

To manage these customizations, I created POP in December 2020
and have been using it since, so far with success.
See [PR #114449](https://github.com/NixOS/nixpkgs/pull/114449)
from which I extracted the POP library in [PR #116275](https://github.com/NixOS/nixpkgs/pull/116275).

As I admit that new features like POP should be added conservatively,
I also started the related [RFC 0082 lib.experimental](https://github.com/NixOS/rfcs/pull/82)
that aims at lowering the barrier to adding experimental code to the nixpkgs library
that any maintainer is capable of using in their own packages,
without lowering the barrier to adopting such code as part of the mainstream nixpkgs
that every maintainer is supposed to master.

# Detailed design
[design]: #detailed-design

## Design Summary

Just like the traditional Nix extension systems, POP manipulates "objects"
that can be seen in two ways: either (a) as regular attrsets mapping strings to values, or
(b) as composable "prototypes" each carrying partial information on how to compute an attrset.
However unlike the traditional Nix extension systems, the "prototype" contains more than
the usual `extension` function from self (a lazy reference to the final attrset)
and super (the attrset computation so far) to an extended attrset:
it also contains a list of direct `supers` to inherit from;
while we're at it, a list of default values to contribute to the base super value for the fixed-point;
and finally, a precomputed cache `precedenceList` for the precedence list.
All of these are stored as fields in the attrset stored in special field `__meta__`.

The primitive to create a POP object is the function `pop`, which takes as parameters an attrset
`{ supers?[], extension?identityExtension, defaults?{}, name?"pop", ...}`.
It precomputes the `precedenceList` from the transitive inheritance graph of `supers`,
using the `name` in case of error to report inheritance issues.
It then composes the `extension` for each of the objects in the `precedenceList`,
with the merge of the `defaults` for them as the base `super` object for the fixed-point.
Finally, it adds a suitable `__meta__` field to it that includes the parameters above
and the `precedenceList`, so you can keep composing the object with others.

When using an attrset without a `__meta__` field, it is assumed to be a like prototype that merges
a constant attrset (ifself) and empty supers and defaults, as per function `kPop`.

## Reference to Authoritative Details

The object system implementation itself,
[pop.nix](https://github.com/MuKnIO/nixpkgs/blob/devel/lib/pop.nix),
is heavily-commented 271-line file,
with 80 lines of actual code.
To make the specified behavior clearer,
those comments include putative types in a hypothetical dependent type system
capable of expressing subtyping and lists of objects in a list
with topologically sorted type constraints.

There is also a documentation file
[pop.md](https://github.com/MuKnIO/nixpkgs/blob/devel/lib/pop.md)
that discusses the background for the design of POP.

Finally, I have been writing an essay that I intend to submit to some
academic programming language conference, wherein
I reconstruct the principles of Object-Oriented Programming
based on my experience with POP and a similar library I wrote in Scheme:
[Pure Object-Orientation, Functionally](https://github.com/metareflection/poof).

## Notable though minor incompatibility

In the object tradition, most OO languages and literature list and compose classes or objects
with the self-most objects to the left, and the super-most objects to the right.
This is reverse order compared to what `composeExtensions` and `composeManyExtensions` do.
As POP embraces the OOP tradition, it also embraces this traditional order.
This is a minor breaking change to current Nix practice.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

Let's imagine support for writing applications in Common Lisp.
We'd define a POP with suitable defaults, say,
using sbcl as the implementation, a debug level of 2,
and no extra systems to load into the application.
In practice, there would be many other fields, but let's omit them for now.
The base object for CL applications would be:
```
clApplication = pop {
  defaults = {
    implementation = pkgs.sbcl;
    debugLevel = 2;
    extraSystems = [];
  };
};
```

Then, let's suppose you want to define an extension for Lisp debugging.
It would compile code with an increased debug level, and
load runtime support for the SLIME debugger into the image:
```
clDebugging = pop {
  extension = self: super: {
    debugLevel = 3;
    extraSystems = super.extraSystems ++ [ lispSystems.slime ];
  }
  supers = [ clApplication ];
};
```

Another extension might instead be about using the CCL implementation instead of SBCL,
which includes a different default debug level that is only valid if there are no overrides:
```
useCcl = {
  extension = self: super: {
    implementation = pkgs.ccl;
  };
  defaults = {
    debugLevel = 1;
  };
  supers = [ clApplication ];
};
```

Meanwhile, another extension might be about using a graphical debugging,
including a graphical inspector:
```
clGraphicalDebugging = {
  extension = self: super: {
    extraSystems = super.extraSystems ++ [ lispSystems.clouseau ];
  };
  supers = [ clDebugging ];
};
```

In the end you can define your application:
```
ernestine = pop {
  extension = self: super: {
    system = "ernestine-gui";
  };
  supers = [ clApplication ];
};
```

And you can define a debugging variant of your application:
```
ernestine = pop {
  supers = [ super.ernestine clGraphicalDebugging ];
}
```

The multiple-inheritance mechanism ensures that defaults override other defaults but not extensions;
it also ensures that extensions are evaluated once and only once, in dependency order,
so that if a dependency appears many times, if doesn't get to re-do its changes
and undo those of other dependencies.

Of course, there are library functions that simplify the cases where a POP
only has an `extension`, only has a `defaults`, or only has `supers`,
but we avoided using them for the sake of this example.

# Drawbacks
[drawbacks]: #drawbacks

- It's a change:
  every change is disruptive.
  If we want to embrace OOP, then the object system we adopt will become pervasive,
  and clash with the large body of existing code.
  Maybe then we should implement that autodetection magic so that POP can
  seamlessly interoperate with previous extension systems
  in an incremental embrace-and-extend replacement.

- Experimental:
  It's working well for me, but so far, I'm the only user.
  Quite possibly, the UI (name and signature of toplevel functions)
  might be adjusted based on feedback by other users.
  Also, if people actively embrace OOP, they may want to add more features to POP
  (multi-methods, method combinations, meta-object protocol, etc.),
  at which point the design may have to evolve.
  The library could be put in a staging area until it's considered stable.
  See [RFC 0082 lib.experimental](https://github.com/NixOS/rfcs/pull/82).

- Performance:
  Computing the `precedenceList` for an object in general is
  linear in the size of the inheritance graph (nodes plus arcs),
  i.e. the number of transitive `supers` entries.
  In the worst case, that's up to quadratic for each new object,
  which is cubic in the total number of objects.
  That can be slow.
  That said, the same "computation" would have to be done by hand
  by users who would want to achieve the same effect without automation,
  so it's not really a drawback *given the desired effect*.

- Missing features? Previous extension systems may have important features
  that I have neglected so far, and that would need to be implemented
  before we have "the" satisfactory object system for Nix.
  For instance, magic argument processing from pkgs or some other scope;
  and whatever feature modules need.
  That would be one more reason to put the object in experimental until stable.
  But the current state of POP as well as other copies with more features in progress
  could all be in experimental until the ultimate object system wins.

# Alternatives
[alternatives]: #alternatives

## Embrace non-modularity

Keep the existing menagerie of extension systems, embrace the non-modularity of it.

## Invent an even better object system

We can invent an even better object system and still include this one in nixpkgs in the meantime.

## Implement objects at a deeper level

We can make objects part of the language at a deeper level, as in Jsonnet,
for better performance and/or better error messages.
But if we can afford a user-level implementation, that is more flexible, and
we don't deep magic to fix or extend the object system.

# Unresolved questions
[unresolved]: #unresolved-questions

If we could agree on what "the" default prototype representation were for Nix,
or autodetect which it is, we could likewise automatically wrap a traditional extension into a POP.
Actually, we could probably autodetect whether an attrset has some `__unfix__`, `extend`
or some such field. When passed an extension function, we could pass it the `self` argument,
if it returns an attrset make that the attrset-to-merge, and if it returns another function,
pass it the super and use the result as the attrset-to-merge.
I'm not sure if backward-compatibility automagic is an asset or a liability,
so I left it out for now. But if at some point the goal is to replace the existing zoo
with a single improved solution, then we will want explicit conversion,
if not implicit conversion.

# Future work
[future]: #future-work

- Use and enjoy POP in more subsystems of nixpkgs than Gerbil.
- See how POP, with or without further improvements,
  can or cannot fully replace other Nix extension systems.
- In particular, see how POP, with or without further improvements,
  may improve the situation for modules.
- Update [release wiki to reflect changes](https://github.com/NixOS/release-wiki)
- Inform community about changes (Discourse).
