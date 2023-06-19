---
feature: issues-warnings
start-date: 2022-06-11
author: piegames
co-authors: —
shepherd-team: @RaitoBezarius, @mweinelt, @infinisil
shepherd-leader: @mweinelt
related-issues: https://github.com/NixOS/nixpkgs/pull/177272
---

# RFC: Nixpkgs "problem" infrastructure

## Summary
[summary]: #summary

Inspired by the various derivation checks like for broken and insecure packages, a new system called "problems" is introduced. It is planned to eventually replace the previously mentioned systems where possible, as well as the current – undocumented – "warnings" (which currently only prints a trace message for unmaintained packages). A `config.problems.handlers` and `config.problems.matchers` option is added to the nixpkgs configuration, with centralized and granular control over how to handle problems that arise: "error" (fail evaluation), "warn" (print a trace message) or "ignore" (do nothing).

Additionally, `meta.problems` is added to derivations, which can be used to manually declare that a package has a certain problem. This will then be used to inform users about packages that are in need of maintenance, for example security vulnerabilities or deprecated dependencies.

Using the newly introduced features, we may create a process for removing packages from nixpkgs that is easier to maintain and friendlier to users than just replacing packages with `throw` directly.

## Motivation
[motivation]: #motivation

Nixpkgs has the problem that it is often treated as "append-only", i.e. packages only get added but not removed. There are a lot of packages that are broken for a long time, have end-of-life dependencies with known security vulnerabilities or that are otherwise unmaintained.

Let's take the end of life of Python 2 as an example. (This applies to other ecosystems as well, and will come up again and again in the future.) It has sparked a few bulk package removal actions by dedicated persons, but those are pretty work intensive and prone to burn out maintainers. A goal of this RFC is to provide a way to notify all users of a package about the outstanding issues. This will hopefully draw more attention to abandoned packages, and spread the work load. It can also help soften the removal of packages by providing a period for users to migrate away at their own pace.

For some use cases, like for packages without maintainers, we do not want to break evaluation of a package and simply warn the user instead. We want the users to configure all these according to their needs and through a single standardized interface.

