---
feature: sign-commits
start-date: 2021-08-14
author: Las Safin
co-authors:
shepherd-team:
shepherd-leader:
related-issues: https://github.com/NixOS/rfcs/pull/34
---

# Summary
[summary]: #summary

Recommend and eventually require that people who commit directly to
https://github.com/NixOS/nixpkgs and https://github.com/NixOS/nix,
so called authorized committers, sign their commits.

Commits inside merges do not have to be signed as long as the merge commit itself is signed,
such that only Committers have to sign their commits.

# Motivation
[motivation]: #motivation

Signing commits would allow cryptographically verifying that the source code
hasn't been tampered by an untrusted party.

This would ensure that when pulling from GitHub, or some other source,
you can check if the source code has been signed by a trusted person.

This is already done by Guix:
- https://guix.gnu.org/en/blog/2020/securing-updates/
- https://github.com/guix-mirror/guix/commits/master
- https://guix.gnu.org/manual/en/html_node/Commit-Access.html
- https://guix.gnu.org/manual/en/html_node/Channel-Authentication.html

It is also done by most conventional distros, however, they sign
the output from the compilation rather than the source code, since
they distribute the output from the compilation.

This change would also allow using 3rd-party mirrors of Nixpkgs,
since we can verify the source code independent of where it came from.

This RFC was motivated by work during Summer of Nix, specifically,
the Libre SoC maintainer requested that source integrity be
maintained.

# Detailed design
[design]: #detailed-design

## Signing the commits
[signing]: #signing-the-commits

The following will be required from 2022-03-01T00:00Z on,
but is strongly recommended from now on.

Currently merging is done through GitHub, which would not work in this case.
Merging would have to happen outside of GitHub, so that you can sign the commits,
since currently the API doesn't support signing commits with your own GPG
key: https://github.com/cli/cli/issues/1318.

The exact workflow for merging a PR with ID 123 would be something like this:
```bash
git switch master
git pull
gh pr checkout 123
git switch master
git merge -m "Merged #123" --no-ff --gpg-sign -
git push origin master
gh pr close 123
```
A merge commit must always be made so that there is something to sign.

A git hook like the one presented here is also recommended,
so that unsigned commits aren't pushed by accident.
This would be put in `/.git/hooks/pre-push` of the repository to
be committed to.
```bash
#!/bin/sh

# Inspiration taken from https://github.com/guix-mirror/guix/blob/master/etc/git/pre-push.
# Put this in .git/hooks/pre-push.
set -xe

# This is the "empty hash" used by Git when pushing a branch deletion.
z40=0000000000000000000000000000000000000000

while read local_ref local_hash remote_ref remote_hash
do
  # Branch deletion; no signature to verify.
  if [ "$local_hash" != $z40 ]
  then
    # Check repositories under github.com/NixOS.
    case "$2" in
        *github.com*NixOS/*)
      # TODO: More thorough check.
      git verify-commit HEAD
      ;;
    esac
  fi
done
```

