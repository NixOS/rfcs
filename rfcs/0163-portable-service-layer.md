---
feature: portable_service_layer
start-date: 2023-09-10
author: Sander van der Burg
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

This proposal introduces a generic, portable, high-level process management
framework that makes it possible to manage a variety of commonly used
application services on preferably all operating systems/environments that the
Nix package manager supports.

# Motivation
[motivation]: #motivation

The Nix package manager is a deployment solution that offers many powerful
features. For example, it is a very convenient solution to deploy
*multiple versions* and *variants* of packages in isolation so that they do not
conflict with each other and packages of an existing system installation.

The `nix-shell` command is particularly useful to safely experiment with
packages -- you can conveniently spawn a shell session in which you can use
different versions of packages than the host system without changing the host
system's package configuration.

For Nix, it is *not* even required to have *super-user privileges* to deploy
packages -- thanks to its isolation properties this can be done without
interfering with the packages of another user or the system-wide set of packages.

Moreover, the Nix package manager is also a *portable* solution. In addition
to Linux, Nix also has first-class support for macOS/Darwin. With some effort,
it can also be used on other UNIX-like operating systems, such as FreeBSD and
Cygwin.

Unfortunately, Nix does not solve all application deployment problems -- Nix's
purpose is to deploy packages (e.g. delivering the required artifacts, such as
executables and configuration files) but not to manage the life-cycle of
applications, such as long running services (the only exception is the `nix run`
command that allows you to conveniently start an executable).

For these kinds of applications, Nix is typically combined with a *process
manager*, such as `systemd`, that is responsible for managing the life-cycle of
a service. Configuration files for these process managers are also deployed as
Nix packages.

