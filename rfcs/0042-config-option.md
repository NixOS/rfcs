---
feature: config-option
start-date: 2019-03-10
author: Silvan Mosberger
co-authors: (find a buddy later to help our with the RFC)
related-issues: (will contain links to implementation PRs)
---

Contents:
- Mention part 1 (not using stringly typed extraConfig), mention the problems with stringly typed options
- Mention part 2 (encouraging most important options, high-quality, more advanced users can use config, options can't be removed, etc.). Mention the problems with many options. Show examples of maintenance PR's that were needed because of this, e.g. i2pc, prometheus
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

## Part 1: Structural `settings` instead of stringly `extraConfig`
[part1]: #part-1-structural-settings-instead-of-stringly-extraconfig

NixOS modules often use stringly-typed options like `extraConfig` to allow specifying extra settings in addition to the default ones. This has multiple disadvantages: The defaults can't be changed, multiple values might not get merged properly, inspection of it is almost impossible because it's an opaque string and more. The first part of this RFC aims to solve such problems by discouraging such options and instead to use a `settings` option which encodes the modules configuration file as a structural generic Nix value. Here is an example showcasing some advantages:

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
  };
  
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

Stringly-typed options such as `extraConfig` have multiple disadvantages:
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
- Maintenance is hard to keep up with because upstream can add/remove/change settings over time
  - If the module copied defaults from upstream, these might need to be updated. This is especially important for security. A workaround is using `types.nullOr` with `null` signifying that the upstream default should be used, but that's not very nice.
  - Documentation will get out of date as the package updates
  - If upstream removes a setting, the NixOS module is broken for every user until somebody fixes it with a PR.
- With overlays or `disabledModules`, the user can bring the NixOS module out of sync with the package in nixpkgs, which can lead to the same problems as in the previous point.
- Responsibility for backwards compatibility is now not only in upstream, but also on our side.

## Occurences of problems