Nixpkgs already has a couple of mechanisms for doing these kind of things, among others for unfree, insecure or broken packages. However these have been added pretty much ad-hoc over time, and while being similar to each other also may have subtle differences. (For example some allow to provide a predicate for more granular control, others don't.) Usually, adding a new such mechanism (recently done with the source provenance in RFC 89) involves copying one of the existing ones and making adaptations. We need to generalize this concept in a way that is extensible towards new use cases, and to provide a more standardized API for configuration.

## Detailed design
[design]: #detailed-design

### Package problems

A new attribute is added to the `meta` section of a package: `problems`. If present, it is a an attribute set of attrsets where the keys are the problem names and the values have at least the following fields each:

- `kind`: The 'kind' of the problem, see [problem kinds](#problem-kinds) for allowed values. Defaults to the attribute set key.
- `message`: Required. A string message describing the issue with the package. The value should:
  - Start with the "This package", "The application" or equivalent, or simply with the package name.
  - Be capitalized (unless it starts with the package name).
  - Use a period at the end.
- `urls`: Optional, list of strings. Can be used to link issues, pull requests and other related items.

Problem kinds may specify additional attributes. Apart from that, other attributes are not allowed.

Example values:

```nix
meta.problems = {
  # This one will have the name "python2-eol"
  python2-eol = {
    kind = "deprecated";
    message = "This package depends on Python 2, which has reached end of life.";
    urls = [ "https://github.com/NixOS/nixpkgs/issues/148779" ];
  };
  # This one will have the name "removal"
  removal = {
    # kind = "removal"; # Inferred from attribute key
    message = "The application has been abandoned upstream, use libfoo instead.";
  };
};
```

### Problem kinds

At the moment, the following values for the `kind` field of a problem are known:

- `removal`: The package is scheduled for removal some time in the future. Only up to one instance per package.
  - Packages are already being removed for various reasons on a regular basis. Now we can properly warn users about this in advance.
- `deprecated`: The package has been abandoned upstream or has end of life dependencies.
  - Currently we do mass-pings for all maintainers of affected packages, although many packages are under-maintained. This allows to warn users who depend on that package as last resort stake holders.
- `maintainerless`: `meta.maintainers` is empty. Cannot be manually declared in `meta.problems`. Only up to one instance per package.
  - This is currently provided by `config.showDerivationWarnings`, which is only used by Hydra.
- `insecure`: (Reserved for future use.) The package has some security vulnerabilities.
  - This will hopefully replace the existing insecure warnings (`meta.knownVulnerabilities`, `config.permittedInsecurePackages`) in the future (see Future work).
- `broken`: (Reserved for future use.) The package is broken in some way.
  - This will hopefully replace or enhance `meta.broken` in the future (see Future work).
- `unsupported`: (Reserved for future use.) The package is not expected to build on this platform.
  - This will hopefully replace `meta.platforms` and `meta.badPlatforms` in the future (see Future work).

New kinds may be added in the future.

Not all values make sense for declaration in `meta.problems`: Some may be automatically generated from other `meta` attributes (for example `maintainerless`). Furthermore, some kinds are expected to be present only up to once per derivation: for example, we have no use for having multiple `maintainerless` problems. Restrictions like these may be implemented in the metadata check of packages.

### Nixpkgs configuration

The following new config options are added to nixpkgs: `config.problems.handlers` and `config.problems.matchers`. The (currently undocumented) option `config.showDerivationWarnings` will eventually be removed.

Handler values can be either `"error"`, `"warn"` or `"ignore"`. `"error"` maps to `throw`, `"warn"` maps to `trace`. Further values may be added in the future.

`config.problems.handlers` is the simple and most user-facing configuration value. It is a simple doubly-nested attribute set, of style `pkgName.problemName`. The package name is taken from `lib.getName`, which currently yields its `pname` attribute.

```nix
config.problems.handlers = {
  # If "myPackage" is used (evaluated) somewhere and has a problem named "maintainerless", print a warning
  myPackage.maintainerless = "warn";
  # This was added because "otherPackage" has a problem "CVE1234" which prevents evaluation, which needs to be ignored to use it nevertheless ("warn" would work too of course)
  otherPackage.CVE1234 = "ignore";
}
```

Some times, there is the need to set the handler for multiple problems on a package, or for one problem kind across all packages. For this,  `config.problems.matchers` exists. It is a list of matchers (currently package name, problem name or problem kind), with an associated handler. If multiple matchers match a single package, the one with the highest level (error > warn > ignore) will be used. Since the user configuration is merged with the default configuration, this means that one can not decrease the handler level below the default value. This is to protect users against accidentally disabling entire classes of notifications. Values from `config.problems.handlers` take precedence.

```nix
config.problems.matchers = [
  { # Wildcard matcher for everything
    handler = "warn";
  }
  { # Match all security warnings on "hello"
    package = "hello";
    kind = "insecure";
    handler = "error";
  }
  { # Match all packages affected by the python2 deprecation
    name = "python2-eol";
    handler = "error";
  }
  { # Has no effect: the default value is higher
    kind = "insecure";
    handler = "ignore";
  }
  { # Disallowed: Non-wildcards are better handled by using `problems.handlers` instead
    # The equivalent would be: `config.problem.handlers.hello.CVE1234 = "error";
    package = "hello";
    name = "CVE1234";
    handler = "error";
  }
]
```

To make it more explicit, a matcher is an attribute set which may contain the following fields:

- `package`: Match only problems of a specified package. (Using `lib.getName` for the name, same as in `config.problems.handlers`)
- `kind`: Match only problems of a specific kind.
- `name`: Match only problems with a specific name.
- `handler`: Required. Sets the level for packages that have been matched by this matcher.

## Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

### Propagation across transitive dependencies

When a package has a problem that `error`s, all packages that depend on it will fail to evaluate until that problem is ignored or resolved. Most of the time, this is sufficient.

When the problem requires actions on dependents however, it does not sufficiently inform about all packages that need action. Multiple packages may be annotated with the same problem, in that case it should be given a name and the name should be the same across all instances. Other values like the message or the URL list do not need to be the same and may be adapted sensibly.

### Backwards compatbility, Backporting and stable releases

New problems generally should not be added to stable branches if possible, and also not be backported to them, since it may break evaluation. The same rule applies to other changes to a package or its `meta` which may generate a problem and thus lead to evaluation failure too. Scenarios where evaluation failure is a desired goal, for example with unfixable security issues, are obviously exempt from this.

### Removal of packages

If a package needs to be removed for some reason (most likely due to outstanding unresolved problems), the problem kind `removal` should be added:

```nix
meta.problems = {
  removal = {
    message = "This package will be removed from Nixpkgs.";
  };
  # Probably some more problems here
};
```

The plan is to eventually remove packages with long outstanding problems of some kinds. The details will be part of future work, but users will be warned sufficiently in advance to give them the chance to intervene: Before removing a package, it should have a `removal` annotation for at least one full release cycle.

### Package declarations outside of Nixpkgs

Since package checks are done via "check-meta" called by `mkDerivation`, these problems can also be declared and checked in third-party packages outside of Nixpkgs.
This is not always desirable though, since third-party packages do not necessarily need to abide by the standards of Nixpkgs (e.g. having maintainer fields).
Because of this, the implementation needs to ensure no warnings or errors get generated without a `meta` declaration to keep the noise for third-party packages to a minimum. (The idea being that third-party packages commonly don't specify a `meta` attribute in the first place.)

## Drawbacks
[drawbacks]: #drawbacks

- Too much warnings may cause Alarm fatigue
  - One idea I had is to be more verbose on the unstable channels, and then tune down the noise after branch-off.
  - New lints to packages should be introduced gradually, by making them "silent" by default on start and only going to "warn" after most problems in nixpkgs itself are resolved.
- People have voiced strong negative opinions about the prospect of removing packages from nixpkgs at all, especially when they still *technically* work.
  - We already do remove packages on a regular basis, so now at least we can properly warn people about it in advance.
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
  # Using a list instead of attribute set. Slightly less complexity, but also slightly more verbose.
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
    urls = [ "https://github.com/NixOS/nixpkgs/issues/148779" ];
  };
  removal = {
    message = "The application has been abandoned upstream, use libfoo instead";
  };
};

meta.problems = {
  "deprecated" = [{
    name = "python2-eol";
    message = "This package depends on Python 2, which has reached end of life.";
    urls = [ "https://github.com/NixOS/nixpkgs/issues/148779" ];
  }];
  removal = {
    message = "The application has been abandoned upstream, use libfoo instead";
  };
};
```

