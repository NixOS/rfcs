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
should be written somewhere so a service such as nginx can find it.

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

The port allocator will allocate ports decremented from 65535 so it's very unlikely
that it will reach ports under 1024. Because of the ordered nature of attrsets.


# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

This is how the module would be used:
```nix
{ config, lib, ... }:
lib.mkIf config.service.foo.enable {
    networking.ports.foo-web.enable = true;
    service.foo.port = mkDefault config.networking.ports.foo-web.port;
}
```

And an already working implementation of the specification:
```nix
{ config, lib, ... }:

let
  inherit (builtins) removeAttrs;
  inherit (lib) mkOption types submodule literalExpression mdDoc mkDefault attrNames foldl' mapAttrs mkEnableOption attrValues;
in

{
  options.networking.ports = mkOption {
    default = {};

    example = literalExpression ''{
      {
        app.enable = true;
      }
    }'';

    description = "Build time port allocations for services that are only used internally";

    apply = ports: lib.pipe ports [
      (attrNames) # gets only the names of the ports
      (foldl' (x: y: x // {
        "${y}" = (ports.${y}) // {
          port = x._port;
        };
        _port = x._port - 1;
      })  {_port = 65534; }) # gets the count down of the ports
      (x: removeAttrs x ["_port"]) # removes the utility _port entity
    ];

    type = types.attrsOf (types.submodule ({ name, config, options, ... }: {
      options = {
        enable = mkEnableOption "Enable automatic port allocation for service ${name}";
        port = mkOption {
          description = "Allocated port for service ${name}";
          type = types.nullOr types.port;
        };
      };
    }));
  };

  config.environment.etc = lib.pipe config.networking.ports [
    (attrNames)
    (foldl' (x: y: x // {
      "ports/${y}" = {
        inherit (config.networking.ports.${y}) enable;
        text = toString config.networking.ports.${y}.port;
      };
    }) {})
  ];
}
```

# Drawbacks
[drawbacks]: #drawbacks

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

How to allocate blocks of ports so something like a torrent client can use that to
listen for p2p traffic?

How to reserve higher ports to services so the automatic allocator skips them?

# Future work
[future]: #future-work

Selfhosted toolkits that configure services behind a reverse proxy like nginx that
doesn't need to care which local port services are listening to.
