---
feature: secrets_for_services
start-date: 2019-10-29
author: @d-goldin
co-authors: (find a buddy later to help our with the RFC)

shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

This RFC introduces some interfaces, terminology and library functions to help managing
secrets for NixOS systemd services modules.

The general idea is to provide some basic infrastructure within nixos modules to
handle secrets more consistently while being able to integrate pre-existing solutions
like NixOps, or a simple secrets folder.

# Motivation
[motivation]: #motivation

There is currently a lack of consistent and safe mechanisms to make secrets
available to systemd services in NixOS. Various modules implement it in various
ways across the ecosystem. There have also been ideas like adjustments to the
Nix Store (like issue https://github.com/NixOS/nixpkgs/issues/8), which
would allow for non-world-readable files, but this issue has made no progress
in several years.

With the introduction of Systemd's `DynamicUser`, the more traditional
approaches of manually managing permissions of some out-of-store files could
become cumbersome or slow down the adoption of DynamicUser and other sandboxing
features throughout the nixpkgs modules.

The approach outlined in this document aims to solve only a part of the secrets
management problem, namely: How to make secrets that are already accessible on the
system (be it through a secrets folder only readable by root, or a system like
vault or nixops) available to non-interactive services in a safe way.

It assumes that shipping secrets is already solved sufficiently by krops, nixops,
git-crypt, simple rsync etc, and if not, that this can be addressed as a separate
concern without needing to change the approach proposed here. Further, it is outside
of the scope of this proposal to ensure other properties of the secret store, such as
encryption at rest.

The main idea here is to allow for flexibility in the way secrets are delivered to the
system, while at the same time providing a consistent and unobtrusive mechanism that can
be applied widely across service modules without requiring large code-changes while allowing
for a gradual transition of nixos services.

# Detailed design
[design]: #detailed-design

To summarize, necessary preconditions:

* Delivery of secrets to target systems is a solved problem
* It's sufficiently secure to store the secrets or access tokens in a location
  only accessible by root on the system
* The secrets store locations is secure at rest, such as full-disk-encryption.
* Interactive unlocking scenarios are should be treated separately
* Linux namespaces are sufficiently secure
* The service can be run using `PrivateTmp`

Design goals:
* A set of secrets are made available to a set of services only for the duration of their execution
* Retrieved secrets are only accessible to the service processes and root
* Retrieved secrets are reliably cleaned up when the services stop, crash,
  receive sigkill or the system is restarted

Core concepts and terminology:

* *Secrets store*: a secure file-system based location, in this document
  `/etc/secrets`, only accessible to root
* A *fetcher* function: a function whose task it is to resolve the secret
  identifier, retrieve the secret and place it in the service process' private
  namespace within /tmp name
* Simple helper functions to *enrich* expressions defining systemd services
  with secrets
* "Side-car" service: A privileged systemd service running the fetcher
  function to retrieve the fetcher function, and initially create the service
  namespace
* Secrets scope: provides a context in swhich secrets are accessible as
  attributes resolving to path names within the private namespace

The general idea is centered around this simple process:

A privileged side-car service is launched first, creates a namespace, executes
the fetcher function which retrieves the secrets and copies them into the private
tmpfs. The side-car service binds to the target service to ensure that it's shut
down and the namespace is destroyed when the target service disappears. The side-car
uses `RemainAfterExit` to keep the namespace open for other services.

The target service launches once the side-car service has been launched,
the target service then joins its namespace with the side-car namespace
and is able to access the secrets provided in the shared tmpfs in `/tmp`.
The service is now free to access the file in whichever way it wants -
for instance just passing the path to the software to be launched as
an argument, or load it up into an environment variable.

Example of user-facing API:

```
let
   secretsScope = mkSecretsScope {
     loadSecrets = [ "secret1" "secret2" ];
     type = "folder";
   };
in
   systemd.services = secretsScope ({ secret1, ... }: {
      foo = {
        description = "Simple test service using a secret";
        serviceConfig = {
          ExecStart = "${pkgs.coreutils}/bin/cat ${secret1}";
          DynamicUser = true;
        };
      };
    };
```

This is a minimal example of a service depending on a secret called `secret1`.

More specifically, in this example a secrets scope is created - to allow for
extensibility and differentiation a store has a type. In this case "folder"
denotes a secrets store in the form of a root-only accessible locked down
directory on the local filesystem. Here we want to acquire access to
2 secrets, and 2 secrets only, which are specified in `loadSecrets`, by
their id. How a secrets identifier is resolved, should be up to the fetcher
function and here it's just trivially the file-name (this of course does not
allow for file extensions).

