---
feature: selinux-support
start-date: 2019-03-10
author: Alexander Kahl (@e-user)
co-authors: (none yet)
related-issues: NixOS/nix#2374, NixOS/nix#2670, NixOS/nixpkgs#56965
---

[NixOS/nix#2374]: https://github.com/NixOS/nix/issues/2374
[NixOS/nix#2670]: https://github.com/NixOS/nix/pull/2670
[NixOS/nixpkgs#56965]: https://github.com/NixOS/nixpkgs/pull/56965

# Summary
[summary]: #summary

Add support for [SELinux] to Nix and NixOS. This means that Nix will be
able to write SELinux file contexts on enabled systems and NixOS will be
provided with a base policy that supports as many use cases as possible. New
options in NixOS make it possible to build Linux with SELinux support enabled.

[SELinux]: https://selinuxproject.org/page/Main_Page

# Motivation
[motivation]: #motivation

Security Enhanced Linux is a Linux kernel security feature providing mandatory
access controls. It confines processes to access files with corresponding labels
for specific purposes, such as reading and writing.

There is currently one family of Linux distributions with SELinux enforcing
active by default: [Fedora] and derivatives, which includes [Red Hat Enterprise
Linux], [CentOS], Scientific Linux and others. Several other Linux distributions
have optional support for SELinux, including [Arch], [Debian], [Ubuntu], CoreOS,
and [Gentoo].

Without explicit file contexts written to files in the Nix store and Nix
profiles, Nix-provided daemons currently cannot integrate with SELinux-enforcing
systems, as trying to run them from systemd or interacting with them with
systemctl results in kernel-level denials. This includes related issue
[NixOS/nix#2374].

Simply put, implementation of this RFC allows Nix to be run on SELinux-enabled
Linux distributions.

Additionally integrating support for SELinux in NixOS will bring an additional
level of hardening to the distribution, which increases its aptitude as a
server platform but also as a professional workstation distribution.

[Fedora]: https://fedoraproject.org/wiki/SELinux_FAQ
[Red Hat Enterprise Linux]: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/selinux_users_and_administrators_guide/index
[CentOS]: https://wiki.centos.org/HowTos/SELinux
[Arch]: https://wiki.archlinux.org/index.php/SELinux
[Debian]: https://wiki.debian.org/SELinux
[Ubuntu]: https://wiki.ubuntu.com/SELinux
[Gentoo]: https://wiki.gentoo.org/wiki/SELinux

# Detailed design
[design]: #detailed-design

The RFC can be broken down into two pieces. One is support for SELinux in Nix,
which solves the problems outlined above and serves as the enabler for the
second piece, SELinux support in NixOS.

Enabling Nix to write SELinux file contexts has already been put up as a PR,
[NixOS/nix#2670]. Before writing any new file to the Nix store or creating a new
profile, Nix checks for the designated file context and directs the SELinux
kernel interface to write that label through SELinux library calls when creating
the file. This corresponds to that other tools with support for SELinux are
doing, including package managers and systemctl. All calls to SELinux-related
functions are optional and dependent on compile-time presence of the
corresponding SELinux libraries.

For SELinux itself in order to provide sensible file contexts to Nix,
[modifications] to its userspace libraries and tools have to be
undertaken. These changes will enable the existing set of base policies for
SELinux to be re-applied to the Nix store. Careful collaboration with SELinux
maintainers will ensure the success of this endeavour. One crucial base policy
change for Nix is the adoption of `/bin` for all binaries which are commonly
installed under `/sbin` in [FHS-compliant] distributions, such as `httpd`.

[modifications]: https://lore.kernel.org/selinux/7853167.K65cXu0y11@neuromancer/T/#u
[FHS-compliant]: https://refspecs.linuxfoundation.org/FHS_3.0/fhs-3.0.pdf

Lastly, while the above will make sure Nix can fully integrate with other
SELinux-enforcing Linux distrutions, NixOS itself will have to be provided with
a base version of the SELinux policy as well as options to enable SELinux
compilation support for its Linux builds. This requires building the policy
using common utilities and installing it into `/etc`. All the required libraries
and userspace utilities for SELinux are already present in Nix but will need to
be [updated].

[updated]: https://github.com/NixOS/nixpkgs/pull/56965

Test suits will also be put into place for Nix and NixOS, respectively, to make
sure file contexts are applied and are enforced correctly.

# Drawbacks
[drawbacks]: #drawbacks

Obtaining SELinux labels and writing them to files slows down Nix considerably
in the current iteration of the PR. This might or might not be due to incorrect
implementation details, such as lack of re-use of context structs. Other than
that, the only way to mitigate this is to write SELinux labels only on enabled
systems.

Turning NixOS into an SELinux-supporting Linux distribution is not a one-shot
project but a continued endeavour, occasionally requiring close collaboration
with upstream developers. While not a drawback per se, it means that overall
long-term maintenance of the distribution will be increased. One possible
contigency plan can be to drop SELinux support in NixOS at any time but keep
the support in Nix.

While re-using and mending the existing SELinux base policy eases the initial
adoption greatly, it is not particularly idiomatic for Nix. The policy includes
corner-cases for every supported distribution of Linux and is built using M4
macro processing. Turning the build process into something that can be steered
from a Nix expression might be viable, but is a very long shot which would
alienate NixOS from SELinux upstream development.

# Alternatives
[alternatives]: #alternatives

The proposed implementation relies on updated versions of SELinux on the host
operating system and will not work on older systems. In its current iteration,
the [Nix PR] still installs a "dumb" supplementary SELinux policy module which
works around that problem by applying very liberal labels to every path in the
store, in a manner compatible with older versions of SELinux. By detecting the
host's version of SELinux, this mechanism could be kept to work around this
problem.

[Nix PR]: https://github.com/NixOS/nix/pull/2670

As outlined above in [drawbacks], it would theoretically be possible to build
per-derivation context paths and even file contexts from Nix expressions,
essentially rendering existing base policies as well as any dependency on newer
SELinux versions obsolete. However, this would mean re-building the base policy
from scratch and maintaining a completely detached version with no upstream
support.

Ultimately, it is also possible to split up this RFC into two separate RFCs,
covering Nix and NixOS integration, respectively.

# Unresolved questions
[unresolved]: #unresolved-questions

- Should this RFC be split up to cover NixOS separately?
- Is there an incentive to leave the mainstream policy process to attain
  idiomatic, expression-level integration of policy building in Nix?
- How do we ensure long-term sustainability of the integration, once
  accomplished?
- How do we test the integration for other Linux distributions?

# Future work
[future]: #future-work

While the RFC has only touched on file context level security, SELinux
optionally supplies a whole other level of additional security, _Multi-Level
Security_ (MLS), featuring _sensitivity levels_ and _categories_. MLS is not
covered by this RFC.

Potential future work also encompasses the aforementioned, optional policy
building process alternative.
