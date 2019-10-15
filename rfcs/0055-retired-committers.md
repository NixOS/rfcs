---
feature: retired-committers
start-date: 2019-08-25
author: Till Höppner
co-authors: Graham Christensen
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Many people were given push access to the nixpkgs repository, which is kept even if
these committers become inactive. This RFC proposes moving these contributors to
a new team without push access.

# Motivation
[motivation]: #motivation

<!-- Why are we doing this? What use cases does it support? What is the expected
outcome? -->

Each committer represents secrets and access which need to be managed carefully.
These come in the form of passwords, SSH and GPG keys, and leaking them can put nixpkgs
at risk of of unauthorized modification.

Because every secret with push access can be leaked, we should keep their number as low as necessary,
here by deactivating the push access of inactive committers.
A special case of inactive committers are those who have lost access to their GitHub account entirely,
who would be unable to remove potentially leaked secrets from their account.

As of 2019-08-18, at least 2 committers have officially stepped down, and at least 1 committer has
not pushed to nixpkgs since 2014, but are still able to push directly to nixpkgs.

If implemented in this form, and assuming no further contributions, 7 contributors will be moved at the beginning of 2020.


# Detailed design
[design]: #detailed-design

<!-- This is the bulk of the RFC. Explain the design in enough detail for somebody
familiar with the ecosystem to understand, and implement.  This should get
into specifics and corner-cases, and include examples of how the feature is
used. -->

Inactive committers will have their push access disabled after not committing to nixpkgs for an entire year.

That year is measured from January 1 to December 31 instead of using a rolling window over the last 12 months,
to be more predictable for committers and reduce the evaluations from 12 times a year to just once a year.

For each committer from the [Nixpkgs Committers team](https://github.com/orgs/NixOS/teams/nixpkgs-committers), the number of commits
in that time range is checked, and the committer is considered inactive if there are none.

This process is repeated at the beginning of each new year.

Previous committers are moved to a new Nixpkgs Committers Emeritus team, to honor their past contributions.
Members of this team will remain in the GitHub organisation, and may regain push access at a later time.


# Drawbacks
[drawbacks]: #drawbacks

<!-- Why should we *not* do this? -->

- It might put pressure on people because they might lose their hard-earned permissions.
- Lower activity limits might encourage quota contributions of lower quality with the intention of not losing push access.

# Alternatives
[alternatives]: #alternatives

<!-- What other designs have been considered? What is the impact of not doing this? -->

- Committers could keep push access forever.
- We could be even stricter, at the risk of higher contributor churn and losing low-frequency direct contributions.

# Unresolved questions
[unresolved]: #unresolved-questions

<!-- What parts of the design are still TBD or unknowns? -->

- Is one year without commits a good activity threshold?
- How are committers informed about this change, or an impending revocation?

# Future work
[future]: #future-work

<!-- What future work, if any, would be implied or impacted by this feature
without being directly part of the work? -->

- The threshold may need adjustment in the future.

# Reference implementation

```py
#! /usr/bin/env nix-shell
#! nix-shell -I nixpkgs=https://github.com/nixos/nixpkgs-channels/archive/1412af4b2cfae71d447164097d960d426e9752c0.tar.gz -i python3 -p "python3.withPackages (p: [ p.PyGithub ])"

# nixpkgs-inactive-committers expects an API token passed in the environment as GITHUB_TOKEN
# Such a token can be created at https://github.com/settings/tokens
# Make sure to enable the read:org scope

from sys import stderr
from github import Github
from datetime import date, time, datetime
import os

year = date.today().year - 1
start_of_year = datetime.combine(date(year, 1, 1), time.min)

print(f'Reporting from {start_of_year}')

gh = Github(os.environ['GITHUB_TOKEN'],
        user_agent='nixpkgs-inactive-committers',
        per_page=100, timeout=90, retry=5)
print(gh.get_rate_limit(), file=stderr)

org = gh.get_organization('nixos')
nixpkgs = org.get_repo('nixpkgs')
committers = org.get_team_by_slug('nixpkgs-committers').get_members()
sorted_committers = sorted(list(committers), key=lambda c: c.login.lower())

def hasCommit(commits):
    # totalCount is borked, len(list(...)) eats too many API calls
    try:
        c = commits[0]
        return True
    except IndexError:
        return False

for member in sorted_committers:
    commits = nixpkgs.get_commits(author=member, since=start_of_year)

    if not hasCommit(commits):
        print(f'{member.login:<20} https://github.com/NixOS/nixpkgs/commits?author={member.login}')
```
