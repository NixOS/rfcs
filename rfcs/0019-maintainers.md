---
feature: maintainers-file
start-date: 2017-10-28
author: Maarten Hoogendoorn (@moretea)
co-authors: @zimbatm
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Currently, nixpkgs does not have explicit maintainers for anything besides
the packages themselves. Introducing a maintainers file enables us to mark
maintainers for the remaining parts.

# Motivation
[motivation]: #motivation

<!--  Why are we doing this? -->
There is no explicit (machine-readable) description of who maintains what.

Currently, a bot is used to ping people based on the heuristic of who authored
a git commit that that have touched a file at least once.  
This does not accurately track the current maintainers.
For example, if someone took over maintenance of the NixOS module system, nbp 
will still get pinged all the time, because he has created most of the files
in there.

Furthermore, there is only the rather black-and-white distinction between
people who have commit access, and those that do not. A maintainers file
might open further automation to delegate merge access.

<!-- What use cases does it support? -->
With a maintainers file, we can ping the correct maintainer(s) on a PR.
By having this file, we can also enable delegation of maintenance of sub-parts
of the code tree without giving full commit access.

<!-- What is the expected outcome? -->
The output of this RFC is:
- An agreed format for the maintainer file format.
- A simple tool (with machine parseable output) to answer who is the maintainer
  of a file or git diff.

# Detailed design
[design]: #detailed-design

<!-- This is the bulk of the RFC. Explain the design in enough detail for somebody
familiar with the ecosystem to understand, and implement.  This should get
into specifics and corner-cases, and include examples of how the feature is
used. -->

There are two high level options to take:
- Data format, such as toml, yaml, or the 
  [Linux kernel's maintainer file](https://github.com/torvalds/linux/blob/master/MAINTAINERS)
- Use Nix file + script to invoke this.

The maintainers file will be a Nix script, which will enable implementing some
more complex logic, and use the maintainers declared in 
`pkg.$name.metadata.maintainers`


# Drawbacks
[drawbacks]: #drawbacks

<!-- Why should we *not* do this? -->

Potential drawbacks include that this will introduce more formal maintainers.

# Alternatives
[alternatives]: #alternatives

<!-- What other designs have been considered? What is the impact of not doing this?
-->

The alternative is to keep the status quo (to not have explicit maintainers).

# Unresolved questions
[unresolved]: #unresolved-questions

<!-- What parts of the design are still TBD or unknowns? -->

-

# Future work
[future]: #future-work
<!-- What future work, if any, would be implied or impacted by this feature
without being directly part of the work? -->
Once a maintainers file is in place, it could be used by a GitHub bot to
enable more granular permissions than getting full commit access.

Furthermore, we could automate getting a quorum / minimal number of reviews
for complex or critical sub systems, such as the stdenv.



