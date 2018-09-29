---
feature: expression-integrity
start-date: 2018-09-28
author: lrvick
co-authors:
related-issues:
    - https://github.com/NixOS/nix/issues/404
    - https://github.com/NixOS/nix/issues/613
    - https://github.com/NixOS/nix/issues/748
---

# Summary
[summary]: #summary

This RFC seeks to provide a strategy to allow NixOs to strongly attest who
authored a nix expression, who reviewed it, and that it has not been tampered
with outside the review flow.

# Motivation
[motivation]: #motivation

Due to the lack of VCS integrety on NixOS today a bad actor can gain remote
code execution on NixOS systems if any of the following are true:

  * A Github employee is coerced or malicious
  * The Github account credentials of any maintainer are compromised
  * A successful BGP attack on github.com or similar to create an MITM

Essentially NixOS has many single points of trust, and thus single points of
failure.

This is a serious design flaw and we can learn lessons from other package
management systems that have been burned by similarly poor package management
designs.

See examples of major security incidents in other package managers:

 * Gentoo: https://archives.gentoo.org/gentoo-announce/message/dc23d48d2258e1ed91599a8091167002
 * Debian: https://lists.debian.org/debian-devel-announce/2006/07/msg00003.html
 * NPM: https://eslint.org/blog/2018/07/postmortem-for-malicious-package-publishes
 * PyPi: https://www.reddit.com/r/Python/comments/8hvzja/backdoor_in_sshdecorator_package/
 * Ubuntu Snap: https://github.com/canonical-websites/snapcraft.io/issues/651
 * Arch Linux AUR: https://lists.archlinux.org/pipermail/aur-general/2018-July/034153.html

# Detailed design
[design]: #detailed-design

## Package Contributor

### Workflow

  1. Author and test a nixpkg
  2. PR a signed commit adding adding nixpkg to NixOS/nixpkgs repo

### Notes

  * Can be enforced by mandating all commits be signed in VCS settings
  * Contributors who choose not to sign will need someone else to PR for them

## Package Maintainer

### Workflow

  1. Verify signing key ID is listed in maintainers list
    * Add key ID to maintainers list if not already present
  2. Verify signature on PR matches public key id in contributors list
    * Add key ID to contributors list if not already present
  3. Review content of new PR for general best practices
  4. Ensure signatures/hashes verified for third party code referenced
  5. Make signed merge commit to master of NixOS/nixpkgs

### Notes

  * Maintainer signatures should be a hard requirement
  * Maintainer and Contributor should never be the same person.

## Nix Clients

### Workflow

  1. Pull latest nix expressions from VCS repo
  2. Verify author/reviewer commit signatures for all nix expressions
  3. Build/Install nix expression

### Notes

  * Local building is required for integrity as no trusted cache system exists

# Drawbacks
[drawbacks]: #drawbacks

Some contributors to NixOS may no longer contribute if doing so requires some
additional security work.

# Alternatives
[alternatives]: #alternatives

## Git Notes signing

Reviewer/maintainer signatures could be added to the Git Notes interface on
a given ref allowing m-of-n signing for security critical expressions.

This would additionally negate the need for merge commits and would allow
VCS automatic merging to be used if desired.

## Patch ID

One could chose to sign a Git "patch-id" instead of a given ref hash. This
would allow signatures to still be valid even if a git rebase was done that
didn't add any LOC changes to a given changeset. This could add flexibility
but will need more testing.

Example:

```
git diff-tree -p "someref"..HEAD | git patch-id --stable | gpg -as
```

## Detached signatures

We could avoid using VCS level signing at all and simply mandate maintainers
add their detached .nix.sig files to a PR before it merges.

# Unresolved questions
[unresolved]: #unresolved-questions

Currently this scheme does not attempt to solve how to tie trusted cached
binaries to their signed VCS commits. Until a solution for this is reached
users will have to build every expression locally which makes securely using
NixOS impractical on low-spec systems or users with limited time to wait on
compiles.

There are other proposals in progress to address this.

# Future work
[future]: #future-work

It may be desireable to continue to have an untrusted expression repo like the
one used today that users can install from by hand as they please.

This could be an analogue of the Arch Linux User Repository (AUR) vs the
trusted/signed official repos.
