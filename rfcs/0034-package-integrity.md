---
feature: package-integrity
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
authored a package, who reviewed it, and that the package has not been tampered
with.

# Motivation
[motivation]: #motivation

Nix currently does not have any method to attest who authored a nixpkg, who
reviewed it, or that a given binary cached package was actually built from
a given .nix file in version control.

In practice this means that a bad actor can gain remote code execution on NixOS
systems if any of the following are true:

  * A Github employee is coerced or malicious
  * The Github account credentials of any maintainer are compromised
  * A successful BGP attack on github.com or similar to create an MITM
  * A cache server is compromised

Essentially NixOS has many single points of trust, and thus single, points of
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
  2. Builds a nixpkg and adds the hash of the binary to the nixpkg
  3. PR a signed commit adding adding nixpkg to NixOS/nixpkgs repo

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
  5. Build package and verify artifact hash matches hash contained in nixpkg
  6. Make signed merge commit to master of NixOS/nixpkgs

### Notes

  * Maintainer signatures should be a hard requirement
  * Maintainer and Contributor should never be the same person.
  * Some packages may not be reproducible and should get special flag set

## Cache maintainer

### Workflow

  1. Pull code from VCS repo
  2. Compile all new nixpkgs
  3. Publish artifacts

### Notes

  * signed nixpkgs now contain artifact hashes removing need for cache signing

## Nix Clients

### Workflow

  1. Pull latest nixpkgs VCS repo
  2. Verify author/reviewer commit signatures for all nixpkg.
  3. Attempt to fetch cached artifact during install
  4. Verify artifact hash against hash in given nixpkg during install

### Notes

  * Nix clients can opt to only trust reproducible builds with hashes.

# Drawbacks
[drawbacks]: #drawbacks

Some contributors to NixOS may no longer contribute if doing so requires some
additional security work.

# Alternatives
[alternatives]: #alternatives

## Git Notes signing

Reviewer/maintainer signatures could be added to the Git Notes interface on
a given ref allowing m-of-n signing for security critical packages.

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


# Future work
[future]: #future-work

It may be desireable to continue to have an untrusted package repo like the
one used today that users can install from by hand as they please.

This could be an analogue of the Arch Linux User Repository (AUR) vs the
trusted/signed official repos.
