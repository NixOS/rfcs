---
feature: nixos-port-alloc
start-date: 2023-06-10
author: lucasew
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

A port allocator for NixOS services.

# Motivation
[motivation]: #motivation

Sometimes people don't care about which port a service is running, only that it
should be written somewhere so a service, such as nginx, can find it.

# Detailed design
[design]: #detailed-design

The less likely used ports of the port space in a system are the higher ones,
and the highest one is 65535, so a NixOS module could keep track of which services
need a port and the service modules need only to reference that port in their
configurations.

This module exposes the options under `networking.ports`. A service module can
request a port by defining `networking.ports.service.enable = true` and get the
allocated port by referring to `networking.ports.service.port`. The service doesn't
depend on which logic the allocator uses to generate the port number. Only asks for
a port and get the port to be used.

The port allocator will allocate ports in the registered range (from 1024 to
49151) derived from a key. This key by default is the `networking.ports`
subattribute name but can be changed to any other string value in case of
conflicts. The port itself will be parsed from the MD5 hash of the key
obtained from `builtins.hashString`.

To check for conflicts, a port can be hardcoded for services that can't work on
non-default ports. This is a relevant issue for a service, but something has to
be done until it's not properly fixed and released.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

This is how the module would be used:
```nix
{ config, lib, ... }:
lib.mkIf config.service.foo.enable {
    networking.ports.foo-web.enable = true;
    service.foo.port = mkDefault config.networking.ports.foo-web.port;

    networking.ports.bar.port = config.service.bar.port; # for services that can't handle non default ports
}
```

And an already working implementation of the specification:
```nix
{ config, lib, ... }:

let
  inherit (lib) mkOption mkEnableOption types;

  MIN_RANGE = 1024;
  MAX_RANGE = 49151;

  isPortValid = port: if lib.isInt port then (port > MIN_RANGE) && (port < MAX_RANGE) else false;

  portFromKey = key:
  let
    hashed = builtins.hashString "md5" key;
    getPort = partial:
    let
      parsed = builtins.fromTOML "v=0x${lib.substring 0 4 partial}";
      port = parsed.v;
      recursiveStep = getPort (lib.substring 4 (lib.stringLength partial) partial);
    in if (isPortValid port) then port else recursiveStep;

  in getPort hashed;

  cfg = config.networking.ports;

in {
  options = {
    networking.ports = mkOption {
      default = {};
      type = types.attrsOf (types.submodule ({name, config, options, ...}: {
        options = {
          enable = mkEnableOption "port";
          key = mkOption {
            description = lib.mdDoc "Key hashed to derivate the port";
            type = types.str;
            default = name;
          };
          port = mkOption {
            description = lib.mdDoc "Port allocated";
            type = types.port;
            default = portFromKey config.key;
          };
        };
      }));
    };

    debug = mkOption {
      type = types.attrsOf types.anything;
      default = {};
    };
  };

  config = {
    # example definitions to test validation, will be removed in the final implementation
    # networking.ports.a.port = 69;
    # networking.ports.x.port = 2048;
    # networking.ports.y.port = 2048;

    assertions = let
        portNames = lib.attrNames cfg;
        # sort by port number
        cmp = a: b: cfg.${a}.port < cfg.${b}.port;
        sorted = lib.sort cmp portNames;

        pairs = lst:
        let
          ltail = lib.tail lst;
          a = lib.head lst;
          b = lib.head ltail;
          len = lib.length lst;
        in if len < 2 then []
        else [{inherit a b;}] ++ (pairs ltail);

        pairsSorted = pairs sorted;

        assertsValid = map (item: {
          assertion = isPortValid cfg.${item}.port;
          message = "The port for '${item}' (${toString cfg.${item}.port}) is invalid. If this port is derived from another to reserve a port range please change the key of the first port. If it's explicitly set then make sure it's between the range of ${toString MIN_RANGE} and ${toString MAX_RANGE}";
        }) sorted;

        assertsConflict = map (pair: {
          assertion = cfg.${pair.a}.port != cfg.${pair.b}.port;
          message = "The ports for '${pair.a}' and '${pair.b}' are the same (${toString cfg.${pair.a}.port}). This may happen because either one or both of them are explicitly set to a value or a hash collision from the key value.";
        }) pairsSorted;

      in assertsConflict ++ assertsValid;
  };
}
```

# Drawbacks
[drawbacks]: #drawbacks

- This technique shouldn't be used for services that are directly used
 externally as ports may change.

- If someone externally expects to use that service directly, the port which could be used
 to access may differ like a local IP when it's not reserved by the router so it's not
 recommended to use this module in these cases.

# Alternatives
[alternatives]: #alternatives

Keep track of which ports have been used by services and often just seeing that
the port is already being used by some other service when the activation logs show
that the service failed to start.

Forbid usage of common utility ports like 8080, 8081, 5000, 3000 and 3333.

# Unresolved questions
[unresolved]: #unresolved-questions
- Ranges of neighbour ports for torrent clients, for example.

# Future work
[future]: #future-work

Selfhosted toolkits that configure services behind a reverse proxy like nginx that
doesn't need to care which local port services are listening to.
