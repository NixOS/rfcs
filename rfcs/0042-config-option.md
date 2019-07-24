---
feature: config-option
start-date: 2019-03-10
author: Silvan Mosberger
co-authors: (find a buddy later to help our with the RFC)
related-issues: (will contain links to implementation PRs)
---

Contents:
- Implementation
  - Part 1: Adding formatters, types (mention how types.attrs doesn't work correctly) and docs
    - Defaults
  - Part 2: Adding docs for encouraging most important options
- Limitations
- Future work
  - showing defaults in the manual
  - Command line options
- Addendums
  - Configuration checking
  - Backwards compatibility
  - configFile

# Summary
[summary]: #summary

The RFC consists of two parts which flow hand-in-hand

## Part 1: Structural `settings` instead of stringly `extraConfig`
[part1]: #part-1-structural-settings-instead-of-stringly-extraconfig

NixOS modules often use stringly-typed options like `extraConfig` to allow specifying extra settings in addition to the default ones. This has multiple disadvantages: The defaults can't be changed, multiple values might not get merged properly, inspection of it is almost impossible because it's an opaque string and more. The first part of this RFC aims to discourage such options and proposes generic `settings` options instead, which can encode the modules configuration file as a structural Nix value. Here is an example showcasing some advantages:

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

## Part 2: Balancing module option count
[part2]: #part-2-balancing-module-option-count

Since with this approach there will be no more hardcoded defaults and composability is not a problem anymore, there is not a big need to have NixOS options for every setting anymore. Traditionally this has lead to huge NixOS modules with dozens of options, each of them only for a single field in the configuration. Such modules are problematic because they're hard to review and maintain, require constant care as to keep all those options in line with upstream changes, are generally of lower quality and more. Such options aren't without advantages however: They will be presented in the NixOS manual and can have better type checking than the equivalent with `settings`.

The second part of this RFC aims to encourage module authors to strike a balance for the number of such additional options such as to not make the module too big, but still provide the most commonly used settings as separate NixOS options. Quality is encouraged over quantity: Authors should spend more time on thinking about which options to add, documenting them properly, thinking about interactions with the rest of NixOS, or even writing useful high-level options instead. This is in contrast to the fiddly labor of copying dozens of options from upstream to NixOS. With a `settings` option, it's also always easy to add more options over time in a backwards-compatible way, whereas removing options has always been practically impossible.

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

These are only examples of where people *found* problems and fixed them. The number of modules that have outdated options and require maintenance is probably rather high.

## Previous discussions

- https://github.com/NixOS/nixpkgs/pull/44923#issuecomment-412393196
- https://github.com/NixOS/nixpkgs/pull/55957#issuecomment-464561483 -> https://github.com/NixOS/nixpkgs/pull/57716

# Detailed design
[design]: #detailed-design

## [Part 1][part1]

### Additions to the NixOS documentation

#### Writing options for program configuration

TODO: Write this section, followed by another section on `configFile`

Whether having a structural `settings` option for a module makes sense depends on whether the program's configuration format has a direct mapping from Nix. This includes formats like JSON, YAML, INI and similar. Examples of unsuitable configuration formats are Haskell, Lisp, Lua or other generic programming languages. If you need to ask yourself "Does it make sense to use Nix for this configuration format", then the answer is probably No, and you should not use this approach. This RFC does not specify anything for unsuitable configuration formats, but there is [an addendum on that][unsuitable].

#### Default values

Ideally modules should work by just setting `enable = true`. Often this requires the configuration to include some default settings. Defaults should get specified in the `config` section of the module by assigning the values to the `settings` option directly. Depending on how default settings matter, we need to set them differently and for different reasons:
- If the program needs a setting to be present in the configuration file because otherwise it would fail at runtime and demand a value, the module should set this value with a `mkDefault` to the default upstream value, which will then be the equivalent of a starter configuration file. This allows users to easily change the value, but also enables a smooth first use of the module without having to manually set such defaults to get it to a working state. Note that this doesn't necessarily require the module to be updated when upstream defaults change, because that's the expected behavior with starter configurations.
- If the module needs a specific value for a setting because of how the module or NixOS works (e.g. `logger = "systemd"`, because NixOS uses `systemd` for logging), then the value should *not* use `mkDefault`. This way a user can't easily override this setting (which would break the module in some way) and will have to use `mkForce` instead to change it. This also indicates that they are leaving supported territory, and will probably have to change something else to make it work again (e.g. if they set `logger = mkForce "/var/log/foo"` they'll have to change their workflow of where to look for logs).
- If the module itself needs to know the value of a configuration setting at evaluation time in order to influence other options (e.g. opening the firewall for a services port), we may set upstream's default with a `mkDefault`, even though the program might start just fine without it. This allows the module to use the configuration setting directly without having to worry whether it is set at all at evaluation time.