The digest algorithm for GPG must be set to something that isn't SHA-1,
as [it isn't secure anymore](https://eprint.iacr.org/2020/014.pdf), for example by putting the following in
`$HOME/.gnupg/gpg.conf`:
```
digest-algo sha512
```

Committers will need to put their PGP keys in
https://github.com/NixOS/nixpkgs/blob/master/maintainers/maintainer-list.nix,
and add their keys to public key servers.

The following might not be implemented before 2022-03-01T00:00Z,
but the above will still regardless be required at that point in time.

## Verifying flake Git inputs

### Updating flake Git inputs
[updating]: #updating-flake-git-inputs

The design is inspired by what is described here: https://guix.gnu.org/en/blog/2020/securing-updates/.

When updating any existing flake input of type `git` from an old commit, Nix must verify that
the new commit is trusted.

The old commit is always trusted.

In the context of Git, a parent is a direct parent in the DAG of commits.

If a commit has a trusted parent, then the commit is trusted if
it doesn't have a trusted parent with `/.authorized-committers.nix`,

If a commit has a trusted parent,
and is signed by a committer listed in each of the trusted
parents' `/.authorized-committers.nix`, then the commit is trusted.

#### The format of `/.authorized-committers.nix`

An example: `/.authorized-committers.nix`:
```nix
{
  committers = {
    jacob = "XXXX XXXX XXXX XXXX XXXX  XXXX XXXX XXXX XXXX XXXX";
    jonathan = "YYYY YYYY YYYY YYYY YYYY  YYYY YYYY YYYY YYYY YYYY";
  };
}
```

Specifically, it will contain a Nix expression, that evaluates
to a set with a single attribute `committers`, which contains
another set where names are mapped to PGP fingerprints. This is a set
instead of a list to make it easy to get the fingerprint for a specific
person.

### New flake Git inputs

When a flake input is initialized, there is no good way to check who to trust
automatically, i.e. it is [Trust on First Use](https://en.wikipedia.org/wiki/Trust_on_first_use).

To secure initializations, new attributes are added to the `git` input type:
- `startsAt` (optional): This is the first commit to use, therefore verification
  starts from this commit on.
- `startsAtKey` (optional): This is the PGP fingerprint for the `startsAt` commit.
  This should not be required, but is necessary since SHA-1 is insecure.

The standard registry entries will have `startsAt` and `startsAtKey` attributes
added, to ensure that NixOS users fetch trusted source code.

### Other new input attributes

- `insecureUpdate` (optional): If set to true, then the flake will update without errors
  to untrusted commits, however it will still emit a warning.
- `alwaysTrust` (optional): Commits signed by these PGP fingerprints will always be trusted.

## Speeding up fetching Git

Cryptographically verifying Git commits is easy, but
Git is currently often not suitable for using as a flake input.
Nixpkgs is growing at an extreme rate, and with each
revision cloning it becomes slower.
For the author, a full clone from scratch takes over 4 minutes.

To avoid this problem with the Git protocol, Nix currently
supports the `github` type, which fetches archives from GitHub,
and updates the flake input using proprietary GitHub APIs.
This is GitHub specific, isn't usable on other platforms, and can
not take advantage of the above method for verifying source code
integrity.

We can however speed up fetching Git repositories heavily
by passing filters (see man page for `git-clone(1)` and `git-rev-list(1)`):
- `git clone git://github.com/NixOS/nixpkgs --single-branch --branch=21.05-beta` 4:17
- `git clone git://github.com/NixOS/nixpkgs --single-branch --branch=21.05-beta --filter=blob:none` 1:05
- `git clone git://github.com/NixOS/nixpkgs --single-branch --branch=21.05-beta --filter=tree:0` 0:22
- `git clone git://github.com/NixOS/nixpkgs --single-branch --branch=21.05-beta --depth 1` 0:08
  (Almost supported already, see https://github.com/NixOS/nix/issues/5119)
- `curl https://github.com/NixOS/nixpkgs/archive/21.05-beta.tar.gz -LO | tar -xf -`
  0:04 (roughly equivalent to `github:NixOS/nixpkgs?ref=21.05-beta`)

Then after doing `cd nixpkgs`, we try fetching `21.05-beta`, which is 659 commits more to
pull:
- `git pull --ff-only origin 21.05` 0:08
- `git pull --ff-only origin 21.05` 0:08 (after having fetched with `--filter=blob:none`)
- `git pull --ff-only origin 21.05` 0:07 (after having fetched with `--filter=tree:0`)
- `git clone git://github.com/NixOS/nixpkgs --single-branch --branch=21.05 --depth 1` 0:08 (pulling doesn't make sense)
  (Almost supported already, see https://github.com/NixOS/nix/issues/5119)
- `curl https://github.com/NixOS/nixpkgs/archive/21.05.tar.gz -LO | tar -xf -`
  0:04 (roughly equivalent to `github:NixOS/nixpkgs?ref=21.05`)

This is with an 850 EVO SSD, the average download speed from GitHub was around 11 MiB/s according to `git`.
Relevant documentation is:
- https://github.blog/2020-12-21-get-up-to-speed-with-partial-clone-and-shallow-clone/
- https://git-scm.com/docs/partial-clone
- https://git-scm.com/docs/shallow

We likely want to make Nix use `--filter=tree:0` by default when fetching repositories.
`--depth 1` is faster, but it doesn't preserve the commit history,
and it's not clear how it it interacts with GPG signing.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

Committers will need to adapt to the new workflow before March of 2022.
The command they will run is explained in [signing], but further
information about how to sign commits is out of scope for this RFC.

Relevant documentation for setting up GPG:
- https://guix.gnu.org/manual/en/html_node/Commit-Access.html
- https://www.kernel.org/doc/html/latest/process/maintainer-pgp-guide.html

Flake users will need to become aware of the basics of this system
when using forks of Nixpkgs, as updating such flake inputs
will be different from before.
In addition, flake users should also begin taking use of the features
introduced in this RFC, as they are usable and useful for all flakes.

## Example flake

```nix
# flake.nix
{
  inputs.someflake = {
    url = "https://github.com/some/flake.git";
    startsAt = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
    startsAtKey = "XXXX XXXX XXXX XXXX XXXX  XXXX XXXX XXXX XXXX XXXX";
    type = "git";
  };

  outputs = { someflake }: {};
}
```

```nix
# some/flake/authorized-committers.nix
{
  committers.some = "XXXX XXXX XXXX XXXX XXXX  XXXX XXXX XXXX XXXX XXXX";
}
```

Now if `https://github.com/some/flake.git` receives a new commit that can
*not* be trusted according to the algorithm specified in [updating],
we'd get an error like the following if we run `nix flake update`:
```
* **Failed trust verification!** 'someflake': 'git+https://github.com/some/flake.git?ref=master&rev=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' -!> 'git+https://github.com/some/flake.git?ref=master&rev=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb' (Not signed by a trusted party!)
```

Notably, there is nothing that tells the user how to bypass the check
using the `insecureUpdate` attribute,
since if there were, users might very often ignore the error even if valid.

# Drawbacks
[drawbacks]: #drawbacks

- Merging PRs can not be done through GitHub.
- Setting up GPG signatures will be a bit extra work for the committers.
- Committers will need to maintain the list of authorized committers.
- Fetching Nixpkgs with Nix will take around [4 times](#speeding-up-fetching-git) the time, depending on your hardware.
- Currently building a fork of Nixpkgs (for e.g. a PR) will still work fine, since
  the latest commit will be trusted when adding a new flake input, or referring
  to one from the commandline, but updating the flake input will fail
  since the commits are likely not signed by authorized committers.

# Alternatives
[alternatives]: #alternatives

- Mandating signing only tags is an alternative, though not very useful for most users.

# Unresolved questions
[unresolved]: #unresolved-questions

- Should `/.authorized-committers.nix` perhaps not support computation like `flake.nix`?
  If it supports computation, in Nixpkgs it can be derived from the maintainer list partially.
- Should we require that repositories that use this mechanism contain
  the public keys corresponding to the fingerprints to remove the need for key servers?

# Future work
[future]: #future-work

- Currently, Git still uses SHA-1, which means that verifying a commit's signature
  doesn't mean that the hash of that commit is trusted, since there could be
  multiple commits with the same hash. See [SHA-1 is a Shambles](https://eprint.iacr.org/2020/014.pdf).
  To avoid this, all Git repositories must eventually be transitioned to
  SHA-256 when Git support for SHA-256 is stabilized.
- The `github` flake input type could potentially be removed since it doesn't seem to be necessary anymore.
- Instead of an ad-hoc workflow for signing merges, functionality
  could be added to https://github.com/desktop/desktop and https://github.com/cli/cli
  to support signing merge commits. See https://github.com/cli/cli/issues/1318.
- To reduce the amount of time fetching Nixpkgs takes, redirection flakes could be introduced.
  A redirection flake must have no inputs and no outputs.
  It would have a single `redirection` attribute, with the same format as an input.
  For example:
  ```nix
  {
    redirection.url = "https://github.com/NixOS/nixpkgs/archive/e51edc1e641e4a9532566961c7336f4cdd4602a1.tar.gz";
  }
  ```
  Flakes that depend on this flake will instead depend on the target of the redirection.
  Redirection flakes would have lock files, `/.authorized-committers` as usual.
  This would be used to make a "lightweight" Nixpkgs repository that tracks
  the main repository, redirecting using the `tarball` input type.
  This repository would also be verified using the method described in [Updating flake Git inputs][updating].
  CI would be put in place to check that the tarballs' contents are the same
  as the corresponding commits.
- Verify the sources used in Nixpkgs to the extent possible. This would be done on a
  per-package basis since it depends on how upstream signs their source code (if at all).
