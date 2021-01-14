---
feature: config-option
start-date: 2019-03-10
author: Silvan Mosberger
co-authors:
shepherd-leader: Jörg Thalheim
shepherd-team: Jörg Thalheim, Eelco Dolstra, Robert Helgesson
related-issues: https://github.com/NixOS/nixpkgs/pull/65728, https://github.com/NixOS/nixpkgs/pull/70138, https://github.com/NixOS/nixpkgs/pull/75584, TBD
---

# Summary
[summary]: #summary

## Part 1: Structural `settings` instead of stringly `extraConfig`
[part1]: #part-1-structural-settings-instead-of-stringly-extraconfig

NixOS modules often use stringly-typed options like `extraConfig` to allow specifying extra settings in addition to the default ones. This has multiple disadvantages: The defaults can't be changed, multiple values might not get merged properly, inspection of it is almost impossible because it's an opaque string and more. The first part of this RFC aims to discourage such options and encourage people to use the `settings` pattern instead, which can encode the modules configuration file as a structural Nix value. Here is an example showcasing some advantages:

```nix
{
  # Old way
  services.foo.extraConfig = ''
    # Can't be set in multiple files because string concatenation doesn't merge such lists
    listen-ports = 456, 457, 458 
    
    # Can't override this setting because the module hardcodes it
    # bootstrap-ips = 172.22.68.74

    enable-ipv6 = 0
    ${optionalString isServer "check-interval = 3600"}
  '';
  
  # New way
  services.foo.settings = {
    listen-ports = [ 456 457 458 ];
    bootstrap-ips = [ "172.22.68.74" ];
    enable-ipv6 = false;
    check-interval = mkIf isServer 3600;
  };
}
```

Jump to the [detailed design][part1-design] of part 1, which also shows how a module implementing the `settings` approach might look like.

## Part 2: Balancing module option count
[part2]: #part-2-balancing-module-option-count

Since with this approach there will be no more hardcoded defaults and composability is not a problem anymore, there is not a big need to have NixOS options for every setting anymore. Traditionally this has lead to huge modules with dozens of options, each of them only for a single field in the configuration. Such modules are problematic because they're hard to write, review and maintain, are generally of lower quality, fill the option listing with noise and more. Additional options aren't without advantages however: They are presented in the NixOS manual and can have better type checking than the equivalent with `settings`.

The second part of this RFC aims to encourage module authors to strike a balance for the number of additional options such as to not make the module too big, but still provide the most commonly used settings as separate options. Quality is encouraged over quantity: Authors should spend more time on writing documentation, NixOS tests or useful high-level abstractions. This is in contrast to the fiddly labor of copying dozens of options from upstream to NixOS. With a `settings` option, it's also very easy to add additional options over time if the need arises. In contrast, removing options has always been nigh impossible.

Jump to the [detailed design][part2-design] of part 2

# Motivation
[motivation]: #motivation

## [Part 1][part1]

