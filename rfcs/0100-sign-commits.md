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

This RFC consists of several somewhat interdependent parts:
- [Add support in Nix for verifying trust when fetching Git repositories.](#verifying-trust)
- Speed up fetching Git repositories with Nix so that we don't have to
  rely on unverifiable tarballs as much.
- Make use of the above functionality in Nixpkgs, allowing users to
  make sure the version of Nixpkgs they are using is trusted.

# Motivation
[motivation]: #motivation

There is already much literature on why you should
sign your commits, but to quickly reiterate,
it provides assurance that you can trust a commit,
and thus makes it harder to inject malicious code
during an update, i.e. moving from an old commit
to a new commit.

However, even if you sign your commits, Nix currently
provides no way of automatically verifying said
commits for trust.

[Guix](https://guix.gnu.org/), a competitor to Nix, already
support verifying commits through their own system, described
in the following links:
- **https://guix.gnu.org/en/blog/2020/securing-updates/**
- https://github.com/guix-mirror/guix/commits/master
- https://guix.gnu.org/manual/en/html_node/Commit-Access.html
- https://guix.gnu.org/manual/en/html_node/Channel-Authentication.html

In addition, most conventional Linux distributions already sign their
binary packages. By adding this functionality to Nix, end-users of Nixpkgs
and other Nix repositories can be sure that they're getting the correct
source code, **regardless** of the channel through they received
it.

This RFC was motivated by work during Summer of Nix, specifically,
the Libre SoC maintainer requested that source integrity be
maintained.

# Detailed design
[design]: #detailed-design

## Verifying trust
[verifying trust]: #verifying-trust

### The algorithm

The design is inspired by what is described here: https://guix.gnu.org/en/blog/2020/securing-updates/.

We have two inputs to consider, an old trusted commit,
and a new potentially untrusted commit.

In the context of Git, a parent is a direct parent in the DAG of commits.

The old commit is always trusted.

If a commit has a trusted parent, then the commit is trusted if
it doesn't have a trusted parent with `/.well-known/authorized-committers.nix`,

If a commit has a trusted parent,
and is signed by a key listed in each of the trusted
parents' `/.well-known/authorized-committers.nix`,
and the key hasn't expired or been revoked, regardless
of when the commit has made, then the commit is trusted.

The reason the timestamp of the commit doesn't matter,
is that it's not secure and can be forged.

The reason that a commit only needs one trusted parent,
instead of all parents being trusted like Guix, is that
this allows merging non-trusted commits, while the merge
commit itself would be trusted.

### The format of `/.well-known/authorized-committers.nix`

An example: `/.well-known/authorized-committers.nix`:
```nix
{
  committers = {
    jacob = "XXXX XXXX XXXX XXXX XXXX  XXXX XXXX XXXX XXXX XXXX";
    jonathan = "YYYY YYYY YYYY YYYY YYYY  YYYY YYYY YYYY YYYY YYYY";
  };
}
```

Specifically, it will contain a Nix a set with a single attribute `committers`, which contains
another set where names are mapped to PGP fingerprints. This is a set
instead of a list to make it easy to get the fingerprint for a specific
person.
The fingerprints listed should be registered on at least https://keys.openpgp.org/.

The file must contain no thunks, and will be a restricted subset of Nix,
like the top-level of `flake.nix`.

### The Nix interface

A new command, `nix verify-git` will be added:
`nix verify-git <repo> <old> <new> [--always-trust <fingerprint>]`

The command will in addition accept all arguments that `builtins.fetchGit` supports,
except `rev`, `name`, and `submodules`.

When run, Nix will fetch the `new` commit, and check if it's
a descendant of `old`.
If not, the command will err.
If it is, then according to the algorithm described above, each
following commit until `new` will be verified for trust,
and the trusted commit that is closest to `new` will be output to stdout.

Users of the command can then check if the output matches `new`,
or use the newest trusted commit if they so wish.

The `--always-trust` argument allows bypassing the usual
algorithm, by always trusting commits signed by the specified
fingerprint.
You can specify this multiple times.

For example `niv` can then use this to verify that updates to
dependencies are in fact trusted.

### Flakes (experimental)

While flakes are experimental, they will also be affected by this change.
If flakes are not stabilized, then this section will be of no importance.

Flake Git inputs will support 3 new optional attributes:
- `verifyFrom`:
  The hash for the commit from which verification should start,
  if the input is not registered in the lock file.
  If not specified, then verification will start from the latest
  commit found, which will then be automatically trusted.
- `insecureNoVerify`: If set to `true`, then verification will not be done.
- `alwaysTrust`: A list of PGP fingerprints which should always be trusted,
  bypassing the usual verification measures.

When running `nix flake update` or similar, the Git inputs
would be verified and then set to the newest trusted commit.
In the case that there is a newer commit that isn't trusted,
the user will get a warning like the following:
```
* 'someinput': 'git+https://github.com/some/input.git?ref=master&rev=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' -> 'git+https://github.com/some/input.git?ref=master&rev=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb' (Untrusted newer commits are available)
```
In most cases the above situation is likely only temporary, and due to
the untrusted commits being ignored, if the situation is resolved upstream,
downstream users will have no problem and won't have to pay attention to it.

## Speeding up Git
[speeding up git](#speeding-up-git)

Taking the below benchmarks into account, we want to make Nix
by default fetch with `--filter=tree:0`.

### Rationale

Cryptographically verifying Git commits is easy, but
Git is currently often not suitable for fetching in Nix.
Nixpkgs is growing at an extreme rate, and with each
revision cloning it becomes slower.
For the author, a full clone from scratch takes over 4 minutes!

Because of this, fetching the tarball through GitHub's APIs
is preferred, as it is much faster (around 60 times for the author).

Since cryptographic verification of updates of repositories
through tarballs coming from GitHub is much harder,
we must fetch the Git commits instead so that we can verify them.
To speed up fetching Git commits, we can make use of relatively new Git features
to only download the parts we need:
- https://github.blog/2020-12-21-get-up-to-speed-with-partial-clone-and-shallow-clone/
- https://git-scm.com/docs/partial-clone
- https://git-scm.com/docs/shallow
- See man page for `git-clone(1)` and `git-rev-list(1)` and search for `--filter`

A benchmark from the author of this RFC:
- `git clone git://github.com/NixOS/nixpkgs --single-branch --branch=21.05-beta` 4:17
- `git clone git://github.com/NixOS/nixpkgs --single-branch --branch=21.05-beta --filter=blob:none` 1:05
- `git clone git://github.com/NixOS/nixpkgs --single-branch --branch=21.05-beta --filter=tree:0` 0:22
- `git clone git://github.com/NixOS/nixpkgs --single-branch --branch=21.05-beta --depth 1` 0:08
  (Almost supported already, see https://github.com/NixOS/nix/issues/5119)
- `curl https://github.com/NixOS/nixpkgs/archive/21.05-beta.tar.gz -LO | tar -xf -` 0:04

Then after doing `cd nixpkgs`, we try fetching `21.05-beta`, which is 659 commits more to
pull:
- `git pull --ff-only origin 21.05` 0:08
- `git pull --ff-only origin 21.05` 0:08 (after having fetched with `--filter=blob:none`)
- `git pull --ff-only origin 21.05` 0:07 (after having fetched with `--filter=tree:0`)
- `git clone git://github.com/NixOS/nixpkgs --single-branch --branch=21.05 --depth 1` 0:08 (pulling doesn't work)
- `curl https://github.com/NixOS/nixpkgs/archive/21.05.tar.gz -LO | tar -xf -` 0:04

This is with an 850 EVO SSD, the average download speed from GitHub was around 11 MiB/s according to `git`.

While `--depth 1` is faster, but due to its nature it's not clear how it interacts with PGP signing.

## Using this in Nixpkgs and related repositories

Nixpkgs is heavily dependent on the GitHub PR workflow. Because of this, we
heavily rely on trusting GitHub, and even signing only merge commits is not
easily possible, since the merge would have to be done outside of the traditional
GitHub workflow.

While we could require that people who commit directly to Nixpkgs sign
their commits, it would be a major change, and would require new tooling
to merge the pull requests.

This tooling is not yet ready, and because of that we can not yet
require that people sign their commits before pushing to Nixpkgs.

However, it is recommended that people attempt
to transition soon, with the [tooling available now](#current-solutions-for-signing-merges),
so that we can know how to improve the tooling,
and to ensure that we can enjoy a more trusted Nixpkgs sooner.

The required tooling is listed [below](#tooling-for-signing-merges).
When the tooling is somewhat complete, a new RFC to
discuss requiring signing will be made.

Specifically, for now for now, Nixpkgs will have a list of authorized
committers, `/.well-known/authorized-committers.nix`, as described
in [verifying trust], with all the authorized committers,
**in addition** to GitHub's public PGP key,
but only until the tooling is done.

This won't provide much extra security, since anybody
can sign anything with GitHub's key, but it will lay
the foundation for future improvements to security.

**Notably**, no part of the current workflow will change with this RFC.

### Tooling for signing merges

There are several tools that would make this much more ergonomic, for example:
- Support in GitHub's [CLI](https://github.com/cli/cli) for signing merges: https://github.com/cli/cli/issues/1318.
- Support in GitHub's [desktop GUI](https://github.com/desktop/desktop) for signing merges.
- Support in [Refined GitHub](https://github.com/sindresorhus/refined-github) for signing merges,
  perhaps by running Sequoia in WASM.
- Work on https://github.com/withoutboats/bpb/ or https://gitlab.com/wiktor/git-gpg-shim to avoid GPG.
- Solution for merging while on-the-go with your smartphone.
  + Browser extension for doing the merge like for Refined GitHub.
  + Custom app which you can share the link of a PR with to merge it.

When the tooling is in place, another RFC to untrust GitHub's key can be made.

### Current solutions for signing merges

We can make an ad-hoc script for merging and signing, using the GitHub CLI.
This script has been tested on https://github.com/L-as/test/,
and works for most common scenarios. The PR will be marked as
merged, and in the case that pushing fails due to upstream
having moved, it retries the merge. You need to specify the directory in which
the repository will be in, and it will destroy all
uncommitted changes, since it does a `git reset --hard`.
```bash
#!/bin/sh

set -xe

cd /my/nixpkgs/
git switch master
while true; do
  git fetch origin master
  git reset --hard origin/master
  gh pr checkout "$1"
  git switch master
  git merge -m "Merged #$1" --no-ff --gpg-sign -
  git push origin master && break || true
done
```

Another very useful tool is a pre-push hook to verify
that no untrusted commits are pushed. This depends on the
to-be-implemented `nix verify-git` functionality:
```bash
#!/bin/sh
# Put this in .git/hooks/pre-push.

set -xe

# This is the "empty hash" used by Git when pushing a branch deletion.
z40=0000000000000000000000000000000000000000

while read local_ref local_hash remote_ref remote_hash
do
  # Branch deletion; no signature to verify.
  if [ "$local_hash" != $z40 ]
  then
    test "x$(nix verify-git . "$remote_hash" "$local_hash" --ref "$local_ref")" = "$local_hash"
  fi
done
```

## SHA-1

Currently, [SHA-1 is a Shambles](https://eprint.iacr.org/2020/014.pdf), meaning that signatures for
commits hashed with SHA-1 can not be trusted fully.
A repository that wishes to improve its security should switch to SHA-256
(though experimental):
- https://git-scm.com/docs/hash-function-transition/
- [Git 2.29.0 release notes](https://github.com/git/git/blob/master/Documentation/RelNotes/2.29.0.txt)
- https://sha-mbles.github.io/ (Readable version of the paper)

In addition, GPG users ought to put the following in `$HOME/.gnupg/gpg.conf`:
```
digest-algo sha512
```

This way they can be sure that they do not use SHA-1 for digestion.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

Users who wish to allow others to check their repositories for
trust can choose to use GPG to sign their commits.
Relevant documentation for setting up GPG:
- https://guix.gnu.org/manual/en/html_node/Commit-Access.html
- https://www.kernel.org/doc/html/latest/process/maintainer-pgp-guide.html

They can also choose from some experimental alternatives:
- https://github.com/withoutboats/bpb/
- https://gitlab.com/wiktor/git-gpg-shim

The author of this RFC uses Sequoia for key management, but
GPG to sign their commits.

# Drawbacks
[drawbacks]: #drawbacks

- Fetching Nixpkgs with Nix will take around [5 times](#speeding-up-fetching-git) the time, depending on your hardware.
- Commits in PRs are not trustable relative to previous ones.

# Alternatives
[alternatives]: #alternatives

- Mandating signing only tags is an alternative, though not very useful for most users, since:
  1) Users of Nixpkgs rarely fix their used revision to a tag.
  2) Not signing every commit prevents you from using the algorithm described in [updating].
  Somewhat the same thing can be achieved by the "redirection flake" design described
  in [future], however.

Because of this, signing only tags does not make much sense for us.

# Future work
[future]: #future-work

- The `github` flake input type could fetch through Git, since the extra complexity
  of the dedicated code for fetching from GitHub doesn't give an extreme speed-up anymore.
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
  This repository would also be verified using the method described in [verifying trust].
  CI would be put in place to check that:
  1) the tarballs' contents are the same as the corresponding commits.
  2) the new commit is trusted using `nix verify-git`.
- Verify the sources used in Nixpkgs to the extent possible. This would be done on a
  per-package basis since it depends on how upstream signs their source code (if at all).
