---
feature: hydra-nixos-org-terraform
start-date: 2021-08-27
author: Graham Christensen
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Manage hydra.nixos.org's project and jobset configuration as code with
Terraform, terraform-provider-hydra, a configuration repository, and a
continuous deployment process.

# Motivation
[motivation]: #motivation

Managing the configuration by hand can be troublesome when
administrators, trying to solve a problem, tweak settings by hand without
clearly communicating their changes and intent with other administrators.

Users of various trust levels often request temporary jobsets to test
high-impact pull requests. In many cases users are long-term, trustworthy
contributors to the project. However expanding the group of
administrators has the side effect of increasing the potential for
confusion around Hydra configuration changes.

Furthermore, Hydra has no memory of jobset configuration, history of
changes, or audit log for administrative actions. Hydra is a
security-critical tool and provides a root of trust for the project. In
particular, the configuration of jobsets which originate channels in
are in the critical path of determining what and when channel advances
take place.

Using a centralized configuration repository and continuous deployment
process increases communication, transparency, and provides an auditable
log of configuration changes.

With these features, we are able to more liberally give contributors
the privilege of managing projects and jobsets on Hydra.

# Detailed design
[design]: #detailed-design

## Workflow
[workflow]: #workflow


* We will adopt Terraform and [terraform-provider-hydra](https://github.com/DeterminateSystems/terraform-provider-hydra)
  for managing the configuration.
* The relevant Terraform configuration files will be stored in a GitHub
  repository named `NixOS/hydra-nixos-org-configuration`.
* The repository will not allow direct pushes to the primary branch, and
  will require pull requests. Appropriate CI steps should exist to validate
  formatting and validity of the PR'd changes.
* A BuildKite account will be created for the NixOS organization, and
  a BuildKite runner will be configured on the NixOS server named `bastion`.
* After merging changes, a BuildKite task will run `terraform plan`, prompt
  for approval to continue, then run `terraform apply`.
* The Terraform state will be stored in a private S3 bucket administered by
  the NixOS Foundation.

_A note about BuildKite:_ BuildKite is selected to maintain control of
the worker and execution, while also providing transparency to users.
The BuildKite agent is already packaged in NixOS. BuildKite is a paid
service, but they readily allow OSS projects to use it for free.

## Migration
[migration]: #migration

The Hydra provider for Terraform includes a tested import tool for
converting a manually managed Hydra instance in to the corresponding
Terraform configuration.

With that tool, the process for migrating is as follows:

1. The repository and BuildKite infrastructure is created and tested
   against a test Hydra, verifying the workflows execute correctly.
1. The `admin` and `create-projects` role is revoked from every account.
1. A new user is created for Terraform to use. This user is granted `create-projects`.
1. All projects have their `owner` changed to the new Terraform user.
1. The import tool is run, producing a repository of `.tf` files.
1. `terraform plan` is executed, verifying the generated `.tf` files are correct.
1. The repository's BuildKite configuration is altered to operate against
   hydra.nixos.org.
1. The NixOS manual for release managers is updated to instruct Release Managers
   to use this repository for their jobsets.

## Access
[acccess]: #access

* All users which currently have the `create-projects` and `admin` roles
  will be granted merge privileges on the repository.
* Long term, trusted members of the project can request merge access. These
  requests will be evaluated by the Infrastructure and Security team, and
  the decision is ultimately up to the Infrastructure team.
* Jobsets which are the origination point for channels will be maintained
  in specially named files, and the GitHub Code Owners feature will be used
  to require Infrastructure team members to approve changes to those jobsets.
* The BuildKite pipeline will be totally public, allowing anyone to view
  its execution logs.
* All users who are allowed to _merge_ changes will be allowed to trigger
  builds and unblock the `terraform apply` step.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

Contributors can send a pull request for desired Hydra configuration
changes over Matrix, IRC, or a GitHub issue. Contributors can easily copy
the configuration of an existing jobset and modify it to match their needs.

For example, the current `nixos` project configuration looks like this

```terraform
resource "hydra_project" "nixos" {
  name         = "nixos"
  display_name = "NixOS"
  homepage     = "http://nixos.org/nixos"
  description  = "NixOS, the purely functional Linux distribution"
  owner        = "eelco"
  enabled      = true
  visible      = true
}
```

The NixOS `unstable-small` jobset looks like this:

```terraform
resource "hydra_jobset" "nixos_unstable-small" {
  project     = hydra_project.nixos.name
  state       = "enabled"
  visible     = true
  name        = "unstable-small"
  type        = "legacy"
  description = "NixOS small unstable channel"

  nix_expression {
    file  = "nixos/release-small.nix"
    input = "nixpkgs"
  }

  input {
    name              = "nixpkgs"
    type              = "git"
    value             = "https://github.com/NixOS/nixpkgs.git"
    notify_committers = false
  }

  input {
    name              = "stableBranch"
    type              = "boolean"
    value             = "false"
    notify_committers = false
  }

  check_interval    = 43200
  scheduling_shares = 20000
  keep_evaluations  = 3

  email_notifications = false
  email_override      = ""
}
```

# Drawbacks
[drawbacks]: #drawbacks

* Current users with the `admin` or `create-projects` role, and projects
  owners looking to make immediate changes will have a more involved
  process to follow.
* Issues with the Terraform provider or Hydra's API may cause surprising
  or unwanted changes or behavior.
* Issues with GitHub, AWS S3, or BuildKite's availability will prevent
  configuration changes.

# Alternatives
[alternatives]: #alternatives

* Remain at the status-quo of a few limited administrators and low
  change transparency.
* Implement an audit log of administrative actions for Hydra.
* Use GitHub Actions over BuildKite.
* Use a fully open source CI/CD tool over BuildKite or GitHub Actions.

# Unresolved questions
[unresolved]: #unresolved-questions

* What tasks do Hydra administrators perform through the web UI which
  will no longer be possible?

# Future work
[future]: #future-work

n/a
