---
feature: self-describing-store
start-date: 2026-01-18
author: Robert Hensing
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Stores provide a `nix-store.json` file declaring their properties,
including physical encoding, required features, and substituter defaults.
This enables clients to discover store settings,
provides forward compatibility through explicit feature requirements,
and replaces the ad hoc `nix-cache-info` format with a unified JSON-based mechanism.

# Motivation
[motivation]: #motivation

## Store settings are not discoverable

Currently, store settings must be configured externally by the client.
This is error-prone:
users must know and remember the correct settings,
settings can become out of sync with actual store state,
and copying stores via filesystem operations loses this configuration entirely.

Examples of settings that should be discoverable from the store itself:

- `storeDir` (e.g., `/nix/store` vs a custom path)
- Compression algorithms (for binary caches)
- Trust settings and signature requirements
- Physical encodings such as the case hack

## Stores lack forward compatibility mechanisms

Derivations have `requiredSystemFeatures` (e.g., `kvm`, `big-parallel`) that
builders check before attempting a build.
Stores lack an equivalent mechanism.

Without this:

- An old Nix might try to read a store using features it does not understand
- This could cause corruption or misinterpretation of data
- There is no graceful failure or degradation path

Examples of store features that may require client support:

- Content-addressing modes (input-addressed, content-addressed, floating content-addressed)
- Hash algorithms (SHA-256, SHA-512, future algorithms)
- Reference encoding schemes
- Future store object formats

## `nix-cache-info` is an ad hoc format

Binary caches currently use `nix-cache-info`:

```
StoreDir: /nix/store
WantMassQuery: 1
Priority: 40
```

This has several problems:

- It is a bespoke key-value format, not a standard like JSON
- It only exists for binary caches, not local or daemon stores
- The parser ignores unknown fields, so it is extensible to a degree,
  but lacks proper forward compatibility:
  a store cannot explicitly reject an old client that lacks required features

## Enabling the Binary Cache Index Protocol