These secrets are then made acessible to the target service's unit definitions as
arguments passed into a lambda within the scope. These arguments then point to
some private location within the namespace - in our case `secret1 ->
/tmp/secret1`.

The resolution and location of the secrets is decided by the implementation and
should be of little concern to the user as it could potentially change if other
private locations besides `/tmp` become available. It is still possible
to point to the file locations, but is less convenient and
would not result in build time errors when wrong paths are specified - thus the
arguments add a little bit of convenience and safety, aside from the indirection
they offer.

For every service defined this way in a scope, a side-car container is generated
_per service_ and wired up with the target service. This means that the ability
to create a scope does not break isolation between multiple target services
but can add a little bit of developer convenience.



A working POC example can be found in https://github.com/d-goldin/nix-svc-secrets/blob/master/secrets-test.nix.
In this example the target service is forced/asserted to utilize `PrivateTmp=true`.

For the above simple case, the generated service definitions looks like the following:

Side-car service:

```
[Unit]
Before=foo.service
BindsTo=foo.service
Description=side-car for foo

[Service]
Environment="[...]"

ExecStart=/nix/store/v1bm9bnmbxbq9740yj0a64b3vz3y7ryz-secrets-copier secret1 secret2
PrivateTmp=true
RemainAfterExit=true
Type=oneshot
```

Target service:

```
[Unit]
Description=Simple test service using a secret
JoinsNamespaceOf=foo-secrets.service

[Service]
Environment="[...]"

DynamicUser=true
ExecStart=/nix/store/3kqc2wmvf1jkqb2jmcm7rvd9lf4345ra-coreutils-8.31/bin/cat /tmp/secret1
PrivateTmp=true
```

## NixOS modules integration

To implement an interface as outlined above, a little bit of supporting functionality
needs to be added somewhere in the nixos library functionality.

An example of some needed functions, of which some could be user exposed configuration,
is shown in https://github.com/d-goldin/nix-svc-secrets/blob/master/secretslib.nix.

This is mostly functionality containing a _registry_ of existing fetchers, which
might need to be configured by the user via their system configuration, the
fetcher logic itself and functionality to generate side-car services and
expose the secrets scope.

## Rotating secrets

Right now, secrets rotation is not done automatically. When new secrets are
pushed, it is the responsibility of the user to restart the services affected.

It is assumed that once secrets are rotated, old secrets will become invalid and
no further harm is done aside from failing to access the resources (and possibly
restart on its own).

It would be possible to allow for automatic restarts using systemd path monitors.
Also see _Future work_.

# Drawbacks
[drawbacks]: #drawbacks

I can't really think of a serious drawback right now, but hopefully the
RFC process can surface some.

One aspect is of course the additional number of services generated, but this
does not seem to be a big issue when using NixOps.

# Alternatives
[alternatives]: #alternatives

* One approach that has been proposed in the past is a non-world readable store,
  in issue #8 (support private files in the nix store, from 2012). While this would
  be pretty great, it's rather complex and has not made progress in a while.

* "Classical" approach of just storing secrets readable only to a service user and
  utilizing string-paths to reference them. This does not work well anymore with
  DynamicUser.

* A somewhat similar approach exists in
  https://cgit.krebsco.de/stockholm/tree/krebs/3modules/secret.nix
  (loosely related to krops).

* NixOps implements a similar approach, providing a service to expose secrets
  via a systemd service after it has taken care of deployment.

Impact of not doing this:

Continued proliferation of various, individual solutions, per module and
depending on the users environment.

Persistent confusion by new-comers and veterans alike, about what the a
recommended way looks like and a variety of different approaches within
nixos service modules.

# Unresolved questions
[unresolved]: #unresolved-questions

* Is it sufficient to put responsibility on restarting services after key changes
  onto the user or would an automated mechanism be better?

* Would it be better to create a side-cart per secret instead of per secret-scope+service?

# Future work
[future]: #future-work

* When using a scope with multiple services, ideally only the secrets
  referenced in the services definition should be made available to each
  service. Right now all the secrets of the scope are blindly copied.
* Transition of most critical services to use proposed approach
* Implementation of more supported secret stores, such as nixops and vault
* Optional restarting for services affected by rolled secrets
* Merging some attributes better than in the POC - like JoinsNamespaceOf
* Provide simple shell functions for features like loading a file into an environment
  variable and possibly some wrappers to make injecting secrets into config file templates
  easier.
* Decouple secret id name from secret file name, for convenience and to make more complex
  file names work.
