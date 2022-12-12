---
feature: issues-warnings
start-date: 2022-06-11
author: piegames
co-authors: —
shepherd-team: @lheckemann, @mweinelt, @fgaz
shepherd-leader: @mweinelt
related-issues: https://github.com/NixOS/nixpkgs/pull/177272
---

# RFC: Nixpkgs "problem" infrastructure

## Summary
[summary]: #summary

Inspired by the various derivation checks like for broken and insecure packages, a new system called "problems" is introduced. It is planned to eventually replace the previously mentioned systems where possible, as well as the current – undocumented – "warnings" (which currently only prints a trace message for unmaintained packages). A `config.problemHandler` option is added to the nixpkgs configuration, with centralized and granular control over how to handle problems that arise: "throw" (fail evaluation), "trace" (print a warning message) or "ignore" (do nothing).

Additionally, `meta.problems` is added to derivations, which can be used to manually declare that a package has a certain problem. This will then be used to inform users about packages that are in need of maintenance, for example security vulnerabilities or deprecated dependencies.

Using the newly introduced features, we may create a process for removing packages from nixpkgs that is easier to maintain and friendlier to users than just replacing packages with `throw`.

## Motivation
[motivation]: #motivation

Nixpkgs has the problem that it is often treated as "append-only", i.e. packages only get added but not removed. There are a lot of packages that are broken for a long time, have end-of-life dependencies with known security vulnerabilities or that are otherwise unmaintained.

Let's take the end of life of Python 2 as an example. (This applies to other ecosystems as well, and will come up again and again in the future.) It has sparked a few bulk package removal actions by dedicated persons, but those are pretty work intensive and prone to burn out maintainers. A goal of this RFC is to provide a way to notify all users of a package about the outstanding issues. This will hopefully draw more attention to abandoned packages, and spread the work load. It can also help soften the removal of packages by providing a period for users to migrate away at their own pace.

For some use cases, like for packages without maintainers, we do not want to break evaluation of a package and simply warn the user instead. We want the users to configure all these according to their needs and through a single standardized interface.

## Detailed design
[design]: #detailed-design

### Package problems

A new attribute is added to the `meta` section of a package: `problems`. If present, it is a list of attrsets which each have at least the following fields:

- `kind`: Required. If present, the resulting warning will be printed as `kind: message`.
- `message`: Required. A string message describing the issue with the package. The value should:
  - Start with the "This package", "The application" or equivalent, or simply with the package name.
  - Be capitalized (unless it starts with the package name).
  - Use a period at the end.
- `name`: Required if there are multiple values of the same `kind`. Give the issue a custom name for more easy filtering
- `date`: Required. An ISO 8601 `yyyy-mm-dd`-formatted date from when the issue was added.
- `urls`: Optional, list of strings. Can be used to link issues, pull requests and other related items.

Other attributes are allowed. Some message kinds may specify additional required attributes.

Example values:

```nix
meta.problems = [
  {
    name = "python2-eol";
    kind = "deprecated";
    message = "This package depends on Python 2, which has reached end of life.";
    date = "1970-01-01";
    urls = [ "https://github.com/NixOS/nixpkgs/issues/148779" ];
  }
  {
    kind = "removal";
    message = "The application has been abandoned upstream, use libfoo instead";
    date = "1970-01-01";
  }
];
```

### Problem kinds

At the moment, the following values for the `kind` field of a warning are known:

- `removal`: The package is scheduled for removal some time in the future.
- `deprecated`: The package has been abandoned upstream or has end of life dependencies.
- `maintainerless`: `meta.maintainers` is empty
- `insecure`: The package has some security vulnerabilities
- `broken`: The package is marked as broken
- `unsupported`: The package is not expected to build on this platform

Not all values make sense for declaration in `meta.problems`: Some may be automatically generated from other `meta` attributes (for example `maintainerless`). New kinds may be added in the future. Furthermore, some kinds are expected to be present only up to once per derivation: for example, we have no use for having multiple `maintainerless` problems, and therefore also no need to give them a name in order to distinguish them.

### Nixpkgs configuration

The following new config option is added to nixpkgs: `config.problemHandler`. The (currently undocumented) option `config.showDerivationWarnings` will be removed.

Handler values can be either `"throw"`, `"trace"` or `"ignore"`. Future values may be added in the future. The key is of the form `packageName.problemKind` or `packageName.problemName`, where `"*"` is allowed on either level as a wildcard.

```nix
problemHandler = {
  "*" = {
    "*" = "throw";
    alias = "trace";
    maintainerless = "ignore";
  };
  myPackage.foo = "ignore";
};
```

If multiple rules match a given problem of a package, the most specific handler will be called:

1. `pkgName.problemName`
2. `pkgName.problemKind`
3. `pkgName."*"`
4. `"*".problemName`
5. `"*".problemKind`
6. `"*"."*"`

