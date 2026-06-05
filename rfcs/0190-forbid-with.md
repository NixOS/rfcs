---
feature: ban-with-expressions
start-date: 2025-10-07
author: 6543
co-authors:
shepherd-team:
shepherd-leader:
related-issues:
  - https://github.com/NixOS/rfcs/pull/120
  - https://github.com/NixOS/nixpkgs/pull/413393
---

# Summary
[summary]: #summary

Completely prohibit the usage of `with` expressions in nixpkgs to improve code clarity, maintainability, and enable better static analysis. Instead using explicit `inherit` statements should be used if bringing attributes into scope is desired.

# Motivation
[motivation]: #motivation

The `with` expression in Nix creates several problems that impact code quality and tooling:

- **Unclear variable origins**: When reading code with `with`, it's unclear where variables come from without evaluating the expression
- **Difficult static analysis**: Tools cannot determine variables without running full nix evaluation
- **Debugging difficulties**: Error messages become less helpful when variable sources are ambiguous
- **Code review challenges**: Reviewers can not simply relay on a diff view and must read the full code and not miss any scope

The `inherit` statement provides a better alternative that is:

- **Explicit**: Clearly shows which attributes are being brought into scope
- **Traceable**: Easy to see where each variable comes from
- **Analyzable**: Static analysis tools can easily understand the code structure
- **Debuggable**: Error messages can point to specific inherit statements

# Detailed design
[design]: #detailed-design

1. **Immediate prohibition**: New code in Nixpkgs must not use `with` expressions
2. **Gradual migration**: Existing `with` expressions should be migrated to `inherit` over time
3. **CI enforcement**: Add automated checks to prevent new `with` expressions from being merged
4. **Documentation updates**: Update Nixpkgs contributor guidelines to reflect this policy

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

## Simple attribute access

```nix
# Before
with pkgs; [
 git
 vim
 curl
]

# After  
let
  inherit (pkgs) git vim curl;
in [
 git
 vim 
 curl
]
```

## Function arguments

```nix
# Before
{ pkgs, ... }:
with pkgs; {
  buildInputs = [ git vim ];
}

# After
{ pkgs, ... }:
let
  inherit (pkgs) git vim;
in {
  buildInputs = [ git vim ];
}
```

## Nested scopes

```nix
# Before
with pkgs; {
  meta = with lib; {
    license = with licenses; [ mit ];
  };
}

# After
let
  inherit (pkgs.lib.licenses) mit;
in {
  meta = {
    license = [ mit ];
  };
}
```

# Drawbacks
[drawbacks]: #drawbacks

- **Increased verbosity**: Code may become slightly longer due to explicit prefixes or inherit statements
- **Migration effort**: Existing codebase requires changes
- **Learning curve**: Contributors familiar with `with` need to adapt to new patterns
- **Backward incompatible**: requires changing Nix code used "in the wild"

However, these drawbacks are outweighed by the benefits of clearer, more maintainable code.

# Alternatives
[alternatives]: #alternatives

Just discourage usage of `with`, but in this case most things still can not be statically checked.

# Unresolved questions
[unresolved]: #unresolved-questions

# Future work
[future]: #future-work