[RFC 195](https://github.com/NixOS/rfcs/pull/195) proposes a significant but
compatible addition that adds some structured data to the binary cache protocol,
synced periodically.

If that RFC is accepted, combining its data into `nix-store.json` could improve
`nix-cache-info`'s cache staleness on clients from up to 7 days to mere minutes,
as well as slightly reduce the number of requests.
The details of such an integration would be decided by those involved with RFC 195.

## Concrete example: the case hack

The `use-case-hack` setting enables encoding of file names to work on
case-insensitive file systems.
This involves transforming paths, for example:

```
Foo/bar  →  foo~nix~case~hack~1/bar
```

Currently this is a global setting, but it should be a store property.
Case-hackedness is a property of the store *contents*, not the environment:

- A case-hacked store copied to a case-sensitive filesystem is still case-hacked
- The filesystem's case-sensitivity does not tell you what encoding the data uses
- Removing the case hack requires a *transformation*, not just changing a setting

This is analogous to character encoding:
you cannot infer UTF-8 vs Latin-1 in an email from the OS locale configuration.
The web and email solve this with a `Content-Type` header that accompanies the content —
the data declares its own encoding.
Stores should do the same.

Related issues:

- [NixOS/nix#9318](https://github.com/NixOS/nix/issues/9318) — `use-case-hack` is a property of a store, not a global setting
- [NixOS/nix#1446](https://github.com/NixOS/nix/issues/1446) — Darwin does not imply case-insensitive file system

# Detailed design
[design]: #detailed-design

## Metadata file

Stores provide a `nix-store.json` file containing metadata in JSON format.

```json
{
  "version": 1,
  "storeDir": "/nix/store",
  "fileSystemObjectEncoding": {
    "caseHack": true
  },
  "requiredFeatures": [],
  "expectedFeatures": [],
  "usedFeatures": [],
  "substituterDefaults": {
    "wantMassQuery": true,
    "priority": 40
  }
}
```

## Fields

### `version`

A major version number for this metadata format.
Only incremented as part of a major cleanup in the far future.
Granular evolution is handled by the feature lists, avoiding coordinated version bumps.

### `storeDir`

The *logical* location of the store:
the path that programs in the store may expect,
as opposed to the physical location Nix operates on.
On a running NixOS system, these locations are the same for its system store: `/nix/store`.

See also: [`store`](https://nix.dev/manual/nix/latest/store/types/local-store#store-local-store-store) setting.

### `fileSystemObjectEncoding`

An object describing physical encodings applied to file system objects.

- `caseHack`: Whether the case hack encoding is applied.

### Feature lists

Three lists of feature strings, using `kebab-case` naming
(consistent with `experimental-features` and `requiredSystemFeatures`):

| Field | Client behavior when feature not known |
|-------|----------------------------------------|
| `requiredFeatures` | Must refuse to operate (would misinterpret/corrupt data) |
| `expectedFeatures` | Should warn, may proceed with caution |
| `usedFeatures` | Informational; silent degradation acceptable |

Criteria for categorization:

- **required**: Client would actively misinterpret data (e.g., unknown encoding)
- **expected**: Client can proceed but with reduced guarantees (e.g., cannot verify some store paths' validity with unknown hash algorithm)
- **used**: Silent degradation acceptable, or feature is engineered to degrade gracefully, or feature is an addition that does not cause failures in other parts of the system

### `substituterDefaults`

Settings for binary cache substitution, subsuming fields from `nix-cache-info`:

- `wantMassQuery`: Whether to batch path info queries.
- `priority`: Substituter priority.

## File location

### Local stores

- The file resides next to the database: `/nix/var/nix/db/nix-store.json`
- A symlink in the store points to it: `/nix/store/nix-store.json` → `../../var/nix/db/nix-store.json`

This ensures old Nix versions can garbage-collect or clear the symlink without
losing the actual file, and new Nix versions can recover or regenerate it.

### Binary cache stores (HTTP, S3, local file)

The file resides at the root: e.g., `https://cache.nixos.org/nix-store.json`

### Client behavior

1. Query `nix-store.json`.
2. If absent, fall back to `nix-cache-info` (for old caches).

When `nix-store.json` is present, `nix-cache-info` must not be queried,
except to validate backwards compatibility for diagnostic purposes.
For instance, `nix store info` would do well to query both files and warn if they do not match.

## Daemon protocol

The store metadata is consumable through the daemon/worker protocol.
Clients should not need direct filesystem access to discover store properties,
especially for non-local daemons such as remote builders.

Clients are generally isolated from store details such as case hack.
However, exposing this information is invaluable for diagnosing problems
and as a last resort for automated workarounds.

## Interpretation

Interpretation of the file is generally lenient
so as to allow the addition of information without unnecessarily affecting old clients.
Unknown fields are ignored.
The feature fields provide mechanisms to control compatibility and correctness behavior
when leniency is not appropriate.

Implementations should validate fields they use as they deem appropriate,
but should not attempt to validate the entire file,
as this conflicts with future compatibility and the flexibility of decentralized evolution.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

## Copying between stores with different encodings

Alice has a case-hacked store on macOS. She copies it to a Linux server using `rsync`.
Without self-describing stores, the Linux Nix has no way to know the data is case-hack encoded.
Store verification reports false corruption.

With this RFC, the `nix-store.json` file travels with the data.
The Linux Nix reads `fileSystemObjectEncoding.caseHack = true` and knows to
reverse the encoding when reading paths, or to transform the store to remove
the case hack.

## Old Nix encountering a new store feature

A binary cache starts using [BLAKE3](https://nix.dev/manual/nix/latest/development/experimental-features.html#blake3-hashes) for some store paths.
It declares `"expectedFeatures": ["blake3-hashes"]`.

An old Nix that does not support BLAKE3:
1. Reads `nix-store.json`
2. Sees `blake3-hashes` in `expectedFeatures`
3. Warns: "store has unsupported feature `blake3-hashes`; consider updating your Nix version"
4. Continues operating

If the feature were in `requiredFeatures` instead, the old Nix would refuse
to use the cache entirely.

## Binary cache migration

A cache operator upgrades their cache to serve `nix-store.json`.
They also continue serving `nix-cache-info` for old clients.

```
https://cache.example.com/
├── nix-store.json      # new metadata
├── nix-cache-info      # legacy, for old clients
└── nar/
    └── ...
```

New Nix clients read `nix-store.json` and ignore `nix-cache-info`.
Old Nix clients that do not know about `nix-store.json` simply use `nix-cache-info`.

The operator can use `nix store info` to verify both files are consistent.

## Local store initialization

When Nix initializes a new local store, it:

1. Detects filesystem properties (e.g., case sensitivity)
2. Writes `/nix/var/nix/db/nix-store.json` with appropriate settings
3. Creates the symlink `/nix/store/nix-store.json`

If the symlink is garbage-collected by an old Nix, a new Nix regenerates it
on next access.

# Drawbacks
[drawbacks]: #drawbacks

No significant drawbacks.
This change introduces complexity,
but failing to handle the intrinsic complexity of variations between stores is worse.

# Alternatives
[alternatives]: #alternatives

## Status quo

We could leave things as they are:
store settings remain external configuration,
`nix-cache-info` remains the only store metadata,
and issues like the case hack remain unsolved.

As Nix supports more diverse store configurations and features,
this becomes increasingly untenable.

## Extend `nix-cache-info`

Rather than introducing a new file, we could add fields to `nix-cache-info`.

However, the format is bespoke and harder to extend cleanly.
More fundamentally, it only exists for binary caches,
leaving local stores without metadata.
It also lacks a forward compatibility mechanism:
unknown fields are silently ignored,
so a store cannot reject clients that lack required features.

## Database only

For local stores, we could store metadata in the SQLite database
rather than a separate file.

However, binary caches have no database.
The daemon protocol would become the only way to access metadata,
preventing filesystem-level tools from discovering store properties.
Copying a store via filesystem operations would also lose the metadata,
which is precisely the problem this RFC aims to solve.

## Different file format

We could use TOML or another format instead of JSON.

JSON was chosen because this file is not meant for user editing,
so comments are unnecessary.
Some fields like encoding must be managed by Nix;
changing them by hand would corrupt the store.
Other fields like `substituterDefaults` may be acceptably edited by hand,
for instance in a bucket-based binary cache.
Nix already has robust JSON parsing, and the format is widely supported.

# Prior art
[prior-art]: #prior-art

## HTTP and email `Content-Type`

The web and email faced the same problem:
how does a recipient know how to interpret a message body?
The solution was the `Content-Type` header,
which declares the media type and character encoding.
This RFC applies the same principle to Nix stores.

## File format headers

Binary file formats commonly include magic numbers and version information
in their headers.
For example, PNG files begin with a fixed signature,
and SQLite databases include format version bytes in their header.
This allows tools to identify and validate files before processing them.

## Git repository format version

Git repositories include a `core.repositoryformatversion` setting
that indicates the repository format.
Extensions are declared separately,
allowing Git to refuse operations on repositories with unknown extensions.
This is similar to our `requiredFeatures` mechanism.

# Unresolved questions
[unresolved]: #unresolved-questions

## File naming

Should the file be named differently?

- `nix-store.json` — plain name (proposed)
- `.nix-store.json` — hidden, like the `.links` directory in local stores
- `.well-known/nix-store.json` — aligns with (or abuses) web convention ([RFC 8615](https://www.rfc-editor.org/rfc/rfc8615))

`nix-cache-info` is not hidden, so `nix-store.json` is consistent with precedent.
The `.links` directory is different:
it is internal bookkeeping not meant for client discovery,
whereas this file is explicitly for clients to discover store properties.
The `.well-known` approach may be excessive and cause more trouble than it solves.

# Future work
[future]: #future-work

We expect this feature to be used productively by various new proposals
as well as proposals to enhance existing functionality
by tracking information more accurately as it pertains to stores.

Examples:
- Logic for handling `caseHack` properly may be implemented
- [RFC 195](https://github.com/NixOS/rfcs/pull/195) may store some of its data in `nix-store.json`

A JSON Schema file may be maintained.
We recommend it to be lenient,
and for `$schema` to reference a mutable resource that provides the latest schema.