So for example the value of `myPackage.*` would override the one in `*.maintainerless` if both matched, as it is more specific.

The default value in nixpkgs might be something like:

```nix
problemHandler."*" = {
  "*" = "trace";
  removal = "throw";
  deprecated = "throw";
  maintainerless = "ignore";
};
```

It may also be expanded by values from other configuration options as part of a migration scheme from the other mechanisms.

## Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

### Propagation across transitive dependencies

When a package has a problem that `throw`s, all packages that depend on it will fail to evaluate until that problem is ignored or resolved. Most of the time, this is sufficient.

When the problem requires actions on dependents however, it does not sufficiently inform about all packages that need action. Multiple packages may be annotated with the same problem, in that case it should be given a name and the name should be the same across all instances. Other values like the message or the URL list do not need to be the same and may be adapted sensibly.

For the example of Python 2 deprecation, all problems would have `name = "python2-eol"` and then a user may set `config."*".python2-eol = "ignore";` to ignore them.

### Backwards compatbility, Backporting and stable releases

New problems generally should not be added to stable branches if possible, and also not be backported to them, since it may break evaluation. The same rule applies to other changes to a pacakge's `meta` which may generate a problem and thus lead to evaluation failure too. Scenarios where evaluation failure is a desired goal, for example with unfixable security issues, are obviously exempt from this.

### Removal of packages

The plan is to eventually remove packages with long outstanding problems. The details will be part of future work, but at the very least a package must have a problem whose kind defaults to "throw" for at least one full release cycle (so that stable users have sufficient time to be warned and intervene).

If a package needs to be removed for some other reason, the problem kind `removal` should be used instead:

```nix
meta.problems = [{
  kind = "removal";
  message = "We don't want this in nixpkgs anymore";
  date = "1970-01-01";
}];
```

## Drawbacks
[drawbacks]: #drawbacks

- Too much warnigns may cause Alarm fatigue
  - One idea I had is to be more verbose on the unstable channels, and then tune down the noise after branch-off.
  - New lints to packages should be introduced gradually, by making them "silent" by default on start and only going to "warn" after most problems in nixpkgs itself are resolved.
- People have voiced strong negative opinions about the prospect of removing packages from nixpkgs at all, especially when they still *technically* work.
  - We do not want to encourage the use of unmaintained software likely to contain security vulnerabilities, and we do not have the bandwidth to maintain packages deprecated by upstream. Nothing is lost though, because we have complete binary cache coverage of old nixpkgs versions, providing a comparatively easy way to pin old very package versions.
  - This change is a general improvement in the ecosystem even if we do not end up using it to remove any packages.

## Alternatives
[alternatives]: #alternatives

This project has gone through multiple iterations, and grown quite in scope during that. Therefore this section doubles a chronology of previous attempts of implementing it.

Alternative to the current solution, we could just continue to add new systems to `check-meta.nix` when specific use cases arise. The downside is that they are mostly similar yet not 100% consistent, resulting in both code duplication and user confusion.

The original proposal only wanted to deal with eval-breaking problems, and grew in scope since. Removing warnings from the equation makes the implementation simpler, however we would then miss out on things like tracing aliases. Maybe we should have a distinct mechanism for evaluation warnings.

The following sections discuss alternative ways of implementing the current feature proposal.

### Naming

A lot of names have been considered so far for this feature, currently "problems" is the "least bad" proposal.

- Problem: Extremely generic "kind of fits all use cases but not that well" word
- Issue: Colliding with GitHub issues
- Warning: People might expect that it would never break evaluation
- Error: This is too harsh of a word for things that are minor issues, like unmaintained packages
- Advisory: Too focused on security issues

Consider that the name should work as well as possible for all of the following cases, even if there are no current plans to replace all of these with our new feature: "removal", "deprecated", "maintainerless", "insecure", "broken", "unsupported", "unfree".

### Problem declaration

*n.b.: the terminology of the feature has multiple times since the earlier proposals were made*

