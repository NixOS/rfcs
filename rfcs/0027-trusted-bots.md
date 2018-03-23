---
feature: trusted-bots
start-date: 2018-03-23
author: Matthew Bauer
co-authors:
related-issues: https://github.com/matthewbauer/rfcs/pull/27
---

# Summary
[summary]: #summary

Create a "trusted bot" process to manage GitHub bots. Bot maintainers can apply to make their bot "trusted", adding it to the bot team.

# Motivation
[motivation]: #motivation

Why do we need bots? Nix has never had the accessibility of a package manager like Homebrew or the massive user base of a distro like Debian. To compete with them, we need to make our developers more productive. Bots can be a massive help.

Currently running bots:

- @GrahamC's @GrahamCOfBorg
- @ryantm's [nix-update](https://github.com/ryantm/nix-update)
- Flying Circus's [Vulnix](https://github.com/flyingcircusio/vulnix)

Past bots:

- Travis CI bot
- [mention-bot](https://github.com/facebook/mention-bot)

Right now we have kind of a wild west of bots where anyone can create and manage their own bots. This is great for iterating on new ideas, but has certain dangers. The biggest danger is that these maintainers get hit by a bus and are unable to continue managing the bot. In the long-term, My goal is to have these bots managed by the NixOS organization. The trusted bots program is the first step in that direction

# Detailed design
[design]: #detailed-design

My solution is to create a process for creating new bots that touch the Nixpkgs repo. Actionable steps:

- [ ] Create a "bots" repo in the NixOS org to list trusted bots. The rules for new bots are listed here.
- [ ] Use bots repo in NixOS as issue tracker for issues on bots.
- [ ] New bots are created through new pull requests. Provide a template like with NixOS/rfcs.
- [ ] Create a "bots" team in the NixOS org.

## Requirements for trusted bots
  - A bot must run on a designated GitHub user. Name preferably ending in "OfBorg" (as in @GrahamCOfBorg) or just including "bot". Profile homepage should link to software repo. Once accepted, bots will be added to a "bots" team on GitHub (can be used to filter them out with "-team:NixOS/bots", see NixOS/nixpkgs#37181).
  - Maintainer should be designated who maintains and runs bot. Some sort of contact information or a designated mailing list would make sense to have.
  - Bot software should have its own public GitHub repo. If possible, software should be listed in Nixpkgs.
  - A reproducible service must be available as either a NixOS module or just a "configuration.nix" file in the repo. The bot can be run on any hardware but the eventual goal is to run this on NixOS foundation hardware or through Graham's OfBorg.

@GrahamCOfBorg can be grandfathered into this program as it is the first "trusted bot". The intention is to make this "opt-in" for now-no changes are immediately needed to anyone's workflow.

# Drawbacks
[drawbacks]: #drawbacks

This process could formalize things too much. We want to allow people to iterate quickly on their bots. Also it's unclear how many bots we will have in the future, but hopefully this RFC will encourage more development in this area.

# Alternatives
[alternatives]: #alternatives

- An alternative to this would be just handling bots in a case-by-case basis. Each bot is different and has different needs.
- Another, more radical, alternative would be requiring every bot to meet the above requirements. This would be required for all auto-generated content in the GitHub issue and pull request trackers. The downside is that we don't want to discourage experimentation.

# Unresolved questions
[unresolved]: #unresolved-questions

- What permissions to give bots?
- How to deal with inactive bot maintainers?
- How to handle bots that need to have "webhooks" to work correctly?

# Future work
[future]: #future-work

In the future, we want to move the bots onto the NixOS org on GitHub and through hardware. This will help decrease the "bus factor" of Nixpkgs.

Interested in co-authors and also any suggestions, comments or concerns.