Stringly-typed options such as `extraConfig` have multiple disadvantages in comparison to a structural `settings` option.
- Impossible to even implement correctly with configuration formats like JSON (because concatenation doesn't make sense)
- Bad modularity
  - No proper merging: Multiple assignments get merged together with string concatenation which can't merge assignments of the same setting
  - No priorities: `mkDefault` and co. won't work on settings
- Values within it can't be inspected, since it's just an opaque string
- Syntax of assigned values can easily be wrong, especially with escaping sequences
- Can break services if users assign a value to `extraConfig` which later gets turned into a specialized option, [here](https://github.com/NixOS/nixpkgs/commit/23d1c7f4749#diff-d66632f8013e5976f782de43a0043604R750) is an example of this.

## [Part 2][part2]

NixOS modules with dozens of options aren't optimal for these reasons:
- Writing takes a lot of time and is a repetitive task of copying the settings from upstream
- Reviewing is tedious because of the big size of it, which in turn demotivates reviewers to even do it
- The option listing will be filled with a lot of options almost nobody ever needs, which in turn makes it hard for people to find the options they *do* need.
- Maintenance is hard to keep up with because upstream can add/remove/change settings over time
  - If the module copied defaults from upstream, these might need to be updated. This is especially important for security. A workaround is using `types.nullOr` with `null` signifying that the upstream default should be used, but that's not very nice.
  - Documentation will get out of date as the package updates
  - If upstream removes a setting, the NixOS module is broken for every user until somebody fixes it with a PR.
- With overlays or `disabledModules`, the user can bring the NixOS module out of sync with the package in nixpkgs, which can lead to the same problems as in the previous point.
- The bigger the module, the more likely it contains bugs
- Responsibility for backwards compatibility is now not only in upstream, but also on our side.
- Making a module with many options is a one-way ticket, because options can't really be removed again. Smaller modules however can always scale up to more needs with more options.

By not doing the tedious work of writing out dozens of options, module authors also have more time to do more meaningful work such as
- Writing a NixOS test
- Writing documentation
- Implementing high-level options that tie different NixOS modules together in non-trivial ways (e.g. `enableACME`)

Problem instances:
- The [i2pd module](https://github.com/NixOS/nixpkgs/blob/2a669d3ee1308c7fd73f15beb35c0456ff9202bc/nixos/modules/services/networking/i2pd.nix) has a long [history](https://github.com/NixOS/nixpkgs/commits/2a669d3ee1308c7fd73f15beb35c0456ff9202bc/nixos/modules/services/networking/i2pd.nix) of option additions due to upstream updates, bug fixes and documentation changes
- Because prometheus uses options to encode every possible setting, PR's like [#56017](https://github.com/NixOS/nixpkgs/pull/56017) are needed to allow users to set a part of the configuration that wasn't encoded yet.
- Because strongswan-ctl uses options to encode its full configuration, changes like [#49197](https://github.com/NixOS/nixpkgs/pull/49197) are needed to update our options with upstream changes.

These are only examples of where people *found* problems and fixed them. The number of modules that have outdated options and require maintenance is probably much higher.


# Detailed design
[design]: #detailed-design

## [Part 1][part1]
[part1-design]: #part-1-1

It's already possible to write generic `settings` options today, using PR's introducing [`pkgs.formats`](https://github.com/NixOS/nixpkgs/pull/75584) and [freeform modules](https://github.com/NixOS/nixpkgs/pull/82743) when needed. Documentation for these features and how to use them for declaring `settings` options already exists in the manual: [Options for Program Settings](https://nixos.org/manual/nixos/stable/index.html#sec-settings-options) and [Freeform Modules](https://nixos.org/manual/nixos/stable/index.html#sec-freeform-modules).

Using these features, a module supporting `settings` might look like

```nix
{ options, config, lib, pkgs, ... }:
let
  cfg = config.services.foo;
  # Define the settings format used for this program
  settingsFormat = pkgs.formats.json {};
in {

  options.services.foo = {
    enable = lib.mkEnableOption "foo service";

    settings = lib.mkOption {
      type = lib.types.submodule {

        # Declare that the settings option supports arbitrary format values, json here
        freeformType = settingsFormat.type;

        # Declare an option for the port such that the type is checked and this option
        # is shown in the manual.
        options.port = lib.mkOption {
          type = lib.types.port;
          default = 8080;
          description = ''
            Which port this service should listen on.
          '';
        };

      };
      default = {};
      # Add upstream documentation to the settings description
      description = ''
        Configuration for Foo, see
        <link xlink:href="https://example.com/docs/foo"/>
        for supported values.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # We can assign some default settings here to make the service work by just
    # enabling it. We use `mkDefault` for values that can be changed without
    # problems
    services.foo.settings = {
      # Fails at runtime without any value set
      log_level = lib.mkDefault "WARN";

      # We assume systemd's `StateDirectory` is used, so this value is required
      # therefore no mkDefault, forcing the user to use mkForce to override it
      data_path = "/var/lib/foo";

      # Since we use this to create a user we need to know the default value at
      # eval time
      user = lib.mkDefault "foo";
    };

    environment.etc."foo.json".source =
      # The formats generator function takes a filename and the Nix value
      # representing the format value and produces a filepath with that value
      # rendered in the format
      settingsFormat.generate "foo-config.json" cfg.settings;

    # We know that the `user` attribute exists because we set a default value
    # for it above, allowing us to use it without worries here
    users.users.${cfg.settings.user} = {};

    # ...
  };
}
```

This RFC proposes to agree upon making this the standard way to specify configuration when this approach is feasible. Notably infeasible for this approach are configuration file formats that can't be directly mapped to Nix, such as bash, python, and others.

## [Part 2][part2]
[part2-design]: #part-2-1

The second part of this RFC aims to encourage people to write better NixOS modules in terms of quality, maintainability and discoverability by limiting NixOS options representing single settings to a set of most "valuable" options. The general idea of valuable options is that they provide more value (used by people, provide safety) than the trouble they're worth (bloated option listings, maintenance cost). Of course this isn't something we can measure, so it's up to the module author to make a reasonable decision, but some general suggestions are given in the next section. As more such options are deemed valuable they can be added to the module over time as well.

### Valuable options

| Kind | Why | Examples | Notes |
| --- | --- | --- | --- |
| Main/popular settings | These options are what you'll need for basic module usage, they provide a good overview and should be enough for most users | [`services.i2pd.address`](https://nixos.org/nixos/manual/options.html#opt-services.i2pd.address), [`services.taskserver.organisations`](https://nixos.org/nixos/manual/options.html#opt-services.taskserver.organisations) but **not** [~~`services.i2pd.logCLFTime`~~](https://nixos.org/nixos/manual/options.html#opt-services.i2pd.logCLFTime) and **not** [~~`services.taskserver.extensions`~~](https://nixos.org/nixos/manual/options.html#opt-services.taskserver.extensions) | Settings only needed by few can be set through the `settings` option instead |
| Mandatory user-specific values | Reminds the user that they have to set this in order for the program to work, an evaluation error will catch a missing value early | [`services.hydra.hydraURL`](https://nixos.org/nixos/manual/options.html#opt-services.hydra.hydraURL), [`services.davmail.url`](https://nixos.org/nixos/manual/options.html#opt-services.davmail.url) | |
| Sensitive data, passwords | To avoid those ending in the Nix store, ideally an option like `passwordFile` should replace a password placeholder in the configuration file at runtime | | This is specifically about configuration files that have a `password`-like setting |

## Backwards compatibility with existing modules

This RFC has to be thought of as a basis for *new* modules first and foremost. By using this approach we can provide a good basis for new modules, with great flexibility for future changes.

For existing modules, it is often not possible to use this `settings` style without breaking backwards compatibility. How this is handled is left up to the module authors. A workaround that could be employed is to define options `useLegacyConfig` or `declarative` which determin  the modules behavior in regards to old options.

# Drawbacks
[drawbacks]: #drawbacks

For [Part 2][part2]:
- The less encoded options there are, the less checks are happening at evaluation time, and by default this means more runtime failures for initial runs, which isn't as bad as it sounds. If available, configuration checking tools can be used to have build-time failures instead, or alternatively assertions can be used to have additional evaluation-time checks.
- Only options that are specified will appear in the central NixOS option listings. This means with fewer options there are, the more often upstream documentation is needed. Since the NixOS documentation might be very outdated and incomplete however, this can often be a good thing.

# Alternatives
[alternatives]: #alternatives

The trivial alternative of not doing that, see [Motivation](#motivation)

# Unresolved questions
[unresolved]: #unresolved-questions

# Future work
[future]: #future-work

## Documentation defaults
When defaults for NixOS options are set *outside* the options definition such as `config.services.foo.settings.log_level = lib.mkDefault "WARN"` above, these values don't show up in the documentation as the options defaults. Using the options `default` value would show up in the manual, but unfortunately that doesn't do merging correctly with `settings` options since the value is set with `mkOptionDefault`. To fix this, an option attribute like `recursiveDefault` could be implemented, which recursively sets `mkOptionDefault` on its value instead.

# Addendums

## Command line interfaces
Sometimes programs use command arguments for configuration. Since [PR 75539](https://github.com/NixOS/nixpkgs/pull/75539) there is `lib.encodeGNUCommandLine` to convert a Nix value to an argument string. With compatible programs this brings all the above-mentioned benefits to those programs as well.

## Modules that use the `settings` style

This idea has been implemented already in some places:
- [nixos/znc](https://github.com/NixOS/nixpkgs/tree/master/nixos/modules/services/networking/znc)
- [nixos/davmail](https://github.com/nixos/nixpkgs/blob/master/nixos/modules/services/mail/davmail.nix)
- [My Murmur module](https://github.com/Infinisil/system/blob/45c3ea36651a2f4328c8a7474148f1c5ecb18e0a/config/new-modules/murmur.nix)
- [nixos/bitwarden\_rs](https://github.com/nixos/nixpkgs/blob/master/nixos/modules/services/security/bitwarden_rs/default.nix)
- [nixos/hercules-ci-agent](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/continuous-integration/hercules-ci-agent/common.nix)
- [nixos/blackfire](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/development/blackfire.nix)
- [nixos/biboumi](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/networking/biboumi.nix)
- [nixos/mackerel-agent](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/monitoring/mackerel-agent.nix)
- [nixos/epgstation](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/video/epgstation/default.nix)
- [nixos/klipper](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/misc/klipper.nix)
- [nixos/redmine](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/misc/redmine.nix)
- [nixos/nfs](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/tasks/filesystems/nfs.nix)

## Previous discussions

- https://github.com/NixOS/nixpkgs/pull/44923#issuecomment-412393196
- https://github.com/NixOS/nixpkgs/pull/55957#issuecomment-464561483 -> https://github.com/NixOS/nixpkgs/pull/57716
