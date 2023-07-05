# Motivation for Migrations 

While the current NixOS Configuration system works incredibly well for immutable services, not all services are immutable, and we currently lack facilities to handling imperative steps needed to upgrade or downgrade complex stateful services. Nix can even be an obstacle to doing so, as often these steps are dissonant with the methodologies required for declarative and immutable structures.

Let's take the example of GitLab. GitLab is notoriously hard to upgrade, and the current NixOS module system produces major obstacles to upgrades of this nature, as GitLab expects the user to run many imperative steps to modify stateful parts of the application such as the database and configuration files. The need to migrate stateful portions of an application to new versions is nothing new; database migrations are standard practice and can provide structure and inform the concerns of module migrations.

With the extension of the NixOS Configuration system with migration infrastructure, we can close this conceptual gap and fully realize the value of atomic immutable deployments, as we gain the ability to atomically migrate parts of stateful services along with the packages and definitions.

# Proposed Migration Structure

The following extension to the module system and standard is proposed. Each migration is a Set defined in Nix with the following fields:

- `version`
- `up`
- `down`

`up` and `down` are both Nix Sets with the following fields:

- `script`
- `warn`
- `backup`
- `restore`

## Version Information

For migrations to work we must know what version the stateful parts of this service are currently using; this will be stored in the metadata of the systemd service in a standard location to be determined. This is needed for the same reason as in the database migration context: to determine which migrations are needed to achieve the new state.

```Nix
{
  config.migrations = [ { version = "2023-04-07"; ... } ];
}
```

The version information will be stored as a formatted date string (such that lexigraphical and chronological sort are the same), representing the date at which the migration was merged into Nixpkgs.

## Up Script

A place in the Nix Module system for describing the imperative steps required to migrate from the previous version to the new version. This will be run as a systemd "oneshot" service, to take advantage of the standard architecture.

```Nix
{
  up.script = ''
    ${pkgs.my-service-cli} --run-migration /etc/service-state
  '';
}
```

# Down Script

A place in the Nix Module system for describing the imperative steps required to migrate from the current version to the previous version. This will run as a systemd "oneshot" service, to take advantage of the standard architecture. 

```Nix
{
  down.script = "my-service.up" ''
    ${pkgs.my-service-cli} --run-migration /etc/service-state
  '';
}
```

## Transactionality and Warnings

There are limitations for to the effectiveness of up and down scripts. For example, some migrations are destructive in nature, meaning returning to a previous version is not possible. Sometimes a service cannot be upgraded. Human error and entropy can cause these scripts to fail to execute. In a database migration context we can rely on transactions to cope with some of these issues, a luxury we do not have in this context. As such the onus is placed on the module author to provide these properties to the best of their ability. 

### Known destructive migration

```Nix
{
  up.warn = ''
    The 2023 version of My Service requires the deletion of configuration files. Therefore downgrading in an automated fashion is not possible. This is due to unfortunate hard coding of paths in My Service. You can find your old configuration files retained at /etc/service-state-old for your records. 
  '';
  down.warn = ''
    Downgrade was not attempted as the 2023 upgrade is known to be destructive. If you retained your old configuration files, you need to copy them back to /etc/service-state manually.
  '';
}
```

## Failure potential

```Nix
{
  up.backup = ''
    # backup stateful directory
    cp -r /etc/my-state $BACKUP
  '';
  up.restore = ''
    # restore stateful directory as the script failed
    cp -r $BACKUP /etc/my-state
  '';
}
```

`$BACKUP` is a path to a temporary filesystem location which will be deleted upon completion of the migration. This provides a temporary location to backup state if needed. `up.backup` is a hook that will run before `up.script`. If `up.script` encounters an error, `up.restore` is run to ensure that the failed migration does not result in contamination of the system. These options are available in both `up` and `down` definitions. This roughly allows for transaction-like logic for the migration.

# Testing

Extend the NixOS VM Test framework to ergonomically test migrations in an automated fashion. Migrations should be accompanied by VM tests demonstrating that migrations succeed from a clean service state.

# Sequencing

Migrations need to be run in order, executing each one at a time. This is accomplished by constructing each migration as a "oneshot" systemd process at runtime with each migration depending on the result of the previous one; until the desired state is achieved.

# Migrations for critical services

In this effort we also hope to provide migrations for the following modules, establishing the ability to migrate Nix Modules for the future.

- GitLab
- Postgresql (needs to work well with entities like `ensure`)
- Jira
- MySQL
- Kibana
- LDAP
- MongoDB
- Neo4J
- Jupyter
- Jenkins
- CouchDB
- Consul
- ??
