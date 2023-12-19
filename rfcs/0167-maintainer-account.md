---
feature: nixpkgs Maintainers Requirements and Expectations
start-date: 2023-12-19
author: Adam C. Stephens
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary

[summary]: #summary

Update the requirements and expectations for nixpkgs Maintainers, ensuring fairness and transparency.
As nixpkgs is a worldwide community, it is imperative that potential maintainers understand what is expected of them so that we can all collaborate effectively.

# Motivation

[motivation]: #motivation

Maintainers are encouraged to self select themselves for maintenance of packages and modules inside nixpkgs.
This provides flexibility for maintainers as they come and go, and lets them take responsibility for one or more areas in nixpkgs.
It is quite simple for users to add themselves to the [maintainer list](https://github.com/NixOS/nixpkgs/blob/master/maintainers/maintainer-list.nix), and they are expected to do so in a commit prior to adding themselves to a package or module.

The existing [maintainers/README.md](https://github.com/NixOS/nixpkgs/tree/master/maintainers/README.md) in nixpkgs, and the associated maintainer list, spell out a few expectations and requirements for maintainers.
The requirements in these documents may not be exhaustive and they currently allow for maintainers to opt out of one or more pieces of contact information.
For example, a maintainer may choose to not provide their user information for the primary nixpkgs hosting platform.
This opting out for one or more individuals can put extra maintenance overhead on the remaining maintainers; it fragments information which may be important for the overall community; and may even hide information from others working on nixpkgs.

# Detailed design

[design]: #detailed-design

At the time of this writing, the primary nixpkgs hosting platform is GitHub, but this RFC is meant to be platform agnostic.
If in the future nixpkgs moves to an alternative platform, these requirements and expectations should transfer to the new platform as well.

## Update maintainers/README

Update the section `How to lose maintainer status` in the [maintainers/README.md](https://github.com/NixOS/nixpkgs/tree/master/maintainers/README.md)` file:

```md
### How to become a maintainer

We encourage people who care about a package to assign themselves as a maintainer.
Commit access to the nixpkgs repository is not required to become a maintainer.

Maintainers are required to have an account on the nixpkgs hosting platform, which is currently GitHub.
You are expected to maintain an active account on the nixpkgs hosting platform, and are required to provide this information when adding yourself to `maintainer-list.nix`.

In order to do become a maintainer, add yourself to the [`maintainer-list.nix`](./maintainer-list.nix), and then to the desired package's `meta.maintainers` list, and send a PR with the changes.

### How to lose maintainer status

The following spells out reasons why a maintainer may lose this status. The maintainer is welcome to come back at any time once any issues have been resolved.

#### Inactivity

Maintainers who have become inactive on a given package can be removed.
This helps us keep an accurate view of the state of maintenance in nixpkgs.

The inactivity measure is currently not strictly enforced.
We would typically look at it if we notice that the author hasn't reacted to package-related notifications for more than 3 months.

Removing the maintainer happens by making a pull request on the package, adding that person as a reviewer, and then waiting one week for response or feedback.

#### Unreachable

Maintainers who do not have an active account on the nixpkgs hosting platform will be removed as maintainers.
An effort will be made to contact them through provided information prior to removal to provide a chance.
Individuals will receive a window of at least one week to respond to contact attempts.

Maintainers who have provided an email address as a point of contact, which when contacted are not available through this email address (e.g. emails bounce and fail to deliver), will have this email address removed. They must be added as a reviewer on the corresponding pull request and given one week for response or feedback prior to merging.

#### Violation of Code of Conduct

Maintainers are not immune to the [NixOS Code of Conduct](https://github.com/NixOS/.github/blob/master/CODE_OF_CONDUCT.md) and must be held to the same standard as non-maintainers.
Violations of the Code of Conduct severe enough to warrant enforcement should incur removal as maintainer as well.

### Removal as maintainer

The above section documents _why_ a maintainer may be removed.
All removals of a maintainer or a portion of their contact information will require at least a one week waiting period on the removal pull request.
All provided contact information from `maintainer-list.nix` will be used to attempt contact.
The initial contact attempts will be used as the starting point for this one week window.
```

## Update maintainers/maintainer-list.nix

Update the preamble in [maintainers/maintainer-list.nix](https://github.com/NixOS/nixpkgs/blob/master/maintainers/maintainer-list.nix)

````
/* List of NixOS maintainers.
    ```nix
    handle = {
      # Required
      name = "Your name";
      github = "GithubUsername";
      githubId = your-github-id;

      # At least one of email, matrix or discourse must be given in order to provide fallback communications
      email = "address@example.org";
      matrix = "@user:example.org";
      discourse = "DiscourseUsername";

      keys = [{
        fingerprint = "AAAA BBBB CCCC DDDD EEEE  FFFF 0000 1111 2222 3333";
      }];
    };
    ```

    where

    - `handle` is the handle you are going to use in nixpkgs expressions, strongly preferred to match `github`
    - `name` is a name that people would know and recognize you by,
    - `github` is your GitHub handle (as it appears in the URL of your profile page, `https://github.com/<userhandle>`),
    - `githubId` is your GitHub user ID, which can be found at `https://api.github.com/users/<userhandle>`,
    - `email` is your maintainer email address,
    - `matrix` is your Matrix user ID,
    - `discourse` is your `https://discourse.nixos.org` username,
    - `keys` is a list of your PGP/GPG key fingerprints.

    # Editing

    When editing this file:
     * keep the list alphabetically sorted, check with:
         nix-instantiate --eval maintainers/scripts/check-maintainers-sorted.nix
     * test the validity of the format with:
         nix-build lib/tests/maintainers.nix

    See `./scripts/check-maintainer-github-handles.sh` for an example on how to work with this data.

    # GitHub username

    Maintainers must have an active account on the primary nixpkgs hosting platform.
    GitHub is currently the primary nixpkgs hosting platform, so you are required to provide and keep active a GitHub account.

    This information ensures that you:
    - Can actively participate in Issues and Pull Requests
    - Get invited to the @NixOS/nixpkgs-maintainers team
    - Are reachable by mention on Issues and Pull Requests, either by a human or a robot.

    `handle == github` is **strongly preferred** whenever the username is an acceptable attribute name.

    If `github` begins with a numeral, `handle` should be prefixed with an underscore.
    ```nix
    _1example = {
      github = "1example";
    };
    ```

    # Alternative form of contact

    Maintainers must provide at least one of the alternative forms of contact. The simplest option would be to provide
    the same email address you use for git commits.

    # PGP/GPG keys

    Add PGP/GPG keys only if you actually use them to sign commits and/or mail.

    To get the required PGP/GPG values for a key run
    ```shell
    gpg --fingerprint <email> | head -n 2
    ```

    !!! Note that PGP/GPG values stored here are for informational purposes only, don't use this file as a source of truth.

    # Data usage

    By adding yourself to this maintainer-list file, you understand that the information you provided and your contributions are made public. While removal from the maintainer list is possible, in the interests of public good the history of nixpkgs will not be rewritten to remove you from it.

    Fields in this file may change in the future. In order to comply with GDPR this file should stay as minimal as possible.
*/
````

## Resolution of maintainers failing the criteria

There may be one or more maintainers who currently fail the criteria of an account on the nixpkgs hosting platform.
These maintainers will be contacted through their available information and give one month after initial contact to remedy the missing account information, and will be contacted at least three times during the month.
The maintainer should, themselves, create a Pull Request to provide the account information.
In case they decide they still would prefer not to provide nixpkgs hosting platform account information, they will be removed from `maintainers-list.nix`.
If a maintainer does not respond within the month window, they will be removed from `maintainers-list.nix`.

# Examples and Interactions

[examples-and-interactions]: #examples-and-interactions

This RFC intends to only apply to _maintainers_ and not general contributions from non-maintainers.
These two roles are distinguished by their expected responsibility.
While a contributor may use an alternative platform to submit a change, they are not considered a maintainer unless meeting the expectations laid out in this RFC and the resulting nixpkgs documentation.

# Drawbacks

[drawbacks]: #drawbacks

These changes grant the nixpkgs hosting platform control over who may or may not be a maintainer.

This may elevate the Code of Conduct, and the corresponding Moderation team, to a more prominent place than it currently is.

# Alternatives

[alternatives]: #alternatives

## Do nothing (status quo)

We have the alternative of doing nothing, and continuing to allow maintainers to opt out of having an account on the nixpkgs hosting platform.

### Upsides

- nixpkgs does not depend on GitHub's policies and practices to determine who is a maintainer. This could be mitigated by migrating away from GitHub, but until that happens this point remains.
- maintainers can remain more anonymous

### Downsides

- Maintainers without an account cannot be mentioned or referenced on the nixpkgs hosting platform
- Users and maintainers must leave the nixpkgs hosting platform in order to contact a maintainers, creating fractured communications
- Automation must account for users who do not have an account on the nixpkgs hosting platform
- Another maintainer/contributor/committer must execute all actions on behalf of a maintainer who does not have an account
- Automation may need to be written and maintained to accommodate contacting users without an account on the nixpkgs hosting platform

## Move to another platform that is hosted by the community

This is a non-trivial amount of effort and is out of the scope of this RFC.
While this could alleviate some issues, it would not change the existing policy which allows maintainers to opt out of having an account on the nixpkgs hosting platform.

# Prior art

[prior-art]: #prior-art

- [Linux Kernel Feature and driver maintainers](https://docs.kernel.org/maintainer/feature-and-driver-maintainers.html)
- [Debian Maintainer](https://wiki.debian.org/DebianMaintainer)
- [Kubernetes Community Membership](https://github.com/kubernetes/community/blob/master/community-membership.md)
- [Fedora Joining the Package Maintainers](https://docs.fedoraproject.org/en-US/package-maintainers/Joining_the_Package_Maintainers/)
- [openSUSE:How to contribute to Factory](https://en.opensuse.org/openSUSE:How_to_contribute_to_Factory)

All of the prior art communities have a requirement for joining or participating in the hosting platform of the project.
Some of these require an account for _all_ contributions, not just maintenance.

- Kernel: `Maintainers must be subscribed and follow the appropriate subsystem-wide mailing list`
- Debian: `register for a Salsa account if you do not have one`
- Kubernetes: Does not explicitly state a GitHub account is required, but by reading the requirements which mention GitHub 2FA it seems clear that it is
- Fedora: `Create a Bugzilla Account` and `Create a Fedora Account`
- OpenSUSE: `To begin to contribute to factory, you will need to make an account on openSUSE.`

# Unresolved questions

[unresolved]: #unresolved-questions

Is this touching on areas of law that justifies involving legal counsel?

Would implementing a Developer Certificate of Origin (DCO) as a contract or a more explicit grant of personal data provide better understanding for maintainers?
This could be added for signoff of modifications to `mainters-list.nix` only if it does provide the intendend behavior of granting nixpkgs permission to use data.

Do we need even more explicit contracts, similar to the [Debian declarations of intent](https://wiki.debian.org/DebianMaintainer#step_2_:_Declaration_of_intent)?

# Future work

[future]: #future-work

Any future moves of the nixpkgs hosting platform would necessitate users are active participants and have accounts on the destination system.
