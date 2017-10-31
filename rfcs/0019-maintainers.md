---
feature: maintainers-file
start-date: 2017-10-28
author: Maarten Hoogendoorn (@moretea)
co-authors: @zimbatm
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

In the long term we want to move to a more controlled way of can merge what, and have explicit
reviewers in place for all files.
This RFC is part of a larger body of work that is necessary to archieve this goal.
To enable this, we must be able to map all nixpkgs files to maintainers.


# Motivation
[motivation]: #motivation
<!--  Why are we doing this? -->
Currently we have two mechanism in place that explictly describes who the owner is.
It either is defined in the `metadata.maintainers` in a `stdenv.mkDerivation`, or when it matches a
pattern in `CODEOWNERS` file.

The metadata.maintainers only covers the packages, and does not used to determine reviewers
for packages on GitHub.

The [`CODEOWNERS`](https://help.github.com/articles/about-codeowners/)
is only used to help GitHub select a reviewer and is centrally managed in a single file.
One of the problems is that this loses the data locality, unlike the `.gitignore` files, on which
the format is heavily inspired.
This makes further delegation of maintainer responsibilities harder.

These two systems do not integrate together.
The meta data in` pokgs/*` is used by Hydra packages break, and the CODEOWNERS is only used by
GitHub for reviews.

The `CODEOWNERS` format is not extensible at all; there is no way to specify e.g. that some parts
require one positive review of the maintainers and others might require more than one.

Furthermore, GitHub is not suitable to handle the permission that the Nix community needs;
currently people either have full commit access, or none at all.

Therefore, we should implement a format and automation to handle both the data from the
`metadata.maintainers` and some maintainers file.

The output of this RFC is:
- An agreed format for the maintainer file format.
- A simple tool (with machine parseable output) to answer who is the maintainer
  of a file or git diff.
- Have a check to ensure that every file in nixpkgs has a maintainer.


# Detailed design
[design]: #detailed-design

<!-- This is the bulk of the RFC. Explain the design in enough detail for somebody
familiar with the ecosystem to understand, and implement.  This should get
into specifics and corner-cases, and include examples of how the feature is
used. -->

## Requirements
The input to the maintainers script is a list of files the output will be a machine readable list
of maintainers. It will support a `--why` option to print out which decisions points were
encountered, in order to debug why someone is a maintainer of a file.

This script will read in a MAINTAINERS files, with support for nested delegation like how the
`.gitignore` files work.

For files in `pkg/`, the script will try to use the metadata in the packages to find the maintainer.
If this information cannot be retrieved, it falls back to the rules in the MAINTAINERS file.


## Maintainers file format

TBD.

There are two high level options to take:
- Data format, such as toml, yaml, or the
  [Linux kernel's maintainer file format](https://github.com/torvalds/linux/blob/master/MAINTAINERS)
- Use Nix file + script to invoke this.

## Implementation
In order to facilitate integration in the GitHub PR + Hydra work by @globin and @gchristensen,
the implementation will consist of a python library and script.


# Drawbacks
[drawbacks]: #drawbacks

<!-- Why should we *not* do this? -->

A drawback is that this will introduce more formal maintainers and processes.


# Alternatives
[alternatives]: #alternatives

<!-- What other designs have been considered? What is the impact of not doing this?
-->

## Codeowners
Using the existing Codeowners file. This will not include the data from the metadata in packages.

## Mentionbot
Mentionbot is a heuristic to find ownership.
It does not work properly with accidental contributors, or when ownership has been tranferred to a new maintainer.


# Unresolved questions
[unresolved]: #unresolved-questions

<!-- What parts of the design are still TBD or unknowns? -->

- The exact file format


# Future work
[future]: #future-work
<!-- What future work, if any, would be implied or impacted by this feature
without being directly part of the work? -->
Once a maintainers file is in place, it could be used by a GitHub bot to
enable more granular permissions than getting full commit access.

Furthermore, we could automate getting a quorum / minimal number of reviews
for complex or critical sub systems, such as the stdenv.