If the above points don't apply to a configuration setting, that is the module doesn't care about the value, the program doesn't care about the setting being present and we don't need the value at evaluation time, there should be no need to specify any default value.

TODO: Nice table for default kind / how to set it / whether it needs to track upstream / examples

#### Additional options for single settings

One can easily add additional options that correspond to single configuration settings. This is done by defining an option as usual, then applying it to `settings` with a `mkDefault`. This approach allows users to set the value either through the specialized option, or `settings`, which also means that new options can be added without any worry for backwards incompatibility.

#### An example

Putting it all together, here is an example of a NixOS module that uses such an approach:

```nix
{ config, lib, ... }:
let cfg = config.services.foo;
in {

  options.services.foo = {
    enable = lib.mkEnableOption "foo service";

    settings = lib.mkOption {
      type = lib.types.settings.json;
      default = {};
      description = ''
        Configuration for foo, see <link xlink:href="https://example.com/docs/foo"/>
      '';
    };

    # An additional option for a setting so we have an eval error if this is missing
    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain this service operates on.";
    };
  };
  
  config = lib.mkIf cfg.enable {
    services.foo.settings = {
      # Fails at runtime without any value set
      log_level = lib.mkDefault "WARN";
    
      # We use systemd's `StateDirectory`, so we require this (no mkDefault)
      data_path = "/var/lib/foo";
      
      # We use this to open the firewall, so we need to know about the default at eval time
      port = lib.mkDefault 2546;
      
      # Apply our specialized setting.
      domain = lib.mkDefault cfg.domain;
    };
  
    environment.etc."foo/config.json".text = lib.settings.genJSON cfg.settings;
    
    networking.firewall.allowedTCPPorts = [ cfg.settings.port ];
    # ...
  };
}
```

### Configuration format types

In order for a structural `settings` to enforce a valid value and work correctly with merging and priorities, it needs to have a type that corresponds to its configuration format, `types.attrs` won't do. As an example, the INI type could be represented with `attrsOf (attrsOf (nullOr (either int str)))`, which means there's multiple named sections, each of which can contain a key-value pair where the value is either `null`, an integer or a string, where `null` signifies a key not being present (which is useful for unsetting existing values).

Common format types will be provided under `lib.types.settings`. This could include JSON, YAML, INI, a simple `key=value` format and a recursive `key.subkey.subsubkey=value` format for a start. Sometimes programs have their own configuration formats which are specific to them, in which case the type should be specified in that programs module directly instead of going in `lib.types.settings`.

### Configuration format writers

In order for the final value of `settings` to be turned into a string, a set of configuration format writers should be provided under `lib.settings`. These should ideally make sure that the resulting text is somewhat properly formatted with readable indentation. Things like `builtins.toJSON` are therefore not optimal as it doesn't add any spacing for readability. These writers will have to include ones for all of the above-mentioned configuration types. As with the type, if the program has its own configuration format, the writer should be implemented in its module directly.

## [Part 2][part2]

TODO: write what goes in the NixOS docs

