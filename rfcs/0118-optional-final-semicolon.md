---
feature: optional-final-semicolon
start-date: 2021-12-03
author: Lucas Eduardo Wendt
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Make it acceptable a semicolon at the end of a Nix expression raising a warning instead of a syntax error.

# Motivation
[motivation]: #motivation

Faster iterations.

Some people use full keyboard editors and hack around with their configurations, sometimes you move code from the final
part to a let expression or the reverse to test something or debug some faulty part then forgot a semicolon on the 
final of the last line, the code fails with a syntax error then you reopen the editor just to remove the semicolon to
make the parser happy, then you forgot the semicolon when you put the thing back to a let expression. This should be
a recoverable syntax issue just raising a warning to remove that semicolon when all is over.

This would make iterations a little faster and bring a bit less friction, and give a better clue about what is going on in this case.

# Detailed design
[design]: #detailed-design

Allow an optional semicolon at the end of an expression raising a warning if it's provided.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

=> 2+2
4
=> 2+2;
warning: extra semicolon at the end of the expression
4

The second example raises a syntax error on, for example, Nix 2.4

```
nix-repl> 2+2
4

nix-repl> 2+2;
error: syntax error, unexpected ';', expecting end of file

       at «string»:1:4:

            1| 2+2;
             |    ^
            2|
```

# Drawbacks
[drawbacks]: #drawbacks

- Temporary unhandled edge case for secondary nix parsers like [rnix-parser](https://github.com/nix-community/rnix-parser) that by consequency affects [rnix-lsp](https://github.com/nix-community/rnix-lsp)

# Alternatives
[alternatives]: #alternatives

There are no alternatives so far.

The impact of not doing this is not critic.

# Unresolved questions
[unresolved]: #unresolved-questions

What parts of the design are still TBD or unknowns?

# Future work
[future]: #future-work

What future work, if any, would be implied or impacted by this feature
without being directly part of the work?