These have the advantage of enforcing the presence of a name if there are multiple problems of the same kind, at the cost of some additional nesting in those cases.

### Problem resolution

On the nixpkgs configuration side, the first iteration used a generic "predicate" system for ignoring packages, similar to `allowUnfreePredicate` and `allowInsecurePredicate`. This turned out to be both too flexible and not convenient enough to use, so this was complemented with a list of packages to ignore and "smart" default values generation.

A second approach used a list type: `list of ("packageName.warningKind" or "packageName.*" or "*.warningKind" or "*.*")`. This was a binary choice (compared to the ternary value today), with an additional boolean `traceIgnoredWarnings` option. One downside is that it does not allow granular control over warnings, only evaluation failures. A bigger issue is that due to how the merge rules on lists work, it would have been difficult to provide good default values for the nixpkgs confinguration while keeping backwards compatibility.

A third approach used a two-level attribute set, similarly to the list above, but with the value setting the handler instead of it being a binary choice. `"*"."*" = "error";`, `myPackage."*" = "ignore";`, `"*".maintainerless = "ignore";`, etc. This provides better merging behavior than a list, while also being more granular. However, people voiced concerns about people accidentally wildcard-ignoring everything. Also, it is ambiguous on matching problem name vs problem kind, which mostly works fine but might lead to weird things happening in the case where new kinds are introduced.

## Unresolved questions
[unresolved]: #unresolved-questions

- ~~From above: "Ignoring a package without issues (i.e. they have all been resolved) results in a warning at evaluation time". How could this be implemented, and efficiently?~~
  - ~~More generally, how do we tell users that their ignored warning can be removed, so that they won't accidentally miss future warnings?~~
  - ~~Issues have a `resolved` attribute that may be used for that purpose.~~
    - Properly implementing this turned out to be non-trivial, so this feature was cut for the sake of simplicity as it was not of high importance anyways.
  - The ignore mechanism has been refined so that there is less risk of missing future warnings.
- ~~Should issues be a list or an attrset?~~·
  - ~~We are using a list for now, there is always the possibility to also allow attrsets in the future.~~
  - Current design uses an attribute set
- Currently, many of the relevant nixpkgs configuration options can also be set impurely via environment variables. The `config.problems.handler` option does however not easily map to some environment variable.
  - When merging existing features into the problems system, existing environment variable will keep working in the future.
  - Maybe using less environment variables is all for the better?
  - We may always add specific environment variables for specific use cases where needed without having to expose the full expression power of the configuration options.

## Future work
[future]: #future-work

- The actual process of removing packages is only sketched out here to show how the new infrastructure may improve the situation. It is intentionally left as open as possible, and details should be figured out in a follow-up discussion.
- The problems system is designed in a way that it supersedes a lot of our "insecure"/"unfree"/"unsupported" packages infrastructure. There is a lot of code duplication between them. In theory, we could migrate some of these to make use of problems. At the very least, we hope that problems are general enough so that no new similar features will have to be added in the future anymore.
  - Migrating the existing systems may end up being tricky due to backwards compatibility issues.
- Inspired by the automation of aliases, we could build tooling for this as well. This is deemed out of scope of this RFC because only real world usage will tell which actions will be worthwhile automating, but it should definitely be considered in the future.
  - There will likely be need for tooling that lists problems on all nixpkgs packages, filtered by kind or sorted chronologically.
  - Automatically removing packages based on time will likely require providing more information whether it is safe to do so or not.
- > If the advisories were a list, and we also added them for modules, maybe we could auto-generate most release notes, and move release notes closer to the code they change. [[source]](https://discourse.nixos.org/t/pre-rfc-package-advisories/19509/4)
  - Issues can certainly be automatically integrated into the release notes somehow. However, this alone would not allow us to move most of our release notes into the packages, because for many release entries breaking eval would be overkill.
- There has been discussion about introducing "tracing aliases"; aliases that don't `throw` by default. Such an implementation may make use of the problem infrastructure.