- Because prometheus uses options to encode every possible setting, PR's like [#56017](https://github.com/NixOS/nixpkgs/pull/56017) are needed to allow users to set a part of the configuration that wasn't encoded yet.
- Because strongswan-ctl uses options to encode its full configuration, changes like [#49197](https://github.com/NixOS/nixpkgs/pull/49197) are needed to update our options with upstream changes.
- Pull requests like [#57036](https://github.com/NixOS/nixpkgs/pull/57036) or [#38324](https://github.com/NixOS/nixpkgs/pull/38324) are needed because users wish to have more configuration options than the ones provided.
- [#58239](https://github.com/NixOS/nixpkgs/pull/58239), [#58181](https://github.com/NixOS/nixpkgs/pull/58181)

## Previous discussions

- https://github.com/NixOS/nixpkgs/pull/44923#issuecomment-412393196
- https://github.com/NixOS/nixpkgs/pull/55957#issuecomment-464561483 -> https://github.com/NixOS/nixpkgs/pull/57716

## Previous implementations

This idea has been implemented already in some places:
- [#45470](https://github.com/NixOS/nixpkgs/pull/45470)
- [#52096](https://github.com/NixOS/nixpkgs/pull/52096)
- [My Murmur module](https://github.com/Infinisil/system/blob/45c3ea36651a2f4328c8a7474148f1c5ecb18e0a/config/new-modules/murmur.nix)
- [#55413](https://github.com/NixOS/nixpkgs/pull/55413)

# Detailed design
[design]: #detailed-design

For specifying configuration files to programs in NixOS options, there should be a main option called `config` (TODO: or `settings`, name to be decided), which represents the configuration of the program as a Nix value, which can then be converted to the configuration file format the program expects. In order for the most prominent/popular/main options of the package to be easily discoverage, they should still be specified as separate NixOS options, see the [additional config option](#additional-config-options) section for more details.

As a result, modules will look as follows:

```nix
{ config, lib, ... }: with lib;
let

  cfg = config.services.foo;

  configText = configGen.json cfg.config;

in {

  options.services.foo = {
    enable = mkEnableOption "foo service";

    config = mkOption {
      type = types.config.json;
      default = {};
      description = ''
        Configuration for foo. Refer to <link xlink:href="https://example.com/docs/foo"/>
        for documentation on the supported values.
      '';
    };

    # Because this option is a main/popular one we provide a separate
    # option for it, to improved discoverability and error checking
    domain = mkOption {
      type = types.str;
      description = ''
        Domain this service operates on.
      '';
    };
  };
  
  config = mkIf cfg.enable {
  
    # Set minimal config to get service working by default
    services.foo.config = {
      # We don't use mkDefault here, as this module requires this value in order to function
      data_path = "/var/lib/foo";

      log_level = mkDefault "WARN";

      # Upstream default, needed for us to open the firewall
      port = mkDefault 2546;

      domain = cfg.domain;
    };
  
    environment.etc."foo.json".text = configText;
    
    networking.firewall.allowedTCPPorts = [ cfg.config.port ];
    # ...
  };
}
```

This approach solves all of the above mentioned problems for the settings we don't refer to in the module, the defaults we specify however are unavoidably still tied to upstream. In addition we have the following properties that work with this approach out of the box:
- Ability to easily query arbitrary configuration values with `nix-instantiate --eval '<nixpkgs/nixos>' -A config.services.foo.config` (TODO: does `nixos-option services.foo.config` work too?)
- The configuration file can be well formatted with the right amount of indentation everywhere
- Usually hardcoded defaults can now be replaced by simple assignment of the `config` option, which in addition allows people to override those values. See the [Defaults](#defaults) section for more details.

## Defaults

Depending on how default settings matter, we need to set them differently and for different reasons:
- If the module needs a specific value for a setting because of how the module or NixOS works (e.g. `logger = "systemd"`, because NixOS uses `systemd` for logging), then the value should *not* use `mkDefault`. This way a user can't easily override this setting (which would break the module in some way) and will have to use `mkForce` instead to change it. This also indicates that they are leaving supported territory, and will probably have to change something else to make it work again (e.g. if they set `logger = mkForce "/var/log/foo"` they'll have to change their workflow of where to look for logs).
- If the program needs a setting to be present in the configuration file because otherwise it would fail at runtime and demand a value, the module should set this value *with* a `mkDefault` to the default upstream value, which will then be the equivalent of a starter configuration file. This allows users to easily change the value, but also enables a smooth first use of the module without having to manually set such defaults to get it to a working state. Optimally modules should Just Work (tm) by setting their `enable` option to true.
- If the module itself needs to know the value of a configuration setting at evaluation time in order to influence other options (e.g. opening the firewall for a services port), we may set upstream's default with a `mkDefault`, even though the program might start just fine without it. This allows the module to use the configuration setting directly without having to worry whether it is set at all at evaluation time.

If the above points don't apply to a configuration setting, that is the module doesn't care about the value, the program doesn't care about the setting being present and we don't need the value at evaluation time, there should be no need to specify any default value.

## Additional config options

For multiple reasons, one may wish to still have additional options available for configuration settings:
- Popular or main settings. Because such `config` options will have to refer to upstream documentation for all available settings, it's much harder for new module users to figure out how they can configure it. Having popular/main settings as NixOS options is a good compromise. It is up to the module author to decide which options qualify for this.
- Settings that are necessary for the module to work and are different for every user, so they can't have a default. Examples are `services.dd-agent.api_key`, `services.davmail.url` or `services.hydra.hydraURL`. Having a separate option for these settings can give a much better error message when you don't set them (instead of failing at runtime or having to encode the requirement in an assertion) and better discoverability.
- Password settings: Some program's configuration files require passwords in them directly. Since we try to avoid having passwords in the Nix store, it is advisable to provide a `passwordFile` option as well, which would replace a placeholder password in the configuration file at runtime.

Keep in mind that while it's trivial to add new options with the approach in this RFC, removing them again is hard (even without this RFC). So instead of introducing a lot of additional options when the module gets written, authors should try to keep the initial number low, to not introduce options almost nobody will end up using. Every additional option might be nice to use, but increases coupling to upstream, burden on nixpkgs maintainers and bug potential. Thus we should strive towards a balance between too little and too many options, between "I have no idea how to use this module because it provides too little options" and "This module has become too problematic due to its size". And because this balance can only be approached from below (we can only add options, not remove them), additional options should be used conservatively from the start.

This `config` approach described here is very flexible for these kind of additions. As already showcased in the above example, an implementation of such an option looks like this:
```nix
{ config, lib, ... }: with lib; {

  options.services.foo = {
    # ...
    
    domain = mkOption {
      type = types.str;
      description = "Domain this service operates on.";
    };
  };
  
  config = mkIf cfg.enable {
    services.foo.config = {
      # ...
      domain = mkDefault cfg.domain;
    };
  };
}
```

Even though we have two ways of specifying this configuration setting now, the user is free to choose either way.

## Configuration checking

One general downside of this approach is that the module system is not able to check the types and values of the configuration file, which could be fast, simple and give good error messages by default. While it would be possible to use `types.addCheck` for the type of the `config` option, this sounds more painful than it's worth and would lead to bad error messages, so we'll ignore this here. Here are some alternatives.

### Configuration checking tools

Occasionally programs have tools for checking their configuration without the need to start the program itself. We can use this to verify the configuration at **build time** by running the tool for a derivation build. While this is not as fast as if we had the module system do these checks, which would be at evaluation time already, it is better than the program failing at runtime due to misconfiguration. These tools however are also more powerful than the module system and can integrate tightly with the program itself, allowing for more thorough checks. In addition, it reduces the amount of RAM needed for evaluation. If a configuration checking tool is available, optimally by the program itself, it should be used if possible, as it can greatly improve user experience. The following illustrates an example of how this might look like

```nix
{ config, pkgs, lib, ... }: with lib;

let

  configText = configGen.json cfg.config;

  configFile = pkgs.runCommand "foo-config.json" {
    # Because this program will be run at build time, we need `nativeBuildInputs` instead of `buildInputs`
    nativeBuildInputs = [ pkgs.foo ];

    inherit configText;
    passAsFile = [ "configText" ];
  } ''
    foo check-config $configTextPath
    cp $configTextPath $out
  '';

in { /* ... */ }
```

TODO: Explain how `options.services.foo.config.files` can be used to give a better indication of where a failure occurs.

### Ad-hoc checks with assertions

While not as optimal as a configuration checker tool, assertions can be used to add flexible ad-hoc checks for type or other properties at **evaluation time**. It should only be used to ensure important properties that break the service in ways that are otherwise hard or slow to detect (and easy to detect for the module system), not for things that make the service fail to start anyways (unless there's a good reason for it). The following example only demonstrates how assertions can be used for checks, but any reasonable program should bail out early in such cases, which would make these assertions redundant, and only add more coupling to upstream, which we're trying to avoid.

```nix
{ config, lib, ... }: with lib; {
  # ...
  config = mkIf cfg.enable {
    # Examples only for demonstration purposes, don't actually add assertions for such properties
    assertions = [
      {
        assertion = cfg.config.enableLogging or true -> cfg.config ? logLevel;
        message = "You also need to set `services.foo.config.logLevel` if `services.foo.config.enableLogging` is turned on.";
      }
      {
        assertion = cfg.config ? port -> types.port.check cfg.config.port;
        message = "${toString cfg.config.port} is not a valid port number for `services.foo.config.port`.";
      }
    ];
  };
}
```

TODO: Are there any good examples of using assertions for configuration checks at all?

## Backwards compatibility for configuration settings

By having a single option instead of many, we by default keep responsibility for backwards compatibility in upstream. This however also means that if upstream breaks backwards compatibility, instead of the NixOS module fixing it up, the user would have to do it themselves by adjusting their NixOS configuration. However, because such `config` options allow deep introspection into their values, it is possible to provide backwards compatibility in the module itself. This is possible by not using `config` directly to write the configuration file, but instead transforming it first, adjusting everything that's needed. For a simple `key = value` type configuration format, this could look as follows (TODO: Verify that this code works):

```nix
{ config, lib, ... }: with lib;
let
  cfg = config.services.foo;

  fixedUpConfig = let
    renamedKeys = {
      # foo has been renamed to bar
      foo = "bar";
    };
    in
      # Remove all renamed keys
      removeAttrs cfg.config (attrNames renamedKeys) //
      # Readd all renamed keys with their new name
      mapAttrs' (name: value:
        nameValuePair value cfg.config.${name}
      ) (intersectAttrs cfg.config renamedKeys);
in
  # ...
```

If this is needed in the future, we may add a set of config deprecation fix-up functions for general use in modules.

## Implementation parts

The implementation consists of three separate parts.

### Configuration types

A set of types for common configuration formats should be provided in `lib.types.config`. Such a type should encode what values can be set in files of this configuration format as a Nix value, with the module system being able to merge multiple values correctly. This is the part that checks whether the user set an encodeable value. This can be extended over time, but could include the following as a start:
- JSON
- YAML, which is probably the same as JSON
- INI
- A simple `key=value` format
- A recursive `key.subkey.subsubkey=value` format

Sometimes programs have their own configuration formats, in which case the type should be implemented in the program's module directly.

### Configuration format writers

To convert the Nix value into the configuration string, a set of configuration format writers should be provided under `lib.configGen`. These should make sure that the resulting text is somewhat properly formatted with readable indentation. Things like `builtins.toJSON` are therefore not optimal as it doesn't add any spacing for readability. These writers will have to include ones for all of the above-mentioned configuration types. As with the type, if the program has its own configuration format, the writer should be implemented in its module directly.

### Documentation

The nixpkgs manual should be updated to recommend this way of doing program configuration in modules, along with examples.

## Limitations

### Nix-representable configuration formats

Limited to configuration file formats representable conveniently in Nix, such as JSON, YAML, INI, key-value files, or similar formats. Examples of unsuitable configuration formats are Haskell, Lisp, Lua or other generic programming languages. If you need to ask yourself "Does it make sense to use Nix for this configuration format", then the answer is probably No, and you should not use this approach.

For unsuitable formats it is left up to the module author to decide the best set of NixOS options. Sometimes it might make sense to have both a specialized set of options for single settings (e.g. `programs.bash.environment`) and a flexible option of type `types.lines` (such as `programs.bash.promptInit`). Alternatively it might be reasonable to only provide a `config`/`configFile` option of type `types.str`/`types.path`, such as for XMonad's Haskell configuration file. And for programs that use a general purpose language even though their configuration can be represented in key-value style (such as [Roundcube's PHP configuration](https://github.com/NixOS/nixpkgs/blob/e03966a60f517700f5fee5182a5a798f8d0709df/nixos/modules/services/mail/roundcube.nix#L86-L93) of the form `$config['key'] = 'value';`), a `config` option as described in this RFC could be used as well as a `configFile` option for more flexibility if needed.

### Backwards compatibility with existing modules

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


# Arguments for Part 2

- We currently have a lot of NixOS modules with a lot of options. We can't really get rid of them to simplify the module. Removing/deprecating options would annoy users and give the feeling off that functionality is reduced.
- In comparison if the module is small to start with, we can easily add more options as needed. This gives off the idea that new functionality is added.




- Typed config instead of stringly-typed

# The option count scale

- config option only: Very simple module, easy to maintain, but very little documentation in the NixOS manual, almost everything is a runtime error
- Every program setting as an option: Very big module, hard to maintain, but everything is neatly documented and eval errors for a lot of things

Somewhere in-between is the sweet spot, where the module has the necessary options to be useful for most people, but where it's still reviewable and maintainable.

This sweet-spot is only approachable from below, because once you add an option, you can't really remove it without users being annoyed that it broke their setup or people feeling they get robbed of functionality.



