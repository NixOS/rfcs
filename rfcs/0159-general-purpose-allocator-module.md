---
feature: general-purpose-allocator-module
start-date: 2023-08-11
author: lucasew
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

A function that generates a suggestion based item allocator module.

# Motivation
[motivation]: #motivation

Sometimes there are some values that the user don't actually care about which
value a option will get in some kind of space as long is a valid one and doesn't
conflict with other definitions.

One of these spaces, for example, is the port space, like, non administrative ports
for servers (1025..49151). You will probably put a reverse proxy in front of it
so even the stability of the port number is not so important.

# Detailed design
[design]: #detailed-design

A function that receives the following parameters:
- `enableDescription`: The description of the enable option for one of the resources. Can also be a function that receives the value name and returns the description.
- `valueKey`: Key of the allocated value, like `value` or `port`. By default is `"value"`.
- `valueType`: Type of the value as the `type` parameter of `mkOption`. By default, as `mkOption`, is `null`.
- `valueApply`: Apply function passed to the value `mkOption`. By default, as `mkOption`, is `null`.
- `valueLiteral`: User friendly string representation of the value. By default is string-enclosed value passed to `keyFunc`.
- `valueDescription`: The description of the value option for one of the resources. Can also be a function that receives the value name and returns the description.
- `firstValue`: First item allocated. By default is `0`.
- `keyFunc`: Function that transforms the value to string in a way that uniquely identified the value for conflict checking. By default is `toString`.
- `succFunc`: Get the next value in the allocation space, like the next port or the next item of some item. This parameter is required.
- `validateFunc`: Function that returns if some value is valid. By default is the `valueType.check` function.
- `cfg`: As most of the module definitions in NixOS, receives the resolved reference of the option being defined.
- `keyPath`: Path in the module system to the option being defined. Used to give better error messages.
- `example`, `internal`, `relatedPackages`, `visible` and `description`: Just passed through to the outer `mkOption`.

This function will return a NixOS module system module that will follow the following rough schema:

```
<keyPath> = {
    <name> = {
        enable: boolean = false;
        <valueKey>: <valueType> = null;
    };
}
```
The values checking will happen in the following order:

- If any `<keyPath>.<name>.enable` is true and `<keyPath>.<name>.<valueKey>` is `null` it will suggest the next value available.

- If any more than one `<keyPath>.<name>` has the same `<keyFunc> <keyPath>.<name>.<valueKey>` it will suggest that one of the values is changed to the suggested value.

- If any `<keyPath>.<name>.enable` is true and `<validateFunc> <keyPath>.<name>.<keyFunc>` is `false` then it will list all the invalid value keys and suggest to change the first value key to the suggested value.

Only one suggested value is generated per evaluation in one module, so it will give up on first fail.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

This is an example of a port allocator using the function, plus a usage example:

```nix
{ config, lib }:
let
    inherit (lib) types;
    inherit (__future__) mkAllocModule;
in {
    options.networking.ports = mkAllocModule {
        valueKey = "port";
        valueType = types.port;
        cfg = config.networking.ports;
        description = "Build time port allocations for services that are only used internally";
        enableDescription = name: "Enable automatic port allocation for service ${name}";
        valueDescription = name: "Allocated port for service ${name}";

        firstValue = 49151;
        succFunc = x: x - 1;
        valueLiteral = toString;
        validateFunc = x: (types.port.check x) && (x > 1024);
        keyPath = "networking.ports";
        example = literalExpression ''{
            app = {
                enable = true;
                port = 42069; # guided
            };
        }'';
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
    config.networking.ports = {
        eoq = {
            enable = false;
            port = 22;
        };
        trabson = {
            enable = true;
            port = 49139;
        };
    };
}
```

# Drawbacks
[drawbacks]: #drawbacks

Evaluation time: the validation will need to happen everytime the module is used and the time it takes may be a problem. Allocators with many values can use a lot of recursion. IFD with an imperactive or a tail call optimized functional programming language for the validation phase may help.

# Alternatives
[alternatives]: #alternatives

Setting values by hand and hoping these values don't conflict on runtime.

Just allocate items without logic for reserving values as suggested initially by [RFC 151](https://github.com/NixOS/rfcs/pull/151).

# Unresolved questions
[unresolved]: #unresolved-questions

Is this the right abstraction for a generic allocator?

What about non primitive value allocations?

What about maybe some kind of space that has 2D conflicts that would require two keys to keep track or some kind of nesting like subnets?

Are function parameter names good enough?

# Future work
[future]: #future-work

Multiple machine based deployments.

Network allocation for NixOS cluster guests.

IPs for NixOS containers.

Port allocation for local running services.