The second part of this RFC aims to encourage people to write better NixOS modules in terms of quality, maintainability and discoverability by limiting NixOS options representing single settings to a set of most "valuable" options. Of course in general "valuable" doesn't have a clear definition, so it's up to the module author and other people familiar with the program to decide on it, but in the following section some conventions will be given. As more such options are deemed "valuable" they can be added to the module over time.

### Valuable options

TODO: Add table

- Popular or main settings. Because such `settings` options will have to refer to upstream documentation for all available settings, it's much harder for new module users to figure out how they can configure it. Having popular/main settings as NixOS options is therefore a good idea
- Settings that are necessary for the module to work and are different for every user, so they can't have a default. Examples are `services.dd-agent.api_key`, `services.davmail.url` or `services.hydra.hydraURL`. Having a separate option for these settings can give a much better error message when you don't set them (instead of failing at runtime or having to encode the requirement in an assertion) and better discoverability.
- Password settings: Some program's configuration files require passwords in them directly. Since we try to avoid having passwords in the Nix store, it is advisable to provide a `passwordFile` option as well, which would replace a placeholder password in the configuration file at runtime.

### Configuration checking

One downside of using `settings` instead of having a dedicated NixOS option is that values can't be checked to have the correct key and type at evaluation time. Instead the default mode of operation will be to fail at runtime when the program reads the configuration. There are ways this can be improved however.

#### Configuration checking tools

Occasionally programs have tools for checking their configuration without the need to start the program itself. We can use this to verify the configuration at build time by running the tool during a derivation build. These tools are generally more thorough than the module system and can integrate tightly with the program itself, which can greatly improve user experience. A good side effect of this approach is that less RAM is needed for evaluation. The following illustrates an example of how this might look like:

TODO: Rewrite in terms of `configFile`
```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.services.foo;
  
  checkedConfig = pkgs.runCommandNoCC "foo-config.json" {
    # Because this program will be run at build time, we need `nativeBuildInputs`
    nativeBuildInputs = [ pkgs.foo-checker ];
    
    config = lib.settings.genJSON cfg.settings;
    passAsFile = [ "config" ];
  } ''
    foo-checker "$configPath"
    cp "$configPath" "$out"
  '';

in {
  options = { /* ... */ };
  config = lib.mkIf cfg.enable {
  
    environment.etc."foo/config.json".source = checkedConfig;
    
    # ...
  };
}
```

TODO: Explain how `options.services.foo.config.files` can be used to give a better indication of where a failure occurs.

### Ad-hoc checks with assertions