There are a variety of Nix-based solutions that combine Nix with a process
management solution (see: [prior art](#prior-art)). These solutions are quite
useful, but have a number of drawbacks. The most notable drawback is that there
is almost no reuse between the configurations of the services that are managed by
these solutions. In practice, I have noticed that quite a few properties remain
the same in spite of the process management solution that was selected.

Moreover, there are also a number of interesting Nix properties for which we also
want to provide a process-management equivalent:

* Nix makes it possible to have *multiple versions* and variants of the same
  package to safely co-exist on the same system. We also want to bring this
  property to process management -- this becomes possible if we make sure that
  multiple instances do not share the same state (e.g. state directories, port
  numbers, UIDs, GIDs).
* Nix supports *unprivileged* user package installations. It is also possible for
  many kinds services to run as an unprivileged user as long as we make sure
  that they use state directories have write permissions (e.g. using a state
  directory in the user's home directory) and that these services use TCP/UDP
  port numbers that are greater than 1024

The ideas described in this RFC have been explored in the experimental
[Nix process management framework](https://github.com/svanderburg/nix-processmgmt).
There is also an
[example services repository](https://github.com/svanderburg/nix-processmgmt-services)
repository that demonstrates how it can be used with a number of commonly used
services.

# Detailed design
[design]: #detailed-design

This RFC proposes a number of feature additions to the Nixpkgs ecosystem. These
features correspond to the concepts implemented in the experimental Nix process
management framework.

There are variety of ways to implement these concepts. Moreover, the idea is that
these concepts can be implemented one-by-one and in an iterative fashion.

The following sections explain its concepts one by one and provide possible
implementation strategies.

## A service layer that can be used independently of NixOS

Currently, the Nixpkgs repository only contains systemd service configurations.
These systemd configurations cannot be used separately from NixOS (as a
sidenote: there is project called
[system-manager](https://github.com/numtide/system-manager)
that makes it possible to only generate systemd units that can be used outside
NixOS, but it can only be used on Ubuntu and is still under heavy development).

Another project that makes services management available in combination with
Nix is [nix-darwin](https://github.com/LnL7/nix-darwin). This project uses
launchd (on macOS) in combination with Nix to support process management.

To make service deployment accessible to a broader audience, it would be nice to
create a separation in the Nixpkgs tree for portable systemd services (e.g. a
`services/` directory in the root folder) and to develop a derivation and
command-line tool (e.g. `nix-services-rebuild`) that allows you to deploy (at
least a reasonable sub set) of systemd units separately on a conventional Linux
distribution.

Low-level system services, such as `cups`) do not need to be separated from
NixOS, but high-level services should, such as `Apache`, `Nginx`, `MariaDB`,
`PostgreSQL` etc.

NixOS will be a consumer of this separated service layer.

## Generator functions for other kinds of process managers

With a separated services tree and command-line tool to manage instances of
services, it should also become more convenient to target different kinds of
process managers.

The purpose of this RFC is not to have a debate about systemd's usefulness.
systemd has IMO many good features, and I believe it should remain the default
option in NixOS.

However, there are also good reasons to sometimes consider a different process
manager:

* systemd is a Linux-specific tool. If we want to deploy a service on another
  operating system, we need to pick a different solution that is compatible with
  that operating system.
* systemd is glibc-specific. Sometimes, it may also be desired to manage
  services on a Linux system that uses a different libc, such as musl. Then
  you need a process manager that is compatible with that different flavour of
  libc.
* We may want to deploy services on older Linux distros or distros with LTS
  support. These distros may still work with sysvinit scripts (also known as
  [LSB Init compliant scripts](https://wiki.debian.org/LSBInitScripts)).
* Sometimes we may want to experiment with services as an unprivileged user
  that does not have the ability to control systemd. Then it can be very
  convenient to use a process manager that can be used as an unprivileged user,
  such as `supervisord`.
* Although it is possible to run systemd in a Docker container to manage
  multiple processes, it is typically more preferable to use a more Docker
  friendly alternative

With a separated service layer in Nixpkgs, it should also become more convenient
to use a different generator module for a different kind of process manager.

Similar to the systemd generator module, we can provide NixOS generator modules
for other process managers as well, that provide a one-on-one translation
between properties in the Nix expression language and generated config file
properties.

For example, we can also develop an abstraction that generates `sysvinit` scripts
(also known as LSB Init compliant scripts). The nix-processmgmt framework allows
you to generate a `sysvinit` script as follows:

```nix
{createSystemVInitScript, nginx}:

let
  configFile = ./nginx.conf;
  stateDir = "/var";
in
createSystemVInitScript {
  name = "nginx";
  description = "Nginx";
  activities = {
    start = ''
      mkdir -p ${stateDir}/logs
      log_info_msg "Starting Nginx..."
      loadproc ${nginx}/bin/nginx -c ${configFile} -p ${stateDir}
      evaluate_retval
    '';
    stop = ''
      log_info_msg "Stopping Nginx..."
      killproc ${nginx}/bin/nginx
      evaluate_retval
    '';
    reload = ''
      log_info_msg "Reloading Nginx..."
      killproc ${nginx}/bin/nginx -HUP
      evaluate_retval
    '';
    restart = ''
      $0 stop
      sleep 1
      $0 start
    '';
    status = "statusproc ${nginx}/bin/nginx";
  };
  runlevels = [ 3 4 5 ];
}
```

(As a sidenote: the nix-processmgmt framework uses different conventions than
NixOS, which I will explain later)

The above code example invokes the `createSystemVInitScript` function to generate
a `sysvinit` script to manage Nginx:

* The `name` of the script is: `nginx`
* The `description` in the comment is: Nginx
* The `activities` parameter specifies the implementation of all the activities
  (process lifecycle operations) that the init script exposes (as bash shell
  instructions), such as starting, stopping, restarting and reloading the
  service.

Since the kind of activities that you need to implement are so common, it is
also possible to add a little bit of abstraction on top of the generator
function:

```nix
{createSystemVInitScript, nginx}:

let
  configFile = ./nginx.conf;
  stateDir = "/var";
in
createSystemVInitScript {
  name = "nginx";
  description = "Nginx";
  initialize = ''
    mkdir -p ${stateDir}/logs
  '';
  process = "${nginx}/bin/nginx";
  args = [ "-c" configFile "-p" stateDir ];
  runlevels = [ 3 4 5 ];
}
```

In the above example, we have simplified the previous example -- we no longer
specify the implementation of any of the activities, but we specify which
process we want to be managed and how it can be initialized. From this
high-level specification the activities are automatically derived.

Currently, the Nix process management framework provides generator functions for
the following backends:

* `sysvinit` scripts (also known as LSB Init compliant scripts). Because it is
  standardize by the LSB, widely used and the most primitive, I have decided to
  experiment with this first.
* `systemd` services
* `supervisord` services
* `launchd` services
* `bsdrc` scripts
* `s6-rc` services
* Windows services (deployed by calling: `cygrunsrv`)

In addition to the above process managers, it also possible to directly generate
Docker containers for each process instance. Although the framework was not
originally designed for this purpose, I have noticed that the abstractions are
generic enough to make such deployments possible.

In NixOS, for each backend, we can add a generator module. Currently, a NixOS
module for systemd already exists, but we can also add generator modules for
different kinds of process managers.

## A high-level, target-agnostic specification format for running processes

During the development of the Nix process management framework I have written
configurations for various kinds of services for various kinds of process
managers.

If you look closely at their configurations, then I have noticed that they have
much in common. For example, to generate a `sysvinit` script for managing Nginx,
I can use the following Nix expression:

```nix
{createSystemVInitScript, nginx,  stateDir}:
{configFile, dependencies ? [], instanceSuffix ? ""}:

let
  instanceName = "nginx${instanceSuffix}";
  nginxLogDir = "${stateDir}/${instanceName}/logs";
in
createSystemVInitScript {
  name = instanceName;
  description = "Nginx";
  initialize = ''
    mkdir -p ${nginxLogDir}
  '';
  process = "${nginx}/bin/nginx";
  args = [ "-c" configFile "-p" stateDir ];
  runlevels = [ 3 4 5 ];

  inherit dependencies instanceName;
}
```

For `supervisord` I could write:

```nix
{createSupervisordProgram, nginx, stateDir}:
{configFile, instanceSuffix ? ""}:

let
  instanceName = "nginx${instanceSuffix}";
  nginxLogDir = "${stateDir}/${instanceName}/logs";
in
createSupervisordProgram {
  name = instanceName;
  command = "mkdir -p ${nginxLogDir}; "+
    "${nginx}/bin/nginx -c ${configFile} -p ${stateDir}";
}
```

And for `systemd` I could write:

```nix
{createSystemdService, nginx, stateDir}:
{configFile, instanceSuffix ? ""}:

let
  instanceName = "nginx${instanceSuffix}";
  nginxLogDir = "${stateDir}/${instanceName}/logs";
in
createSystemdService {
  name = instanceName;
  Unit = {
    Description = "Nginx";
  };
  Service = {
    ExecStartPre = "+mkdir -p ${nginxLogDir}";
    ExecStart = "${nginx}/bin/nginx -c ${configFile} -p ${stateDir}";
    Type = "simple";
  };
}
```

As you may probably have already seen, in all the examples I specify the same
kinds of configuration properties:
* The initialization steps
* The executable to run with the appropriate command-line arguments
* Meta information such as the name and description

We could also create a high-level abstraction that captures these properties:

```nix
{createManagedProcess, nginx, stateDir}:
{configFile}:

let
  nginxLogDir = "${stateDir}/${instanceName}/logs";
in
createManagedProcess {
  name = "nginx";
  description = "Nginx";
  initialize = ''
    mkdir -p ${nginxLogDir}
  '';
  process = "${nginx}/bin/nginx";
  args = [ "-c" configFile" -p" "${stateDir}/${instanceName}" ];
}
```

The above code example uses a high-level function: `createManagedProcess` that
specifies an `initialize` script and a process that we need to launch (`process`)
with a number of command-line parameters (`args`). This high-level specification
can be translated to a configuration file for various kinds of process managers.

Currently, the `createManagedProcess` function in the Nix process management
framework supports the following properties:

* `name`. Name of the service
* `description`. Description of the service
* `initialize`. Initialization script that initializes state on first startup.
* `foregroundProcess`. Path to an executable that launches a process in
  foreground mode
* `foregroundProcessArgs`. Command-line parameters propagated to the foreground
  process
* `daemon`. Path to an executable that launches a process in daemon mode
* `daemonArgs`. Command-line parameters propagated to the daemon
* `process`. When this property is specified, it translates both to:
  `foregroundProcess` and `daemon`.
* `args`. When this property is specified, it translates both to:
  `foregroundProcessArgs`, `daemonArgs`.
* `foregroundProcessExtraArgs`. Extra command-line parameters appended to the
  list of command-line parameters when the process runs in foreground mode
* `daemonExtraArgs`. Extra command-line parameters appended to the
  list of command-line parameters when the process runs in daemon mode
* `environment`. An attribute set with environment variables
* `user`. Name of the user we should change to
* `directory`. The current working directory we should change to before
  executing the process
* `nice`. Nice level
* `umask`. Umask
* `dependencies`. Specifies the process dependencies: dependencies on other
  running processes that should be deployed first.

### About foreground processes and daemons

The function abstraction makes a distinction between *foreground processes* and
*daemons*. Most modern process managers
(e.g. `systemd`, `launchd`, `supervisord`) have a preference for the former,
because they can be more reliably managed (i.e. no PID files). However,
`sysvinit` (which is an LSB standard) and `bsdrc` scripts require processes to
daemonize by themselves, otherwise the scripts will block.

Most services have the option to support both deployment scenarios. For an
optimal user experience, it is also best to support both. However, this is not a
strict requirement -- if a service is only offered as a foreground process then 
it can still be daemonized by calling an external tool, such as:
[libslack's daemon](https://libslack.org/daemon).

The inverse scenario is also possible -- if a service always daemonizes, you can
add a substitute proxy that runs in foreground mode that watches the lifecycle
of the daemon.

In the Nix process management framework, the `createManagedProcess` abstraction
will automatically use a simulation strategy when a deployment scenario is
unspecified. For example, if you only specify a `foregroundProcess` then it will
transparently call the `daemon` tool if a process manager requires a process to
daemonize by itself.

### Process dependencies

Another interesting concept is the notion process dependencies (`dependencies`
parameter). Sometimes, a service requires the presence of another service to
work reliably. For example, if you have a PHP application deployed to Apache
that uses a MariaDB database for data storage, then MariaDB needs to be
activated before Apache.

The `dependencies` parameter can be used to automatically generate a
configuration in which the order is preserved. For example, when generating
a `systemd` configuration, this property can be translated into `Wants=` and
`Requires=` directives. For `sysvinit` we can derived sequence numbers.

In NixOS, there is no high-level concept of process dependencies. It is still
possible to directly control the activation order by modifying systemd's `Wants=`
and `Requires=` directives through overrides, but this is not really
user-friendly.

### Process manager-specific overrides

Obviously, it is impossible to standardize all properties of all process
managers. Sometimes, it may still be desired to specify properties that are
unique to certain process managers.

For example, `sysvinit` has the notion of run levels that are not used by other
process managers. Specifying runlevels for `sysvinit` scripts can be done by
defining a process-manager specific override:

```nix
{createManagedProcess, nginx, stateDir}:
{configFile}:

let
  nginxLogDir = "${stateDir}/${instanceName}/logs";
in
createManagedProcess {
  name = "nginx";
  description = "Nginx";
  initialize = ''
    mkdir -p ${nginxLogDir}
  '';
  process = "${nginx}/bin/nginx";
  args = [ "-c" configFile" -p" "${stateDir}/${instanceName}" ];

  overrides = {
    sysvinit = {
      runlevels = [ 3 4 5 ];
    };
  };
}
```

In the above example, the `overrides.sysvinit` property specifies
`sysvinit`-only options. We use the override to define in which runlevels the
script should be started.

We can also use overrides for other process managers. For example, if we want
to use the readiness-check property of systemd (which is not standardized) or
Linux namespaces and cgroups, we can define a `systemd`-specific override.

## Writing services as units of instantiation rather than singleton objects

Compared to NixOS and other solutions, such as nix-darwin and system-manager,
another feature of the Nix process management framework is that services are
units of *instantiation* rather than *singleton* objects -- in NixOS, services
are bound to modules. As a result, services are singleton objects that only have
a single implementation and a single configuration.

For many kinds of services (e.g. PostgreSQL, Apache HTTP server etc), it
typically suffices to only have a single instance running on a machine. For
microservices, it may actually be quite useful to have the ability to easily
create multiple instances. For testing/experimentation purposes it may also be
desired to run multiple instances of a system service, such as a web server.

It is also not easily possible in NixOS to switch to alternative implementations
of a service. For many services, alternative implementations (e.g. `cron`,
`ssh`) are not required, but some services accept complex configurations, such
as the Apache HTTP server and Apache Tomcat.

Finding a universal abstraction in NixOS to facilitate all possible use cases
may be impossible. Moreover, it may also be desired for developers to write
their own abstractions on top of existing functionality.

To support abstractions and multiple instances, the Nix process management
framework does not use the NixOS module system, but a convention that is based
on the organisation of "ordinary" Nix packages in the Nixpkgs repository.

In Nixpkgs, most package follow the convention that a separate Nix file defines
a function in which the function header refers to the build-time dependencies to
construct a package from source. Packages are composed in the top-level Nix
expression (`all-packages.nix`) that invokes these functions with the required
build-time parameters. For most packages, only a single variant is composed, but
it is also possible to build different kinds of package variants by changing the
function parameters.

The Nix process management framework follows the same principles and extends the
Nixpkgs convention with a number of additional concepts:

* Every service is instantiated from a *constructor* which is a nested function:
  the outer function refers to the build-time dependencies that are required to
  build the service from source code.
* The inner function refers to the service *instance parameters* -- calling the
  constructor with different parameters makes it possible to compose a service
  with an alternative configuration and in such a way that they do not conflict
  with other instances.
* The build-time dependencies of constructor functions are composed in a Nix
  expression that is typically called: `constructors.nix` in which every
  constructor function is called with its required build-time dependency
  parameters.
* The process instances of a system are composed in a Nix expression that is
  typically called: `processes.nix` in which every constructor function is
  called with its required instance parameters.

```nix
{createManagedProcess, lib, postgresql, su, stateDir, runtimeDir}:

{ port ? 5432
, instanceSuffix ? ""
, instanceName ? "postgresql${instanceSuffix}"
, configFile ? null
, postInstall ? ""
}:

let
  postgresqlStateDir = "${stateDir}/db/${instanceName}";
  dataDir = "${postgresqlStateDir}/data";
  socketDir = "${runtimeDir}/${instanceName}";

  user = instanceName;
  group = instanceName;
in
createManagedProcess rec {
  inherit instanceName user postInstall;

  path = [ postgresql su ];
  initialize = ''
    mkdir -m0755 -p ${socketDir}
    mkdir -m0700 -p ${dataDir}

    chown ${user}:${group} ${socketDir}
    chown ${user}:${group} ${dataDir}

    if [ ! -e "${dataDir}/PG_VERSION" ]
    then
        su ${user} -c '${postgresql}/bin/initdb -D ${dataDir} --no-locale'
    fi

    ${lib.optionalString (configFile != null) ''
      ln -sfn ${configFile} ${dataDir}/postgresql.conf
    ''}
  '';

  foregroundProcess = "${postgresql}/bin/postgres";
  args = [ "-D" dataDir "-p" port "-k" socketDir ];
  environment = {
    PGDATA = dataDir;
  };

  overrides = {
    sysvinit = {
      runlevels = [ 3 4 5 ];
    };
  };
}
```

The above Nix expression shows a constructor function for PostgreSQL and has the
following properties:

* The outer function-header (first line) refer to the build inputs of the
  service. For example, to construct a configuration from a high-level
  specification for any supported process manager, we propagate the
  `createManagedProcess` as a parameter.
* The inner-function header refers to the instance parameters of a PostgreSQL
  instance. When it is desired to have two instances deployed to the same
  machine we must make sure that there is no conflict between the state of
  the two instances. Avoiding a conflict is possible by assigning a unique TCP
  port number and making sure that the state directories do not conflict. The
  `instanceName` parameter is appended to the name of the state directories to
  make this possible.
* In the body of the inner function, we invoke `createManagedProcess` to
  agnostically generate a configuration for a supported process manager.
  In the configuration, we provide an initialization script and we call the
  `postgres` service with its required command-line parameters and environment
  variables.

As explained earlier, a constructor function is a nested function that we need to compose
twice. The build-time dependencies are composed in a Nix expression typically called
`constructors.nix`:

```nix
{ nix-processmgmt ? ../../nix-processmgmt
, pkgs
, stateDir
, logDir
, runtimeDir
, cacheDir
, spoolDir
, libDir
, tmpDir
, callingUser ? null
, callingGroup ? null
, processManager
, ids ? {}
}:

let
  createManagedProcess = import "${nix-processmgmt}/nixproc/create-managed-process/universal/create-managed-process-universal.nix" {
    inherit pkgs runtimeDir stateDir logDir tmpDir processManager ids;
  };
in
{
  postgresql = import ./postgresql {
    inherit createManagedProcess stateDir runtimeDir;
    inherit (pkgs) lib postgresql su;
  };
}
```

In the above Nix expression, we invoke the `postgresql` constructor function and
we propagated its required build-time dependencies, such as the `postgresql`
package and the `createManagedProcess` abstraction function.

The instance parameters are composed in a Nix expression that is typically called
`processes.nix`:

```nix
{ pkgs ? import <nixpkgs> { inherit system; }
, system ? builtins.currentSystem
, stateDir ? "/var"
, runtimeDir ? "${stateDir}/run"
, logDir ? "${stateDir}/log"
, spoolDir ? "${stateDir}/spool"
, cacheDir ? "${stateDir}/cache"
, libDir ? "${stateDir}/lib"
, tmpDir ? (if stateDir == "/var" then "/tmp" else "${stateDir}/tmp")
, processManager
, nix-processmgmt ? ../../../nix-processmgmt
}:

let
  constructors = import ../../services-agnostic/constructors.nix {
    inherit pkgs stateDir runtimeDir logDir tmpDir cacheDir spoolDir libDir processManager nix-processmgmt;
  };
in
rec {
  postgresql = rec {
    port = 5432;

    pkg = constructors.simplePostgresql {
      inherit port;
    };
  };

  postgresql-secondary = rec {
    port = 5433;

    pkg = constructors.simplePostgresql {
      inherit port;
      instanceSuffix = "-secondary";
    };
  };
}
```

In the above Nix expression, we compose two PostgreSQL instances that run on the
same machine simultaneously. This is possible due to the fact that they use
instance parameters that avoid their states to conflict.

The above expression imports the `constructors.nix` expression so that each
process instance can be composed from the PostgreSQL constructor function.

In NixOS, we use the NixOS module system that makes it possible to define
multiple aspects of a system in a module (such as packages, config files,
systemd units and environment variables) and combine the aspects of each module
into a single configuration from which a complete system is deployed, which is
very powerful.

Combining the conventions of the nix-processmgmt framework with the NixOS module
system is something that still needs to be discussed. There are variety of
options possible, such as:

* Combining the convention with process instances as described earlier by
  referring to a process instance from a NixOS module, similar to how NixOS
  modules can also refer to ordinary Nix packages
* Using sub modules, in which every sub module can define its own variant of a
  service.

### Unprivileged user deployments

Another interesting feature of Nix is to allow unprivileged users to deploy
packages. With services, this is also possible, but there are some things we
need to take into account, such as:

* The state directories must refer to a directory that has writable permissions
  for the user
* We cannot bind to a TCP/UDP port below 1024

We can also introduce a configuration flag and configure a service in such a way
that the above criteria are met:

```nix
{createManagedProcess, lib, postgresql, su, stateDir, runtimeDir, forceDisableUserChange}:

{ port ? 5432
, instanceSuffix ? ""
, instanceName ? "postgresql${instanceSuffix}"
, configFile ? null
, postInstall ? ""
}:

let
  postgresqlStateDir = "${stateDir}/db/${instanceName}";
  dataDir = "${postgresqlStateDir}/data";
  socketDir = "${runtimeDir}/${instanceName}";

  user = instanceName;
  group = instanceName;
in
createManagedProcess rec {
  inherit instanceName user postInstall;

  path = [ postgresql su ];
  initialize = ''
    mkdir -m0755 -p ${socketDir}
    mkdir -m0700 -p ${dataDir}

    ${lib.optionalString (!forceDisableUserChange) ''
      chown ${user}:${group} ${socketDir}
      chown ${user}:${group} ${dataDir}
    ''}

    if [ ! -e "${dataDir}/PG_VERSION" ]
    then
        ${lib.optionalString (!forceDisableUserChange) "su ${user} -c '"}${postgresql}/bin/initdb -D ${dataDir} --no-locale${lib.optionalString (!forceDisableUserChange) "'"}
    fi

    ${lib.optionalString (configFile != null) ''
      ln -sfn ${configFile} ${dataDir}/postgresql.conf
    ''}
  '';

  foregroundProcess = "${postgresql}/bin/postgres";
  args = [ "-D" dataDir "-p" port "-k" socketDir ];
  environment = {
    PGDATA = dataDir;
  };

  overrides = {
    sysvinit = {
      runlevels = [ 3 4 5 ];
    };
  };
}
```

The above Nix expression shows a revised PostgreSQL constructor function that
accepts a new parameter: `forceDisableUserChange`. When this property is
enabled, the service configured in such a way that it does not change users,
which an unprivileged user is not allowed to do. With this setting enabled, it
becomes possible for an unprivileged user to deploy PostgreSQL.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

The `processes.nix` expression shown earlier can be used with a variety of tools
to deploy running process instances.

The following command deploys the configurations as `sysvinit` scripts and
activates the configuration automatically:

```bash
$ nixproc-sysvinit-switch processes.nix
```

We can deploy the same configuration as systemd units with the following command:

```bash
$ nixproc-systemd-switch processes.nix
```

Or with `supervisord` with the following command:

```bash
$ nixproc-supervisord-switch processes.nix
```

As an unprivileged user, we can use the `--state-dir` parameter to change the
prefix of the state directories to reside in a user's home directory
(`/home/sander/var`) and disable user changing:

```bash
$ nixproc-sysvinit-switch --state-dir /home/sander/var --force-disable-user-change processes.nix
```

# Drawbacks
[drawbacks]: #drawbacks

The ideas describes in this RFC makes the Nixpkgs eco-system more powerful, but
these new features come at at a price:

* Using high-level abstractions hide the low-level configuration details of
  specific process managers. This makes it sometimes more difficult to reason
  about what is happening in problematic cases
* More testing is required -- we need to test services in multiple deployment
  scenarios, which is more expensive. Fortunately, I have seen that testing for
  two kinds of targets often give enough certainty: if you test with a
  foreground process (e.g. `systemd`) and a daemon (e.g. `sysvinit`) there is a
  big chance that it will work with other process managers as well.
* You may target the lowest common denominator. This is not actually true,
  because with overrides it is still possible to use any feature of a process
  manager. Moreover, not all services need to be portable -- low-level services
  such as `cups` and `syslogd` can still be packaged in a process
  manager-specific way.

# Alternatives
[alternatives]: #alternatives

This RFC proposes a new strategy to allow multiple process instances of the
same service to co-exist. Co-existence is possible by avoiding conflicts --
making sure that state directories and port numbers do not conflict through
function parameters.

It is also possible to isolate services by using concepts such as Linux
namespaces. Then it is not required to avoid certain kinds of conflicts.
Unfortunately, using these features is restricted to Linux only -- this RFC aims
to be operating system agnostic.

# Prior art
[prior-art]: #prior-art

This RFC is not the first approach that combines Nix with a process management
solution:

* [NixOS](https://nixos.org) uses `systemd` as its process management solution.
  Services can be deployed by generating systemd unit configuration files in a
  Nix expression. NixOS deploys `systemd` units globally and requires super
  user privileges to get deployed. Moreover, you cannot use the service layer
  independently from the rest of NixOS.
* [nix-darwin](https://github.com/LnL7/nix-darwin) provides various NixOS
  features on macOS/Darwin, including a service management layer that uses the
  process manager of macOS: `launchd`.
* [home-manager](https://github.com/nix-community/home-manager) offers a service
  layer that works with systemd user services, rather than system services. It
  contains its own set of service configurations that can be deployed as user
  services.
* [system-manager](https://github.com/numtide/system-manager) addresses the
  limitation of NixOS to use systemd units independently and can deploy many
  services in the NixOS repository on any Ubuntu-based distribution.
* [nixos-init-freedom](https://git.sr.ht/~guido/nixos-init-freedom) puts some
  efforts on replacing systemd-as-pid-1 with s6. Instead of implementing a
  generic service layer, it translates parts of systemd module configuration
  into s6 configuration.

The biggest drawback is that these solutions are not generic and there is only
little reuse possible between service configurations.

There are also solutions that introduce a portable approach for managing
processes in combination Nix:

* The service deployment chapter (chapter 9) of
  [Eelco Dolstra's PhD thesis](https://github.com/edolstra/edolstra.github.io/blob/master/pubs/phd-thesis.pdf)
  describes a very early service deployment approach that uses generated
  start/stop scripts implemented in `bash`. Because shell scripts are so common,
  they can be used on a variety of operating systems -- in addition to Linux, it
  can also be used on Darwin and FreeBSD.
* [Dysnomia](https://github.com/svanderburg/dysnomia) is a system to manage the
  life-cycle of services deployed by
  [Disnix](https://github.com/svanderburg/disnix) in a generic way. It has its
  own `process` module that deploys services as daemons running the background.
  It can also use the Nix process management framework to deploy services that
  are managed by any kind process manager supported by the framework.
* [devenv](https://devenv.sh) also makes it possible to run multiple processes
  (of different services) in a Nix-based development environment. It works a
  with a variety container-friendly/non-PID-1 based process managers, such as
  `process-compose`, `overmind`, and `honcho`.
* [NixNG](https://github.com/nix-community/NixNG) is considered a late sibling
  to NixOS and shares many designs of it. It also implements the function of
  generating services for several kinds of container-friendly init systems from
  the same Nix expressions. NixNG is primarily used to run in containers.
* [dream2nix](https://github.com/nix-community/dream2nix) has a work-in-progress
  implementation for a high-level specification that can be translated to
  configurations for multiple process managers.

The drawback of some of these solutions is that they rely on services that
daemonize on their own. Although they are portable, not all services have
such functionality. Moreover, foreground processes can be more reliably managed
because they do not rely on PID files -- PID files may get inconsistent.

The other solutions only work with container-friendly supervisors and not with
commonly used process managers, such as `systemd`.

# Unresolved questions
[unresolved]: #unresolved-questions

The integration with NixOS module system still needs to be worked out in detail.
Currently, I can think of two scenarios. For this a discussion in the Nix
community is required.

# Future work
[future]: #future-work

NixOS includes its own test driver that can be used to test services. If we
support multiple process managers and operating systems, then we need a more
generic test driver that can also deploy disk images of alternative operating
systems so that these other scenarios can also be tested automatically.
