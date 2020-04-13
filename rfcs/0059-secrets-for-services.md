---
feature: secrets_for_services
start-date: 2019-10-29
author: @d-goldin
co-authors: (find a buddy later to help our with the RFC)

shepherd-team: Lassulus, globin, aanderse, dhess
shepherd-leader: dhess
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

This RFC introduces some interfaces, terminology and library functions to help managing
secrets for NixOS systemd services modules.

The general idea is to provide some basic infrastructure within nixos modules to
handle secrets more consistently while being able to integrate pre-existing solutions
like NixOps, a simple secrets folder or Vault.

This text should be read together with the current proof of concept implementation
in https://github.com/d-goldin/nix-svc-secrets for clarity, where the text might be lacking.

_A brief remark about the PoC: The goal of the code is to demonstrate a somewhat
working implementation based on the suggested API. The implementation is not
very robust and has a few hacks here and there. Most aspects of the
internal implementation should be changeable without impact on the API though._

# Motivation
[motivation]: #motivation

There is currently a lack of consistent and safe mechanisms to make secrets
available to systemd services in NixOS. Various modules implement it in various
ways across the ecosystem. There have also been ideas like adjustments to the
Nix Store (like [issue #8](https://github.com/NixOS/nix/issues/8)), which would
allow for non-world-readable files, but this issue has made no progress in
several years.

With the introduction of Systemd's `DynamicUser`, the more traditional
approaches of manually managing permissions of some out-of-store files could
become cumbersome or slow down the adoption of DynamicUser and other sandboxing
features throughout the nixpkgs modules.

The approach outlined in this document aims to solve only a part of the secrets
management problem, namely: How to make secrets that are already accessible on
the system (be it through a secrets folder only readable by root, or a system
like vault or nixops) available to non-interactive services in a safe way.

It assumes that shipping secrets is already solved sufficiently by krops,
nixops, git-crypt, simple rsync etc, and if not, that this can be addressed as a
separate concern without needing to change the approach proposed here. Further,
it is outside of the scope of this proposal to ensure other properties of the
secret store, such as encryption at rest.

The main idea here is to allow for flexibility in the way secrets are delivered
to the system, while at the same time providing a consistent and unobtrusive
mechanism that can be applied widely across service modules without requiring
large code-changes while allowing for a gradual transition of nixos services.

# Detailed design
[design]: #detailed-design

## Necessary preconditions:

* Delivery of secrets to target systems is a solved problem
* It's sufficiently secure to store the secrets or access tokens in a location
  only accessible by root on the system
* The secrets store locations is secure at rest, such as full-disk-encryption.
* Interactive unlocking scenarios should be treated separately
* Linux namespaces are sufficiently secure
* The service can be run using `PrivateTmp`

## Design goals:
* A set of secrets are made available to a set of services only for the duration
  of their execution
* Retrieved secrets are only accessible to the service processes and root
* Retrieved secrets are reliably cleaned up when the services stop, crash,
  receive sigkill or the system is restarted
* It should be possible to support mutliple user-configurable sources (backends)
  for secrets without need to adjust the services using secrets.
* The approach should require only few changes to migrate an existing module
  (without being too magical) and not disrupt modules that take other approaches
  or have direct support for some secrets store.
* The module author should not have to worry about different backends and be
  able to rely on a clear interface of secrets files provided and process
  environment.
* The proposed API should be general enough to accommodate changes to specific
  mechanics of storage and retrieval of keys without requiring large scale changes.
  For example if systemd would implement some new features that can replace some parts,
  those should be adopted without having to change users and modules code.

## Core concepts and terminology:

* *Secrets store* or *secrets backend*: A system (such as vault) or location
  (such as a root-only accessible folder) which stores the secrets securely and
  allows safe retrieval.
* *secrets config*: configuration settings required to generate/configure
  fetchers for a variety of backends.
* A *fetcher* function: a function whose task it is to resolve the secret
  identifier, retrieve the secret from a backend and place it in the service
  process' private namespace within `/tmp`
* *"Sidecar" service*: A privileged systemd service running the fetcher
  function to retrieve the secret, creating the private namespace for the
  consuming service.
* Service-secrets scope: provides a context in which secrets are accessible as
  attributes resolving to path names within the private namespace.

The general idea is centered around this simple process:

A privileged side-car service is launched first, creates a namespace, executes
the fetcher function which retrieves the secrets and copies them into the
private tmpfs. The side-car service and main service are configured in such a
way that restart or termination of either causes restart or termination of the
other. Once both services shut down the private tmpfs disappears.

The target service launches once the side-car service has been launched and
singalled successful retrieval of secrets (via systemd-notify), the target
service then joins the sida-cars namespace and is able to access the secrets
provided in the shared tmpfs in `/tmp` or via the environment. The service is
now free to access the file in whichever way it wants - for instance just
passing the path to the software to be launched as an argument.

Fetcher functions can be any arbitrary executable that adheres to the following
interface and life-cycle:

* It needs to be able to accept multiple secrets IDs as arguments
* It has to be configurable to access the target backend, with some settings
  that should be supported by all fetchers if possible, such as reloadOnChange
* Provides secret files and an environment file in a known location. Currently
  `/tmp/$secret_id` and `/tmp/secrets.env` (which combines all secrets in a
  single env-file)

Currently fetchers are generated and single-purpose for a specific service based
on configuration from nix, so there is no further need to configure them. But
this aspect is not strictly necessary. Further, fetchers should never persist
any state outside of the shared private tmpfs and should obviously not leak any
secrets anywhere. It is currently expected by convention that a fetcher
generates the following files for each secret ID passed: `/tmp/$secret_id`
containg exclusively the secret's payload and one file `/tmp/secrets.env` file
per service, which used by a wrapper in the consuming service to populate the
environment.

## Suggested API

The example configurations and interactions described in the this section are
taken from the proof of concept implementation in
https://github.com/d-goldin/nix-svc-secrets.

The following describes the module-author and end-user facing APIs for two
trivial services consuming a secret from a file and the environment, with two
interchangeable backend implementations.

## NixOS modules integration

As outlined in the following examples, a little bit of supporting functionality
needs to be added somewhere in the nixos modules system and libraries to house
some types useful for defining secrets config (such as some more proper version
of `secretsConfig`) and a module to manage system wide secretsStore settings.

This is mostly functionality containing some listing and implementations of
supported backends, which need to be configured by the user via their system
configuration, the fetcher logic itself, functionality to generate side-car
services and expose the secrets scope and convenience functionality like
predefined module option types.

### End-user facing API

The user of the system can configure different available backends for the system
via the secretsStore module. Those settings provide default configuration for
the different fetchers associated with each backend and can be overridden on a
per-service basis with additional service-level configuration, such as reloading
behaviour. The settings provided should be verified as much as possible to ensure
good debuggability - the example implementation uses activation scripts to superficially
check the existence of `secretsDir` and `tokenPath` (but not overridden configs passed to
the service at the moment).

```
  [...]

  secretsStore = {
    enable = true;

    vault = {
      url = "http://localhost:8200";
      mount = "secret";
      tokenPath = "/etc/secrets/service_secrets_token";
      refreshInterval = 30;
    };

    folder = {
      secretsDir = "/etc/secrets";
    };
  };

  services.secrets_test = {
    enable = true;
    secretsConfig = {
      backend = "folder";
      config = {
        secretsDir = "/etc/secrets_other/";
        reloadOnChange = true;
      };
    };
  };

  [...]
```
_Note: This example is based on https://github.com/d-goldin/nix-svc-secrets/blob/master/config.nix_

### Module author facing API

This is a minimal example of a service depending on a secret called `secret1`.
From the module authors point of view using the secretsStore would look like so:

```
[...]

let
  secrets = import ../lib/secrets.nix { inherit pkgs; inherit lib; inherit config; };
  cfg = config.services.secrets_test;

  secretsScope = secrets.serviceSecretsScope {
    loadSecrets = [ "secret1" "secret2" ];
    backendConfig = cfg.secretsConfig;
  };

in {

  options.services.secrets_test = {
    enable = mkEnableOption "Enable secrets store";
    secretsConfig = secrets.secretsBackendOption;
  };

  config = mkIf cfg.enable {

    systemd.services = secretsScope ({ secret1, ... }: {

      # A simple service consuming secrets from files
      secrets_test_file = {
        description = "Simple test service using a secret";
        serviceConfig = {
          ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/cat ${secret1}; sleep infinity'";
          DynamicUser = true;
        };
      };
    });
  };
}

[...]
```
_Note: This example is based on: https://github.com/d-goldin/nix-svc-secrets/blob/master/modules/test_service.nix_

In the above snippet a `serviceSecretsScope` is configured to load two secrets,
`secret1` and `secret2` without any direct reference to a specific backend
within the module itself.

To simplify this a pre-made convenience config option from the `secrets` library
is used to allow the end-user to define the backend config necessary to
configure the mechanism and is passed to `serviceSecretsScope` which provides
the module author with a convenience function to create fetchers, side-car service and
whatever else is required internally and "combines" regular systemd service
definitions with the side-car to provide the secrets.

The secrets requested are then made accessible to the target service's unit
definitions as arguments passed into a lambda within the scope. These arguments
then point to some private location within the namespace - in our case `secret1
-> /tmp/secret1`.

The resolution and location of the secrets is decided by the implementation and
should be rarely a concern for the user. The locations could potentially change
if other private locations besides `/tmp` become available or some other means
of providing the secret are used. It is still possible to point to the file
locations directly, but is less convenient and would not result in build time
errors when wrong paths are specified or secrets accidentally being copied to
the store when a path type is used.

For every service defined this way in a scope, a side-car container is generated
_per service_ and wired up with the target service. This means that the ability
to create a scope does not break isolation between multiple target services
but can add a little bit of developer convenience / reduce repetition for a set of
related services requiring the same secrets.

## Service lifecycle and resulting systemd units

As mentioned earlier, in order to implement features like reloading, the
life-cycles of the two services are linked together. The side-car binds to the
consuming service, defines a private `/tmp` and implicitly creates it's
namespace. When executed, the side-car service is expected to remain running for
the complete duration of the consuming service and to propagate restarts in case
of errors or the need to reload secrets. In this case the side-car uses
systemd-notify to signal it's readyness after copying the secrets to the private
temp successfully and remains running to observe changes to the secrets.

The consuming service starts up once the side-car signals readyness, hooks
itself up to the side-car service in a similar way as the other way around,
joins the side-car's namespace and executes a wrapper to inject the secrets into
it's environment.

The result is that both services are started, stopped and restarted together,
which makes it easier to to allow the side-car service to control the consuming
service and vise versa without any additional communication mechanism.

For the `secrets_test_file` service using a _folder_ backend the resulting
side-car and service units are shown. This should clarify how exactly the
services are hooked up to one another.

Side-car service:
```
[Unit]
Before=secrets_test_file.service
BindsTo=secrets_test_file.service
Description=side-cart for secrets_test_file
PartOf=secrets_test_file.service

[Service]
Environment="..."
ExecStart=/nix/store/kbimh9fsjfj7rmy6zqhpvh98kifzdgf8-file-copy-fetcher secret1 secret2
PrivateTmp=true
Restart=on-success
Type=notify
```

Target service:
```
[Unit]
Description=Simple test service using a secret
JoinsNamespaceOf=secrets_test_file-secrets.service
PartOf=secrets_test_file-secrets.service
Requires=secrets_test_file-secrets.service

[Service]
Environment="..."
DynamicUser=true
ExecStart=/nix/store/3cqqyhyac9nablpc4s7jc0v174qzxq7b-secrets-env-wrapper
PrivateTmp=true
```

_Note: The target service's ExecStart is changed to a wrapper that injects
secrets into the environment. Currently it is generated for for each service.
Both mechanisms, files and environment are always provided by the fetchers._

## Rotating secrets

In order to allow for simple rotation of secrets it should be possible to define
whether a service should be restarted when a change in the secrets is detected
and fetchers need to support checking for updates. Each backend for which it is
possible should provide a mechanism to identify changes (like inotify in "folder"
backends case or polling in vaults case) and associated settings like polling
intervals. The settings should be consistent across different backends.

Based on the examples above, reloading for "folder" and "vault" are configured
quite similarly:

```
secretsConfig = {
  backend = "folder";
  config = {
    [...]
    reloadOnChange = true;
  };
};
```

```
secretsConfig = {
  backend = "vault";
  config = {
    [...]
    reloadOnChange = true;
    pollingInterval = 10;
  };
};
```

# Drawbacks
[drawbacks]: #drawbacks

* Added complexity.
* Generation of additional systemd services.
* Restrictions on participating systemd services, such as mandatory PrivateTmp.

# Alternatives
[alternatives]: #alternatives

* One approach that has been proposed in the past is a non-world readable store,
  in issue #8 (support private files in the nix store, from 2012). While this would
  be pretty great, it's rather complex and has not made progress in a while.

* "Classical" approach of just storing secrets readable only to a service user
  and utilizing string-paths to reference them. This does not work well anymore
  with DynamicUser, which has been accepted in [RFC
  0052](https://github.com/NixOS/rfcs/blob/master/rfcs/0052-dynamic-ids.md).

* A somewhat similar approach exists in
  https://cgit.krebsco.de/stockholm/tree/krebs/3modules/secret.nix
  (loosely related to krops).

* NixOps implements a similar approach, providing a service to expose secrets
  via a systemd service after it has taken care of deployment.

# Impact of not doing this:

Continued proliferation of various, individual solutions, per module and
depending on the users environment.

Persistent confusion by new-comers and veterans alike, about what the a
recommended way looks like and a variety of different approaches within
nixos service modules.

# Unresolved questions
[unresolved]: #unresolved-questions

* Would it be better to create a side-cart per secret instead of per secret-scope+service?

# Future work
[future]: #future-work

* When using a scope with multiple services, ideally only the secrets
  referenced in the services definition should be made available to each
  service. Right now all the secrets of the scope are blindly copied.
* Transition of a few non-critical but diverse services to iterate on implementation
  and possibly missing helpers or wrappers (like template rendering).
* Implementation of more supported secret stores, such as nixops, kernel keyring etc
* Merging some attributes better than in the POC - like JoinsNamespaceOf
* Provide simple shell functions for features like loading a file into an environment
  variable and possibly some wrappers to make injecting secrets into config file templates
  easier.
* Decouple secret id name from secret file name, for convenience and to make more complex
  file names work.