While not as good as a configuration checker tool, assertions can be used to add flexible ad-hoc checks for type or other properties at evaluation time. It should only be used to ensure important properties that break the service in ways that are otherwise hard or slow to detect (and easy to detect for the module system), not for things that make the service fail to start anyways (unless there's a good reason for it). The following example only demonstrates how assertions can be used for checks, but any reasonable program should bail out early in such cases, which would make these assertions redundant, and only add more coupling to upstream, which we're trying to avoid in the first place.

```nix
{ config, lib, ... }: {
  # ...
  config = lib.mkIf cfg.enable {
    # Examples only for demonstration purposes, don't actually add assertions for such properties
    assertions = [
      {
        assertion = cfg.settings.enableLogging or true -> cfg.settings ? logLevel;
        message = "You also need to set `services.foo.settings.logLevel` if `services.foo.settings.enableLogging` is turned on.";
      }
      {
        assertion = cfg.settings ? port -> lib.types.port.check cfg.settings.port;
        message = "${toString cfg.settings.port} is not a valid port number for `services.foo.settings.port`.";
      }
    ];
  };
}
```

TODO: Are there any good examples of using assertions for configuration checks at all?

### Backwards compatibility for configuration settings

By shifting values from a specific NixOS option to the general `settings` one, guarding against upstream changes will have to be done differently. Due to the structural nature of `settings` options, it's possible to deeply inspect and rewrite them however needed before converting them to a string. If the need arises, convenience library functions can be written for such transformations. This might look as follows:

```nix
{ config, lib, ... }:
let
  cfg = config.services.foo;
  
  fixedUpSettings =
    let
      renamedKeys = builtins.intersectAttrs cfg.settings {
        # foo has been renamed to bar
        foo = "bar";
      };
      conflicts = lib.filter (from: cfg.settings ? ${renamedKeys.${from}}) (lib.attrNames renamedKeys);
    in if conflicts == [] then lib.mapAttrs' (from: to:
      lib.nameValuePair to cfg.settings.${from}
    ) renamedKeys // builtins.removeAttrs cfg.settings (lib.attrNames renamedKeys)
    else throw (lib.concatMapStringsSep "," (from:
      "Can't mix the deprecated setting \"${from}\" with its replacement \"${renamedKeys.${from}}\""
    ) conflicts);
  
in {
  config.environment.etc."foo/config.json".text = lib.settings.genJSON fixedUpsettings;
}
```

## Backwards compatibility with existing modules

This RFC has to be thought of as a basis for *new* modules first and foremost. By using this approach we can provide a good basis for a new module, with great flexibility for future changes.

A lot of already existing NixOS modules provide a mix of options for single settings and `extraConfig`-style options, which as explained in the [Motivation](#motivation) section leads to problems. In general it is not easy or even impossible to convert such a module to the style described in this RFC in a backwards-compatible way without any workarounds. One workaround is to add an option `useLegacyConfig` or `declarative` which determines the modules behavior in regards to old options.


# Drawbacks
[drawbacks]: #drawbacks

There are some disadvantages to this approach:
- If there is no configuration checking tool as explained in [this section](#configuration-checking-tools), the types of configuration settings can't be checked as easily, which can lead to packages failing at runtime instead of evaluation time. Refer to [Configuration checking](#configuration-checking) for more info.
- Documentation for the configuration settings will not be available in the central NixOS manual, instead the upstream documentation has to be used, which can be unfamiliar and harder to read. As a compromise, [additional NixOS options](#additional-config-options) can be used to bring part of the settings back into the NixOS documentation.

# Alternatives
[alternatives]: #alternatives

See [Motivation](#motivation)

# Unresolved questions
[unresolved]: #unresolved-questions

Ctrl-F for TODO

# Future work
[future]: #future-work

- When defaults for NixOS options are set *outside* the options definition such as `config.services.foo.config.logLevel = "DEBUG"` above, it's currently not possible to see these default values in the manual. This could be improved by having the manual not only look at the option definitions `default` attribute for determining the default, but also evaluate the options value with a minimal configuration to get the actual default value. This might be non-trivial.
- If needed, add config transformation functions for keeping backwards compatibility with upstream changes. See [Backwards compatibility for configuration settings](#backwards-compatibility-for-configuration-settings)

# Addendums

## Unsuitable configuration formats
[unsuitable]: #unsuitable-configuration-formats

For unsuitable formats it is left up to the module author to decide the best set of NixOS options. Sometimes it might make sense to have both a specialized set of options for single settings (e.g. `programs.bash.environment`) and a flexible option of type `types.lines` (such as `programs.bash.promptInit`). Alternatively it might be reasonable to only provide a `config`/`configFile` option of type `types.str`/`types.path`, such as for XMonad's Haskell configuration file. And for programs that use a general purpose language even though their configuration can be represented in key-value style (such as [Roundcube's PHP configuration](https://github.com/NixOS/nixpkgs/blob/e03966a60f517700f5fee5182a5a798f8d0709df/nixos/modules/services/mail/roundcube.nix#L86-L93) of the form `$config['key'] = 'value';`), a `config` option as described in this RFC could be used as well as a `configFile` option for more flexibility if needed.

## Previous implementations

This idea has been implemented already in some places:
- [#45470](https://github.com/NixOS/nixpkgs/pull/45470)
- [#52096](https://github.com/NixOS/nixpkgs/pull/52096)
- [My Murmur module](https://github.com/Infinisil/system/blob/45c3ea36651a2f4328c8a7474148f1c5ecb18e0a/config/new-modules/murmur.nix)
- [#55413](https://github.com/NixOS/nixpkgs/pull/55413)
