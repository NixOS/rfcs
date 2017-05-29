---
feature: import-from-derivation
start-date: 2017-05-19
author: John Ericson (@Ericson2314)
co-authors: Joe Hermaszewski (@expipiplus1)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Fix some issues with importing from derivations so it is nicer to use both manually and with CI.
Once this RFC is implemented, hydra.nixos.org should allow importing from derivations.

# Motivation
[motivation]: #motivation

Sometimes the entire dependent graph cannot be known statically (before any building).
Examples of this would be a package with its own nix-based build system—the dependency must be downloaded first,
or leveraging a language specific build tool (Cabal, Cargo, etc) to generate a build plan.

Import-from-derivation and recursive Nix are two ways to achieve this dynamism—the interleaving of planning the graph and building it.
Implementation-wise, however, they are completely orthogonal so there's no reason not work on both.

Currently there are some issues with import-from-derivation, however. Per @shlevy's read-only recursive nix RFC:

- *Import-from-derivation breaks dry-run evaluation and separation of evaluation-time from build-time.*

  This is solved by simply making dry-run not build imported derivations.
  Those imports instead become stuck terms, and the derivations blocking them are enqueued.
  Moreover, the conceptual layering of the nix language and the derivation builder is preserved:
  While yes, in non-dry-run mode the evaluator will still need to invoke the builder, the builder need not know anything about evaluation.

- *Import-from-derivation won't work if your expression-producing build needs to run on a different machine than your evaluating machine, unless you have distributed builds set up at evaluation time*

  By not building during evaluation, we can use remote build machines just as usual.

This RFC details the fixes to those problems.

# Detailed design
[design]: #detailed-design

The fundamental change is rather than evaluation unconditionally triggering execution, evaluation will suspend yielding the execution needed to be done so it can make further progress on resumption.
This is probably easier to explain in terms of the implementation steps needed.

## Black-hole unwinding

There's currently a bug with nix-repl where if computation is interrupted (say with `SIGINT`), and the same computation is begun again, one will get an infinite recursion error despite there being no infinite recursion.
This is because the thunks stay black-holed—the indication that they are currently evaluated—despite the computation being aborted.
To fix this, we want aborted computations to instead unwind their stack, un-black-holing any thunks back the way they were before.
Mathematically, black-hole unwinding ensures that evaluation is idempotent.

## Partial evaluation

The next step is to extend the nix evaluator to support partial evaluation—i.e. evaluation in the presence of *stuck terms* which cannot be normalized.
The partial evaluator, on encountering a stuck term, will unwind (while unblack-holing thunks) until it finds another thunk to force—forcing binary primops for example force both subterms.
Eventually nothing is left to evaluate, and the evaluator returns.
[This is all completely standard for partial evaluation.]

## Import-from-derivation as stuck terms.

To leverage our partial evaluator, we deem imports of derivations as stuck terms.
We unconditionally evaluate the argument to `import`, but `import <unbuilt-store-path>` is stuck.
The partial evaluator, on encountering stuck terms, will log the unbuilt derivations, and return the set of all encountered ones (in the case that evaluation is not total).

## CLI

This is taken from issue XXX.
`nix-build --dry-run` will do a single round of partial evaluation, and print out the set of unbuilt imported derivations just as it would the build plan in the case that evaluation doesn't complete.
`nix-build --dry-run=n` will perform `n` rounds of evaluation, and then building unbuilt derivations, and then print the build plan or unbuilt imported derivations.
`nix-build --dry-run` is thus a synonym of `nix-build --dry-run=0`.
`nix-build --dry-run=infinity` is the semantics of `--dry-run` today—perform as many rounds as needed to get the final static build plan.

Because we pause evaluation each round, we can build the imported derivations "normally".
That includes taking advantage of build remotes, which avoids the problem of import from derivation DOSing the hydra evaluator and or imported derivations requiring a different platform than the evaluation machine.

# Drawbacks
[drawbacks]: #drawbacks

Overlap with recursive nix.

# Alternatives
[alternatives]: #alternatives

Recursive nix alone. @shelvy raised some other downsides of import-from-derivation, not solved by this RFC, which I'll address below:

- *Import-from-derivation doesn't keep a connection between the build rule and its dependencies: the expressions imported-from-derivation are not discoverable from the final drv.*

  There is nothing stopping us from logging this as extra metadata, but I'm not sure how this information is useful.

- *Import-from-derivation requires you to know up front all of the possible branches that involve recursive evaluation, whereas recursive nix can branch based on information derived during the build itself.*

  This is fair. There's a CPS-like encoding where one always imports a derivation, but it's something one would want to write.
  But, more importantly, we do not need to choose between improved import-from-derivation and recursive nix.

- *Certain far-future goals, such as a gcc frontend that does all compilations as nested derivations to get free distcc and ccache, would be very impractical to shoehorn into an import-from-derivation regime.*

  We can do both.


# Unresolved questions
[unresolved]: #unresolved-questions

None.

# Future work
[future]: #future-work

This unlocks lots of future work in Nixpkgs:

 - Leveraging language-specific tools to generate plans nix builds, rather than reimplementing much of those tools.

 - Simply fetching and importing packages which use Nix for their build system, like Nix itself and hydra, rather than vendoring that build system in.

Another future project would be some speculative strictness to allow one round of evaluation to return *both* a partial build plan and stuck imported derivations.
Currently the plan must still be evaluated entirely before any building of "actually needed" derivations, i.e. those which *aren't* imported, begins.
