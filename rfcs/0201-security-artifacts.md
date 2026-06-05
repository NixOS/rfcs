---
feature: security-artifacts-backend-agnostic
start-date: 2026-05-13
author: Mutasem Kharma
co-authors:
shepherd-team:
shepherd-leader:
related-issues: https://github.com/NixOS/nixpkgs/pull/519619
---

# Summary
[summary]: #summary

Introduce `security.artifacts`, a backend-agnostic abstraction layer for managing secrets in NixOS. This feature decouples NixOS service modules from specific secret providers (like `sops-nix`, `agenix`, or `systemd-creds`), allowing users to uniformly declare and inject secrets without vendor lock-in.

# Motivation
[motivation]: #motivation

Currently, NixOS modules handle secrets inconsistently. Some modules hardcode support for specific secret managers, while most simply provide options like `passwordFile` or `secretFile` and leave it to the user to manually wire up their chosen secret manager. This results in fragile configurations, tight coupling, and difficult migrations when switching between secret backends (e.g., from `agenix` to `sops-nix`).

A unified interface will:
1. Provide a standard way for NixOS services to consume secrets natively.
2. Standardize filesystem permissions, systemd ordering, and deployment paths.
3. Allow users to easily switch secret backends without rewriting their entire service configuration.

# Detailed design
[design]: #detailed-design

This RFC proposes the `security.artifacts` module tree:

1. **Option Declaration**:
   `security.artifacts.secrets.<name>` accepts a submodule configuring the owner, group, mode, target path, and **optional per-secret provider**.

2. **Providers**:
   The abstraction supports pluggable backends (`security.artifacts.provider`):
   - `sops-nix`
   - `agenix`
   - `systemd-creds`
   - `external` (Assumes secret is provisioned outside of NixOS, e.g. cloud-init)
   - `dummy` (for CI/CD environments where secrets are mocked plaintext)

   Users can set a global provider or override it per-secret, allowing for mixed configurations (e.g. TPM2-bound local secrets via `systemd-creds` alongside shared GitOps secrets via `sops-nix`).

3. **Systemd Synchronization**:
   A global systemd target `nixos-artifacts-secrets.target` is introduced. All secrets must be provisioned before this target is reached. Downstream services that consume secrets simply need `Wants = [ "nixos-artifacts-secrets.target" ]` and `After = [ "nixos-artifacts-secrets.target" ]`.

4. **Security Assertions**:
   Evaluation-time assertions guarantee that the resolved paths of the secrets do not leak into `/nix/store` and that required source files are specified for providers that need them.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

### Basic Usage with `sops-nix`:

```nix
security.artifacts.enable = true;
security.artifacts.provider = "sops-nix";

security.artifacts.secrets."postgres-pw" = {
  owner = "postgres";
  group = "postgres";
  mode = "0400";
  source = ./secrets/postgres.yaml;
};

services.postgresql = {
  enable = true;
  # Explicitly reference the artifact path
  passwordFile = config.security.artifacts.secrets."postgres-pw".path;
};
```

### Mixed Providers (TPM2 + GitOps):

```nix
security.artifacts.enable = true;
security.artifacts.provider = "sops-nix"; # Global default

security.artifacts.secrets = {
  "shared-app-key" = {
    source = ./secrets/app.yaml;
  };
  
  "local-tpm-secret" = {
    provider = "systemd-creds"; # Override global default
    path = "/run/secrets/tpm-key";
  };
};
```

If the user switches to `agenix`, they simply change the `provider` string, and the system seamlessly uses the new backend without requiring any changes to the `postgresql` configuration or the file paths.

# Drawbacks
[drawbacks]: #drawbacks

- **Ecosystem Fragmentation during Transition**: Until all major NixOS services adopt this standard, some services will use `security.artifacts` while others will continue using `LoadCredential` or raw paths.
- **Maintenance of Translation Layers**: The translation layers for out-of-tree backends (`agenix`, `sops-nix`) will need to be kept up to date with upstream changes.

# Alternatives
[alternatives]: #alternatives

- **Status Quo**: Continue using `passwordFile` options and leave integration up to the user. This keeps NixOS core simpler but pushes complexity to the end-user.
- **systemd-creds Only**: Force all secrets to use `systemd-creds`. While powerful, `systemd-creds` does not natively support GitOps workflows (e.g. encrypting with age/PGP and committing to a repo) as easily as `sops` or `agenix` without significant wrapper tooling.

# Prior art
[prior-art]: #prior-art

- **sops-nix**: Pioneered the `sops.secrets.<name>` pattern, which heavily inspired this RFC's interface.
- **agenix**: Similar pattern using `age.secrets.<name>`.

# Unresolved questions
[unresolved]: #unresolved-questions

- Should `security.artifacts` also handle dynamically generated secrets (e.g. `nixos-generate-config` generating an SSH key) rather than just static deployed secrets?

# Future work
[future]: #future-work

- Porting all `services.*` modules to natively consume `security.artifacts` instead of `passwordFile` strings.
- Implementing automatic systemd dependency injection (automatically adding `After = [ "nixos-artifacts-secrets.target" ]` to services that reference an artifact).