An alternative design would be to have issues as a separate list (not part of the package). ~~Instead of allowing individual packages, one could ignore individual warnings (they'd need an identifying number for that). The advantage of doing this is that one could have one issue and apply it for a lot of packages (e.g. "Python 2 is deprecated"). The main drawback there is that it is more complex.~~ The advantages of that approach have been integrated while keeping the downsides small: Warnings are ignored with a per-kind granularity, but one may give some of them a name to allow finer control where necessary.

A few other sketches about how the declaration syntax might look like in different scenarios:

```nix
{
  # As proposed in the RFC
  meta.issues = [{
    kind = "deprecated";
    name = "python2-eol";
    message = "deprecation: Python 2 is EOL. #12345";
    # (Other fields omitted for brevity)
  }];

  # Issues are defined elsewhere in some nixpkgs-global table, only get referenced in packages
  meta.issues = [ "1234-python-deprecation" ];

  # Attempt to unify both approaches to allow both ad-hoc and cross-package declaration
  meta.issues = {
    "1234-python-deprecation" = {
      message = "deprecation: Python 2 is deprecated #12345";
    };
  };

  # Proposal by @matthiasbeyer
  meta.issues = [
    { transitive = pkgs.python2.issues }
  ];
}
```

Some more design options that were considered:

```nix
meta.problems = {
  "deprecated/python2-eol" = {
    message = "This package depends on Python 2, which has reached end of life.";
    date = "1970-01-01";
    urls = [ "https://github.com/NixOS/nixpkgs/issues/148779" ];
  };
  removal = {
    message = "The application has been abandoned upstream, use libfoo instead";
    date = "1970-01-01";
  };
};

meta.problems = {
  "deprecated" = [{
    name = "python2-eol";
    message = "This package depends on Python 2, which has reached end of life.";
    date = "1970-01-01";
    urls = [ "https://github.com/NixOS/nixpkgs/issues/148779" ];
  }];
  removal = {
    message = "The application has been abandoned upstream, use libfoo instead";
    date = "1970-01-01";
  };
};
```

These have the advantage of enforcing the presence of a name if there are multiple problems of the same kind, at the cost of some additional nesting in those cases.

### Problem resolution

On the nixpkgs configuration side, the first iteration used a generic "predicate" system for ignoring packages, similar to `allowUnfreePredicate` and `allowInsecurePredicate`. This turned out to be both too flexible and not convenient enough to use, so this was complemented with a list of packages to ignore and "smart" default values generation.

A second approach used a list type: `list of ("packageName.warningKind" or "packageName.*" or "*.warningKind" or "*.*")`. This was a binary choice (compared to the ternary value today), with an additional boolean `traceIgnoredWarnings` option. One downside is that it does not allow granular control over warnings, only evaluation failures. A bigger issue is that due to how the merge rules on lists work, it would have been difficult to provide good default values for the nixpkgs confinguration while keeping backwards compatibility.

## Unresolved questions
[unresolved]: #unresolved-questions

- ~~From above: "Ignoring a package without issues (i.e. they have all been resolved) results in a warning at evaluation time". How could this be implemented, and efficiently?~~
  - ~~More generally, how do we tell users that their ignored warning can be removed, so that they won't accidentally miss future warnings?~~
  - ~~Issues have a `resolved` attribute that may be used for that purpose.~~
    - Properly implementing this turned out to be non-trivial, so this feature was cut for the sake of simplicity as it was not of high importance anyways.
  - The ignore mechanism has been refined so that there is less risk of missing future warnings.
- ~~Should issues be a list or an attrset?~~·
  - We are using a list ~~for now, there is always the possibility to also allow attrsets in the future.~~
- Currently, many of the relevant nixpkgs configuration options can also be set impurely via environment variables. The `config.problemHandler` option does however not easily map to some environment variable.
  - When merging existing features into the problems system, existing environment variable will keep working in the future.
  - Maybe using less environment variables is all for the better?
  - We may always add specific environment variables for specific use cases where needed without having to expose the full expression power of `config.problemHandler`.

## Future work
[future]: #future-work

- The actual process of removing packages is only sketched out here to show how the new infrastructure may improve the situation. It is intentionally left as vague as possible, and details should be figured out in a follow-up discussion.
- The problems system is designed in a way that it supersedes a lot of our "insecure"/"unfree"/"unsupported" packages infrastructure. There is a lot of code duplication between them. In theory, we could migrate some of these to make use of problems. At the very least, we hope that problems are general enough so that no new similar features will have to be added in the future anymore.
  - Migrating the existing systems may end up being tricky due to backwards compatibility issues.
- Inspired by the automation of aliases, we could build tooling for this as well. This is deemed out of scope of this RFC because only real world usage will tell which actions will be worthwhile automating, but it should definitely be considered in the future.
  - There will likely be need for tooling that lists problems on all nixpkgs packages, filtered by kind or sorted chronologically.
  - Automatically removing packages based on time will likely require providing more information whether it is safe to do so or not.
- > If the advisories were a list, and we also added them for modules, maybe we could auto-generate most release notes, and move release notes closer to the code they change. [[source]](https://discourse.nixos.org/t/pre-rfc-package-advisories/19509/4)
  - Issues can certainly be automatically integrated into the release notes somehow. However, this alone would not allow us to move most of our release notes into the packages, because for many release entries breaking eval would be overkill.
- There has been discussion about introducing "tracing aliases", aliases that don't `throw` by default. Such an implementation may make use of the problem infrastructure.
