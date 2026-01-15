---
feature: binary-cache-index-protocol
start-date: 2026-01-14
author: Wael Nasreddine
co-authors: (to be determined)
shepherd-team: (to be nominated and accepted by RFC steering committee)
shepherd-leader: (to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

This RFC proposes a standardized client-side indexing protocol for Nix Binary Caches that enables efficient store path discovery without requiring per-path HTTP requests. The protocol introduces a **Hybrid Log-Structured Sharded Index (HLSSI)** that uses deterministic compressed hash storage, enabling clients to definitively determine cache membership before issuing network requests. The design supports caches ranging from ~100 items (homelabs) to 1+ billion items (cache.nixos.org) while maintaining sub-second freshness for CI/CD pipelines and supporting garbage collection without requiring expensive storage listing operations.

# Motivation
[motivation]: #motivation

## The Current Problem

Nix binary caches operate as content-addressable stores where artifacts are addressed by their store path hash. Currently, clients discover whether a cache contains a specific path using a "poll-and-pray" approach:

```
Client: GET /b6gvzjyb2pg0kjfwn6a6llj3k1bq6dwi.narinfo
Server: 200 OK (cache hit) or 404 Not Found (cache miss)
```

When a path is missing, the client moves to the next cache in its substituter list. This approach has several critical deficiencies:

1. **Latency Accumulation**: Each cache miss incurs a full HTTP round-trip. For builds with thousands of dependencies querying multiple caches, this compounds to significant delays.

2. **Bandwidth Inefficiency**: HTTP headers, TLS handshakes, and connection overhead dominate when the actual answer is a single bit of information (present/absent).

3. **Backend Load**: High-frequency HEAD/GET requests against object storage (S3, R2) incur per-request costs and can trigger rate limiting.

4. **Poor Offline/Intermittent Connectivity Handling**: Clients cannot make any progress without network access to check each path individually.

## Use Cases Supported

1. **CI/CD Pipeline Acceleration**: A typical NixOS system closure involves 1,000–5,000 store paths. Determining cache hits upfront allows optimal parallelization of downloads vs. builds.

2. **Multi-Cache Federation**: Organizations often chain caches (private → community → cache.nixos.org). An index allows intelligent cache selection without sequential probing.

3. **Offline-First Workflows**: Developers can sync an index and determine substitutability without continuous network access.

4. **Cache Analytics**: Operators can analyze index files to understand cache composition, hit rates, and optimize retention policies. Since HLSSI stores actual hashes (not lossy Bloom filter bits), operators can: count exact items, analyze hash distribution across shards, compare indices between caches to measure overlap, and identify "miss patterns" to improve cache coverage.

## Expected Outcome

A client implementing this protocol will:
- Reduce cache lookup latency by 90%+ for cache misses
- Eliminate unnecessary HTTP requests entirely for definitive misses
- Support caches from 10,000 to 1,000,000,000+ items with proportional bandwidth costs
- Discover newly-pushed artifacts within seconds
- Operate correctly as caches perform garbage collection

# Detailed design
[design]: #detailed-design

## 1. Protocol Overview

The protocol defines a three-layer architecture that separates concerns across different time horizons:

| Layer | Name | Purpose | Mutability |
|-------|------|---------|------------|
| 0 | Manifest | Self-describing metadata and routing | Updated on structural changes |
| 1 | Journal | Real-time additions and deletions | Append-only, periodically archived |
| 2 | Shards | Bulk membership data | Immutable per epoch |

Additionally, the protocol supports **differential updates** (Section 10) allowing clients to efficiently synchronize by downloading only the changes between epochs rather than full shard files.

All files are static and served via standard HTTP from any object storage or web server. No server-side computation is required.

## 2. Store Path Hash Specification

Nix store paths follow the format:
```
/nix/store/<hash>-<name>
```

Where `<hash>` is a 32-character string using Nix's custom base32 alphabet (`0123456789abcdfghijklmnpqrsvwxyz` — notably excluding `e`, `o`, `u`, `t`). This encodes 160 bits of a truncated SHA-256 digest.

For indexing purposes, we operate exclusively on the 32-character hash portion, which we treat as a 160-bit unsigned integer for sorting and compression.

### 2.1 Byte Order Specification

The 32-character base32 string MUST be interpreted as a **big-endian** 160-bit unsigned integer. This ensures that the lexicographic ordering of strings matches the numeric ordering of integers, which is essential for correct sharding (prefix-based routing) and binary search operations.

**Interpretation Rules**:
- `"00000000000000000000000000000000"` maps to integer `0`
- `"zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"` maps to integer `2^160 - 1` (maximum value)
- The first character represents the most significant 5 bits
- The last character represents the least significant 5 bits
- Sorting hashes as strings produces the same order as sorting them as integers

**Example Conversions**:

| Base32 String | Big-Endian Integer | Notes |
|---------------|-------------------|-------|
| `10000000000000000000000000000000` | 2^155 | First char `1` = 1, rest zeros |
| `01000000000000000000000000000000` | 2^150 | Second char `1` = 1 contributes at lower position |
| `00000000000000000000000000000001` | 1 | Only least significant 5 bits set |
| `g0000000000000000000000000000000` | 16 × 2^155 | `g` = 16 in Nix base32 |

**Why Big-Endian Matters**:

With big-endian interpretation, lexicographic string sort equals numeric sort:
```
"0abc..." < "1abc..."  ✓ (string comparison)
    0...  <     1...   ✓ (numeric comparison)
```

If little-endian were used (incorrectly), the first character would be the *least* significant, breaking the sort invariant:
```
"1000...0000" would map to 1 (WRONG for our purposes)
"0000...0001" would map to 2^155 (WRONG for our purposes)
```

This would cause sharding by prefix to group numerically distant hashes together, destroying the compression benefits of delta encoding (which relies on numerically adjacent hashes having small gaps).

**Implementation Note**: When converting, process characters left-to-right, shifting the accumulated value left by 5 bits before adding each new character's value:
```
result = 0
for char in base32_string:
    result = (result << 5) | nix_base32_value(char)
```

## 3. Layer 0: Manifest

The manifest is a JSON file at a well-known path that describes the index topology:

**Path**: `/nix-cache-index/manifest.json`

**Example**:
```json
{
  "version": 1,
  "format": "hlssi",
  "created_at": "2026-01-13T12:00:00Z",
  "item_count": 1200000000,
  "sharding": {
    "depth": 2,
    "alphabet": "0123456789abcdfghijklmnpqrsvwxyz"
  },
  "encoding": {
    "type": "golomb-rice",
    "parameter": 8,
    "hash_bits": 160,
    "prefix_bits": 10
  },
  "journal": {
    "current_segment": 1705147200,
    "segment_duration_seconds": 300,
    "retention_count": 12
  },
  "epoch": {
    "current": 42,
    "previous": 41
  },
  "deltas": {
    "enabled": true,
    "oldest_base": 35,
    "compression": "zstd"
  }
}
```

**Field Definitions**:

- `version`: Protocol version (currently 1). Clients MUST reject manifests with unsupported versions.
- `format`: Index format identifier (`hlssi` for this RFC)
- `created_at`: ISO 8601 timestamp of when this manifest was generated
- `item_count`: Total number of store path hashes indexed across all shards. This is approximate and provided for client information and debugging purposes; it may drift slightly between compactions.
- `sharding.depth`: Number of prefix characters used for partitioning (0–4)
- `sharding.alphabet`: The base32 alphabet used for shard prefixes. MUST match Nix's alphabet: `0123456789abcdfghijklmnpqrsvwxyz`
- `encoding.type`: Compression algorithm for shard files
- `encoding.parameter`: Golomb-Rice divisor exponent (M = 2^parameter)
- `encoding.hash_bits`: Total bits in a full store path hash (160 for Nix)
- `encoding.prefix_bits`: Bits consumed by the shard prefix, used to compute suffix size. For depth=2, this is 10 bits (2 characters × 5 bits each).
- `journal.current_segment`: Unix timestamp of the active journal segment
- `journal.segment_duration_seconds`: How often segments rotate (e.g., 300 = 5 minutes)
- `journal.retention_count`: Number of journal segments retained before archival into shards
- `epoch.current`: Current shard generation number
- `epoch.previous`: Previous shard generation (for grace period support; see Section 9)
- `deltas.enabled`: Whether differential updates are available (see Section 10)
- `deltas.oldest_base`: Oldest epoch from which deltas can be applied. Clients with a local epoch older than this must perform a full download.
- `deltas.compression`: Compression algorithm for delta files (`none`, `zstd`)

**Caching**: Clients SHOULD cache the manifest with a short TTL (30–120 seconds) and revalidate using `If-Modified-Since` or `ETag`.

**Integrity Verification**: Clients SHOULD verify manifest integrity using HTTP-level mechanisms (`ETag`, `Content-MD5`). Cryptographic signing of index files is deferred to future work (see Future Work: Index Signing and Trust).

## 4. Layer 1: Journal (Hot Layer)

The journal captures recent mutations with minimal latency.

**Path Pattern**: `/nix-cache-index/journal/<timestamp>.log`

**Format**: Line-delimited text, one operation per line:
```
+b6gvzjyb2pg0kjfwn6a6llj3k1bq6dwi
+a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
-x9y8z7w6v5u4t3s2r1q0p9o8n7m6l5k4
+q1w2e3r4t5y6u7i8o9p0a1s2d3f4g5h6
```

- Lines beginning with `+` indicate additions
- Lines beginning with `-` indicate deletions (tombstones)
- Hash is the 32-character store path hash (no `-name` suffix)

**Segment Lifecycle**:
1. Writer appends to current segment file
2. Every `segment_duration_seconds`, a new segment begins
3. Segments older than `retention_count` are archived into shards during compaction
4. Archived segments are deleted after successful compaction

**Write Protocol** (for cache operators):
```
On artifact push:
  1. Upload .narinfo and .nar to storage
  2. Append "+<hash>\n" to current journal segment

On garbage collection:
  1. Delete .narinfo and .nar from storage
  2. Append "-<hash>\n" to current journal segment
```

## 5. Layer 2: Shards (Cold Layer)

Shards contain the bulk of membership data, compressed using Golomb-Rice coding.

**Path Pattern**: `/nix-cache-index/shards/<epoch>/<prefix>.idx`

For `sharding.depth = 2`:
```
/nix-cache-index/shards/42/b6.idx    # All hashes starting with "b6"
/nix-cache-index/shards/42/a1.idx    # All hashes starting with "a1"
...
```

For `sharding.depth = 0` (small caches):
```
/nix-cache-index/shards/42/root.idx  # All hashes in single file
```

### 5.1 Shard File Format

```
+------------------+------------------+------------------+
|     Header       |   Sparse Index   |   Encoded Data   |
|    (64 bytes)    |    (variable)    |    (variable)    |
+------------------+------------------+------------------+
```

**Header** (64 bytes, fixed, no padding required):
```
Offset  Size  Field
------  ----  -----
0       8     Magic number: "NIXIDX01" (ASCII)
8       8     Item count (uint64, little-endian)
16      1     Golomb parameter k (uint8, where M = 2^k)
17      1     Hash suffix bits (uint8, typically 160 - prefix_bits)
18      8     Sparse index offset from start of file (uint64, little-endian)
26      8     Sparse index entry count (uint64, little-endian)
34      8     XXH64 checksum of encoded data section (uint64, little-endian)
42      22    Reserved for future use (must be zeros)
------  ----
Total:  64 bytes
```

**Implementation Note**: The header is designed to avoid struct padding issues. All multi-byte integers are little-endian. Implementations in C/Rust should use explicit byte-level serialization or `#pragma pack(1)` / `#[repr(packed)]` to ensure correct layout.

**Sparse Index** (for O(log n) seeking):

Every 256th hash is stored uncompressed with its byte offset into the encoded data section:
```
Entry 0:   [hash_0 (20 bytes)] [offset_0 (8 bytes, little-endian)]
Entry 1:   [hash_256 (20 bytes)] [offset_256 (8 bytes)]
Entry 2:   [hash_512 (20 bytes)] [offset_512 (8 bytes)]
...
```

Each sparse index entry is 28 bytes. The hash stored is the full suffix (after prefix stripping), represented as a 160-bit big-endian integer in 20 bytes.

**Encoded Data** (Golomb-Rice compressed deltas):

Hashes are sorted numerically (as big-endian 160-bit integers), prefix-stripped, and delta-encoded:
```
first_hash: 150 bits raw (160 - 10 prefix bits for depth=2)
delta_1:    golomb_rice(hash_2 - hash_1)
delta_2:    golomb_rice(hash_3 - hash_2)
...
```

### 5.2 Golomb-Rice Encoding Mathematics

Golomb-Rice coding efficiently encodes integers drawn from a geometric distribution, which closely matches the distribution of gaps between sorted uniformly-distributed hashes.

**Understanding Gaps (Deltas)**:

The "gap" is the difference between consecutive hashes when sorted numerically. Instead of storing full hash values, we store the first hash and then the gaps between subsequent hashes.

**Example**: Imagine 4 hashes in a space of size 100 (values 0-99):
```
Sorted hashes: [12, 37, 58, 91]

Gaps (deltas):
  37 - 12 = 25
  58 - 37 = 21
  91 - 58 = 33

Storage: [12, 25, 21, 33] instead of [12, 37, 58, 91]
```

The gaps are typically much smaller than full hash values, making them compress more efficiently. Golomb-Rice coding exploits the predictable (geometric) distribution of these gaps.

**Encoding Process**:

For a delta value `d` and parameter `M = 2^k`:

1. Compute quotient: `q = d / M` (integer division)
2. Compute remainder: `r = d % M`
3. Encode `q` in unary: `q` ones followed by a zero
4. Encode `r` in binary: `k` bits

**Example** (M = 256, k = 8):
```
Delta d = 1000
q = 1000 / 256 = 3
r = 1000 % 256 = 232

Encoded: 1110 | 11101000
         ^^^^   ^^^^^^^^
         unary  8-bit remainder
         (q=3)  (r=232)

Total: 4 + 8 = 12 bits
```

**Decoding Process**:
1. Count ones until a zero is encountered → `q`
2. Read next `k` bits as binary → `r`
3. Compute `d = q * M + r`

**Optimal Parameter Selection**:

For `n` uniformly distributed hashes in a space of size `2^b`, the expected gap is:
```
E[gap] = 2^b / n
```

The optimal Golomb parameter is approximately:
```
M_opt ≈ 0.69 * E[gap]
k_opt = floor(log2(M_opt))
```

**Space Analysis**:

For optimal parameter selection, Golomb-Rice achieves approximately:
```
bits_per_item ≈ log2(E[gap]) + 2.5
             = log2(2^b / n) + 2.5
             = b - log2(n) + 2.5
```

For a shard with 1 million items derived from 150-bit hash suffixes:
```
bits_per_item ≈ 150 - 20 + 2.5 = 132.5 bits
```

For a shard with 1,000 items:
```
bits_per_item ≈ 150 - 10 + 2.5 = 142.5 bits
```

**Note**: While this seems large per item, the total file size remains small because we're encoding deltas, not full hashes. A 1000-item shard requires approximately:
```
1000 * 15 bits (average delta) = 15,000 bits ≈ 2 KB
```

## 6. Sharding Depth Selection

The sharding depth determines the trade-off between file count and file size:

| Cache Size | Recommended Depth | Partitions | Avg Items/Partition |
|------------|-------------------|------------|---------------------|
| < 1,000 | 0 | 1 | < 1,000 |
| 1,000 – 100,000 | 1 | 32 | ~3,000 |
| 100,000 – 10M | 2 | 1,024 | ~10,000 |
| 10M – 1B | 3 | 32,768 | ~30,000 |
| > 1B | 4 | 1,048,576 | ~1,000 |

The number of partitions at depth `d` with Nix's 32-character base32 alphabet is `32^d`.

## 7. Client Query Algorithm

```
FUNCTION query(target_hash: string) -> {DEFINITE_HIT, DEFINITE_MISS, PROBABLE_HIT}:

    // Step 1: Fetch and parse manifest (cached)
    manifest = fetch_cached("/nix-cache-index/manifest.json")

    // Step 2: Check journal for recent mutations
    FOR segment IN manifest.journal.segments:
        journal = fetch_cached(segment.path)
        IF "-" + target_hash IN journal:
            RETURN DEFINITE_MISS  // Recently deleted
        IF "+" + target_hash IN journal:
            RETURN PROBABLE_HIT   // Recently added (see note below)

    // Step 3: Determine shard for this hash
    prefix = target_hash[0:manifest.sharding.depth]
    shard_path = format("/nix-cache-index/shards/{}/{}.idx",
                        manifest.epoch.current, prefix)

    // Step 4: Fetch and search shard (cached by epoch)
    shard = fetch_cached(shard_path)
    suffix = parse_hash_suffix(target_hash, manifest.sharding.depth)

    // Step 5: Binary search sparse index
    bracket = binary_search(shard.sparse_index, suffix)

    // Step 6: Decode from bracket position
    position = bracket.offset
    current_hash = bracket.hash

    WHILE current_hash < suffix:
        delta = decode_golomb_rice(shard.data, position)
        current_hash = current_hash + delta

    IF current_hash == suffix:
        RETURN DEFINITE_HIT
    ELSE:
        RETURN DEFINITE_MISS
```

**Note on PROBABLE_HIT**: When an item is found in the journal (recent addition), the algorithm returns `PROBABLE_HIT` rather than `DEFINITE_HIT`. This is because the journal write occurs *after* the artifact upload (per the Write Protocol in Section 4), so a journal entry *implies* the artifact exists. However, `PROBABLE_HIT` accounts for edge cases:

1. **Replication delay**: In multi-region or CDN setups, the index may propagate faster than the artifact storage.
2. **Eventual consistency**: While S3 provides strong read-after-write consistency as of 2020, other "dumb HTTP" backends (mirrors, custom servers) may exhibit lag.
3. **Race conditions**: A tiny window exists between journal write and artifact visibility.

Clients receiving `PROBABLE_HIT` SHOULD proceed to fetch the `.narinfo` file, treating a 404 response as a transient condition worthy of retry rather than a definitive miss.

## 8. Compaction Algorithm

Compaction merges journal entries into shards, producing a new epoch:

```
FUNCTION compact(manifest, old_shards) -> new_shards:

    // Step 0: Rotate to a new journal segment
    // This ensures no writes occur to segments we're about to process
    new_segment_timestamp = rotate_journal_segment()

    // Step 1: Identify segments to compact (all BEFORE the new segment)
    segments_to_compact = get_segments_older_than(new_segment_timestamp)

    // Step 2: Parse all journal mutations from those segments
    additions = {}  // prefix -> set of hashes
    deletions = {}  // prefix -> set of hashes

    FOR segment IN segments_to_compact:
        FOR line IN segment:
            hash = line[1:]
            prefix = hash[0:manifest.sharding.depth]
            IF line[0] == '+':
                additions[prefix].add(hash)
            ELSE:
                deletions[prefix].add(hash)

    // Step 3: Process each shard independently
    new_epoch = manifest.epoch.current + 1

    FOR prefix IN all_prefixes(manifest.sharding.depth):
        old_hashes = decode_shard(old_shards[prefix])

        // Streaming merge: old + additions - deletions
        new_hashes = sorted(
            (old_hashes | additions[prefix]) - deletions[prefix]
        )

        // Encode new shard
        new_shards[prefix] = encode_shard(new_hashes, manifest.encoding)

    // Step 4: Generate deltas (see Section 10)
    IF manifest.deltas.enabled:
        generate_deltas(old_shards, new_shards, manifest)

    // Step 5: Update manifest (atomic swap)
    manifest.epoch.previous = manifest.epoch.current
    manifest.epoch.current = new_epoch
    manifest.journal.current_segment = new_segment_timestamp

    // Step 6: Delete compacted journal segments
    // Safe because nothing is writing to these anymore
    delete_segments(segments_to_compact)

    RETURN new_shards
```

**Handling Concurrent Writes**:

The critical insight is Step 0: by rotating to a new journal segment *before* reading, we ensure that:
- All new writes go to the new segment (which we won't touch)
- All segments we read are "frozen" — no new writes will occur
- No mutex or lock is required; this works with dumb storage (S3)

This avoids the race condition where a write occurs to a segment while we're reading it, which could cause data loss when we delete the segment after compaction.

**Critical Property**: Compaction requires NO access to the underlying storage (S3). The index is self-sufficient and serves as the authoritative source of truth for membership. After the initial bootstrap (which requires enumerating existing items once), no storage listing is ever needed again.

## 9. Epoch Transition and Grace Period

To prevent race conditions during compaction, servers MUST maintain both the current and previous epoch shards for a defined grace period.

### 9.1 The Race Condition Problem

Without a grace period, the following race can occur:

```
T+0ms:    Client fetches manifest.json, sees epoch: 41
T+100ms:  Server completes compaction to epoch 42
T+101ms:  Server updates manifest.json to epoch: 42
T+102ms:  Server deletes shards/41/ directory
T+500ms:  Client requests shards/41/b6.idx
T+501ms:  Client receives 404 Not Found
```

The client read a valid manifest but could not fetch the shards it referenced.

### 9.2 Grace Period Requirements

**Server Requirements**:

1. The manifest MUST include both `epoch.current` and `epoch.previous` fields.
2. Shards for `epoch.previous` MUST remain available for a **minimum grace period** of:
   ```
   grace_period >= 2 × manifest_ttl + max_request_duration
   ```
   For typical values (manifest TTL = 120s, max request = 30s):
   ```
   grace_period >= 2 × 120 + 30 = 270 seconds (4.5 minutes)
   ```
3. Servers SHOULD retain previous epoch shards for at least **10 minutes** to provide margin.
4. Shards for epochs older than `epoch.previous` MAY be deleted immediately.

**Client Requirements**:

1. Clients MUST first attempt to fetch shards from `epoch.current`.
2. If a shard fetch returns 404 AND `epoch.previous` exists in manifest:
   - Client SHOULD retry using `epoch.previous`
   - Client SHOULD refresh the manifest before subsequent queries
3. If both epochs return 404, client SHOULD refresh manifest and retry once.
4. Persistent 404s after manifest refresh indicate a server-side issue or deleted content.

### 9.3 Compaction Lifecycle

```
Phase 1: Pre-Compaction
  shards/41/  (current)
  manifest.json: { epoch: { current: 41, previous: 40 } }

Phase 2: Write New Epoch
  shards/41/  (still current)
  shards/42/  (being written, not yet referenced)

Phase 3: Atomic Manifest Update
  shards/41/  (now previous)
  shards/42/  (now current)
  manifest.json: { epoch: { current: 42, previous: 41 } }

Phase 4: Cleanup (after grace period)
  shards/40/  (deleted, no longer referenced)
  shards/41/  (retained as previous)
  shards/42/  (current)
```

### 9.4 Structural Parameter Changes

Structural parameters (`sharding.depth`, `encoding.parameter`) are expected to remain stable for the lifetime of a cache. However, if an operator needs to change these parameters (e.g., increasing depth as the cache grows), special handling is required.

**The Problem**:

If structural parameters change between epochs, the grace period mechanism breaks:

```
Epoch 41 (depth=0): shards/41/root.idx
Epoch 42 (depth=2): shards/42/00.idx, shards/42/01.idx, ...

Client with stale manifest tries: shards/41/b6.idx → 404!
```

**Requirements for Structural Changes**:

1. Structural changes MUST reset `deltas.oldest_base` to the new epoch (deltas cannot span structural boundaries).
2. The previous epoch MUST be retained with its original structure for the grace period.
3. Clients encountering a structure mismatch (e.g., expected shard file returns 404) SHOULD refresh the manifest and download the current epoch in full.
4. Operators SHOULD treat structural changes as major events requiring extended grace periods (RECOMMENDED: 1 hour minimum).

## 10. Differential Updates

For large caches, downloading full shard files on every epoch change is bandwidth-intensive. Differential updates allow clients to download only the changes between epochs.

### 10.1 The Bandwidth Problem

For cache.nixos.org with ~1.06 billion items (as of January 2026):
- Full index size: ~1.5 GB
- Typical epoch frequency: Daily
- Typical daily churn: ~0.1% (~1M items)

Without differential updates, a client syncing daily downloads **~1.5 GB/day**. With differential updates, the same client downloads only the delta: **~15-20 MB/day** — a ~100x reduction.

### 10.2 Delta File Format

**Path Pattern**: `/nix-cache-index/deltas/<from_epoch>-<to_epoch>/<prefix>.delta`

Delta files use a simple line-oriented format listing the operations needed to transform the source epoch shard into the target epoch shard:

```
# Example: deltas/41-42/b6.delta
# Operations are sorted by hash for efficient streaming application
-b6a1c2d3e4f5g6h7i8j9k0l1m2n3o4p5
-b6f7g8h9i0j1k2l3m4n5o6p7q8r9s0t1
+b6x9y8z7w6v5u4t3s2r1q0p9o8n7m6l5
+b6z1a2b3c4d5e6f7g8h9i0j1k2l3m4n5
```

- Lines beginning with `-` indicate hashes present in epoch N but absent in epoch N+1
- Lines beginning with `+` indicate hashes absent in epoch N but present in epoch N+1
- Operations MUST be sorted by hash (lexicographically) for efficient streaming merge
- Empty delta files (no changes to that shard) MAY be omitted entirely

**Compression**: Delta files SHOULD be served with compression. The manifest field `deltas.compression` indicates the algorithm:
- `none`: No compression
- `zstd`: Zstandard compression (`.delta.zst`) — RECOMMENDED for best ratio/speed

### 10.3 Checksum Files

To verify correct reconstruction, servers provide checksums for each epoch's shards:

**Path**: `/nix-cache-index/deltas/checksums/<epoch>.json`

```json
{
  "epoch": 42,
  "algorithm": "xxh64",
  "shards": {
    "00": {
      "checksum": "a1b2c3d4e5f6g7h8",
      "item_count": 586234,
      "size_bytes": 892156
    },
    "01": {
      "checksum": "b2c3d4e5f6g7h8i9",
      "item_count": 591052,
      "size_bytes": 901234
    },
    "b6": {
      "checksum": "f6g7h8i9j0k1l2m3",
      "item_count": 578921,
      "size_bytes": 878432
    }
  }
}
```

Clients MUST verify the checksum after reconstructing a shard from deltas. On mismatch, clients SHOULD fall back to downloading the full shard.

### 10.4 Client Update Algorithm

```
FUNCTION update_local_index(local_epoch, manifest):
    remote_epoch = manifest.epoch.current

    IF local_epoch == remote_epoch:
        RETURN  // Already current

    IF NOT manifest.deltas.enabled:
        download_full_epoch(remote_epoch)
        RETURN

    IF local_epoch < manifest.deltas.oldest_base:
        // Too far behind, deltas not available
        download_full_epoch(remote_epoch)
        RETURN

    // Apply deltas sequentially
    current = local_epoch
    WHILE current < remote_epoch:
        next = current + 1

        FOR prefix IN all_prefixes(manifest.sharding.depth):
            delta_path = format("/nix-cache-index/deltas/{}-{}/{}.delta",
                               current, next, prefix)

            delta = fetch(delta_path)  // May be 404 if no changes
            IF delta EXISTS:
                apply_delta(local_shards[prefix], delta)

        // Verify reconstruction
        checksums = fetch(format("/nix-cache-index/deltas/checksums/{}.json", next))
        FOR prefix, expected IN checksums.shards:
            actual = xxh64(local_shards[prefix])
            IF actual != expected.checksum:
                // Reconstruction failed, fall back to full download
                download_shard(next, prefix)

        current = next

    local_epoch = remote_epoch
```

### 10.5 Delta Chaining

Clients that are multiple epochs behind apply deltas sequentially:

```
Client at epoch 38, current is 42:
  1. Fetch and apply deltas/38-39/*.delta
  2. Verify against checksums/39.json
  3. Fetch and apply deltas/39-40/*.delta
  4. Verify against checksums/40.json
  5. Fetch and apply deltas/40-41/*.delta
  6. Verify against checksums/41.json
  7. Fetch and apply deltas/41-42/*.delta
  8. Verify against checksums/42.json
  9. Done: client now at epoch 42
```

**Chain Length Limit**: To prevent excessive sequential fetches, clients SHOULD fall back to full download if `remote_epoch - local_epoch` exceeds a threshold (RECOMMENDED: 30 epochs).

### 10.6 Delta Retention Policy

Delta retention is at the discretion of cache operators. The manifest field `deltas.oldest_base` advertises the oldest epoch from which deltas are available, allowing clients to determine whether differential updates are possible.

**Operator Guidance (Non-Normative)**:

| Cache Scale | Suggested Retention | Rationale |
|-------------|---------------------|-----------|
| Small (<10K items) | 7-14 epochs | Minimal storage cost; covers typical laptop-offline scenarios |
| Medium (10K-10M) | 30-60 epochs | Balances storage with team/CI sync patterns |
| Large (>10M items) | 90-180 epochs | Accommodates infrequent users; storage is negligible relative to artifact size |

Operators SHOULD consider their users' typical sync frequency. A cache serving CI systems that sync hourly needs less retention than one serving developers who may go weeks between syncs.

**Storage Analysis**:

Delta files compress extremely well since they contain sorted hashes:
```
Raw delta (10 MB/day × 180 days)  = 1.8 GB
Compressed with zstd              = ~300-500 MB
```

For cache.nixos.org storing hundreds of terabytes of NARs, this overhead is negligible.

### 10.7 Server-Side Delta Generation

During compaction, servers generate deltas by comparing old and new shards:

```
FUNCTION generate_deltas(old_shards, new_shards, manifest):
    old_epoch = manifest.epoch.current
    new_epoch = old_epoch + 1

    FOR prefix IN all_prefixes(manifest.sharding.depth):
        old_hashes = decode_shard(old_shards[prefix])
        new_hashes = decode_shard(new_shards[prefix])

        deletions = old_hashes - new_hashes
        additions = new_hashes - old_hashes

        IF deletions OR additions:
            delta_path = format("deltas/{}-{}/{}.delta", old_epoch, new_epoch, prefix)
            write_delta(delta_path, deletions, additions)

    // Generate checksums for new epoch
    checksums = {}
    FOR prefix IN all_prefixes(manifest.sharding.depth):
        checksums[prefix] = {
            "checksum": xxh64(new_shards[prefix]),
            "item_count": count_items(new_shards[prefix]),
            "size_bytes": size_bytes(new_shards[prefix])
        }
    write_json(format("deltas/checksums/{}.json", new_epoch), checksums)

    // Prune old deltas beyond retention window
    oldest_to_keep = new_epoch - manifest.deltas.retention_epochs
    delete_deltas_older_than(oldest_to_keep)
    manifest.deltas.oldest_base = max(manifest.deltas.oldest_base, oldest_to_keep)
```

## 11. File Layout Summary

```
/nix-cache-index/
├── manifest.json
├── journal/
│   ├── 1705147200.log
│   ├── 1705147500.log
│   └── 1705147800.log           (current)
├── shards/
│   ├── 41/                      (previous epoch, retained for grace period)
│   │   ├── 00.idx
│   │   ├── 01.idx
│   │   └── ...
│   └── 42/                      (current epoch)
│       ├── 00.idx
│       ├── 01.idx
│       ├── ...
│       ├── b6.idx
│       └── ff.idx
└── deltas/                      (differential updates)
    ├── 35-36/
    │   ├── 00.delta.zst
    │   ├── 01.delta.zst
    │   └── ...
    ├── 36-37/
    │   └── ...
    ├── ...
    ├── 41-42/
    │   ├── 00.delta.zst
    │   ├── 01.delta.zst
    │   └── ...
    └── checksums/
        ├── 36.json
        ├── 37.json
        ├── ...
        └── 42.json
```

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

## Example 1: Small Homelab Cache (~500 items)

**Manifest Configuration**:
```json
{
  "version": 1,
  "format": "hlssi",
  "created_at": "2026-01-13T12:00:00Z",
  "item_count": 487,
  "sharding": {
    "depth": 0,
    "alphabet": "0123456789abcdfghijklmnpqrsvwxyz"
  },
  "encoding": {
    "type": "golomb-rice",
    "parameter": 6,
    "hash_bits": 160,
    "prefix_bits": 0
  },
  "journal": {
    "current_segment": 1705147200,
    "segment_duration_seconds": 3600,
    "retention_count": 24
  },
  "epoch": { "current": 3, "previous": 2 },
  "deltas": {
    "enabled": true,
    "oldest_base": 1,
    "compression": "zstd"
  }
}
```

**File Structure**:
```
/nix-cache-index/
├── manifest.json          (~400 bytes)
├── journal/
│   └── 1705147200.log     (~50 bytes, 2 recent pushes)
├── shards/
│   ├── 2/
│   │   └── root.idx       (~8 KB, previous epoch)
│   └── 3/
│       └── root.idx       (~8 KB, current epoch)
└── deltas/
    ├── 1-2/
    │   └── root.delta.zst (~100 bytes)
    ├── 2-3/
    │   └── root.delta.zst (~50 bytes)
    └── checksums/
        ├── 2.json
        └── 3.json
```

**Client Workflow**:
```
1. Client wants to check: b6gvzjyb2pg0kjfwn6a6llj3k1bq6dwi
2. Fetch manifest.json (400 bytes, cached 60s)
3. Fetch journal/1705147200.log (50 bytes)
   - Hash not in journal
4. Fetch shards/3/root.idx (8 KB, cached until epoch changes)
5. Binary search in shard
6. Result: DEFINITE_MISS

Total bandwidth: ~8.5 KB (first query), 50 bytes (subsequent, same session)
Latency: 1 HTTP request (shard cached from previous query)
```

## Example 2: Large Public Cache (~100M items)

**Manifest Configuration**:
```json
{
  "version": 1,
  "format": "hlssi",
  "created_at": "2026-01-13T12:00:00Z",
  "item_count": 98452103,
  "sharding": {
    "depth": 2,
    "alphabet": "0123456789abcdfghijklmnpqrsvwxyz"
  },
  "encoding": {
    "type": "golomb-rice",
    "parameter": 8,
    "hash_bits": 160,
    "prefix_bits": 10
  },
  "journal": {
    "current_segment": 1705147200,
    "segment_duration_seconds": 300,
    "retention_count": 12
  },
  "epoch": { "current": 156, "previous": 155 },
  "deltas": {
    "enabled": true,
    "oldest_base": 66,
    "compression": "zstd"
  }
}
```

**Shard Statistics**:
- Total partitions: 32² = 1,024
- Average items per shard: ~96,000
- Average shard size: ~180 KB
- Full index size: ~180 MB

**Client Workflow**:
```
1. Client wants to check: b6gvzjyb2pg0kjfwn6a6llj3k1bq6dwi
2. Fetch manifest.json (500 bytes, cached 60s)
3. Fetch recent journal segments (~200 KB total for 12 segments)
   - Hash not in journals
4. Compute prefix: "b6"
5. Fetch shards/156/b6.idx (~180 KB, cached until epoch changes)
6. Binary search sparse index → find bracket
7. Decode Golomb-Rice from bracket until hash found or exceeded
8. Result: DEFINITE_HIT

Total bandwidth: ~380 KB (first query for "b6" prefix)
Subsequent "b6" queries: ~0 bytes (fully cached)
Latency: 1-2 HTTP requests
```

## Example 3: CI/CD Push with Immediate Visibility

**Timeline**:
```
T+0.0s:  CI job completes, uploads artifact to S3
T+0.1s:  CI appends "+abc123..." to current journal segment
T+0.2s:  Journal segment synced to storage
T+0.5s:  Downstream client queries for abc123...
T+0.6s:  Client fetches journal, finds "+abc123..."
T+0.7s:  Client returns PROBABLE_HIT, fetches .narinfo
T+0.8s:  Download begins

Visibility latency: <1 second
```

**Note**: The client receives `PROBABLE_HIT` (not `DEFINITE_HIT`) because the entry was found in the journal rather than a compacted shard. This is semantically correct—the artifact *should* exist, but the client will verify by fetching the actual `.narinfo`.

## Example 4: Garbage Collection Without S3 Listing

**Initial State**:
```
Epoch 41 shards contain 1,000,000 items
Journal contains:
  +new1, +new2, +new3 (3 additions)
  -old1, -old2, ..., -old50000 (50,000 deletions from GC)
```

**Compaction Process**:
```
1. Rotate journal segment (new writes go to new segment)
2. Load epoch 41 shard for prefix "ab" (contains ~1000 items)
3. Parse frozen journal segments:
   - Additions for "ab": 0
   - Deletions for "ab": 487 items
4. Streaming merge:
   old_items = decode(ab.idx)           # ~1000 items
   new_items = old_items - deletions    # ~513 items
5. Encode new shard:
   encode(new_items) → ab.idx           # ~half the size
6. Write to epoch 42
7. Generate delta:
   deltas/41-42/ab.delta contains 487 deletion lines
8. Delete frozen journal segments (safe, nothing writing to them)

No S3 LIST operation required.
Index shrinks proportionally to deletions.
```

## Example 5: Multi-Cache Federation

**Configuration** (client-side):
```nix
substituters = [
  "https://private.company.com"      # Private cache (small)
  "https://nix-community.cachix.org" # Community cache (medium)
  "https://cache.nixos.org"          # Official cache (massive)
];
```

**Optimal Query Strategy**:
```
For store path hash H:

1. Fetch private cache index (~10 KB total)
   → Check all paths against single shard
   → Build set of DEFINITE_MISS paths

2. For remaining paths, fetch community cache index
   → Only fetch relevant shards
   → Build set of paths to fetch from community

3. For still-remaining paths, fetch official cache index
   → Only fetch relevant shards
   → Determine final build-vs-fetch decision

Result: Minimal bandwidth, optimal cache utilization
```

## Example 6: Sparse Index Lookup

**Scenario**: Searching for hash `b6gvzjyb2pg0kjfwn6a6llj3k1bq6dwi` in a shard with 10,000 items.

**Sparse Index** (every 256th hash):
```
Entry 0:  [b6000...000] @ offset 0
Entry 1:  [b6032...8a1] @ offset 4102
Entry 2:  [b6064...c72] @ offset 8245
...
Entry 38: [b6gqs...f21] @ offset 155892
Entry 39: [b6hc2...a83] @ offset 160021
```

**Search Process**:
```
1. Target suffix: gvzjyb2pg0kjfwn6a6llj3k1bq6dwi
2. Binary search sparse index:
   - Entry 38: b6gqs... < b6gvz... ✓
   - Entry 39: b6hc2... > b6gvz... ✓
   - Bracket found: [38, 39]

3. Seek to offset 155892
4. Start with hash b6gqs...f21
5. Decode deltas:
   - delta_1 = 42391 → b6gvh...
   - delta_2 = 18293 → b6gvr...
   - delta_3 = 7284  → b6gvz... ← MATCH!

6. Return DEFINITE_HIT

Decoded entries: 3 (out of 256 in bracket)
```

## Example 7: Epoch Transition Race Condition Handling

**Scenario**: Client encounters a 404 during epoch transition.

**Timeline**:
```
T+0ms:    Client fetches manifest: { epoch: { current: 41, previous: 40 } }
T+50ms:   Server starts compaction to epoch 42
T+100ms:  Server finishes writing shards/42/
T+101ms:  Server updates manifest: { epoch: { current: 42, previous: 41 } }
T+200ms:  Client requests shards/41/b6.idx (based on stale manifest)
T+201ms:  Server returns 200 OK (epoch 41 retained as previous)
T+300ms:  Client completes query successfully
```

**Alternate Timeline** (without grace period, showing the problem):
```
T+0ms:    Client fetches manifest: { epoch: { current: 41 } }
T+50ms:   Server completes compaction, deletes shards/41/
T+200ms:  Client requests shards/41/b6.idx
T+201ms:  Server returns 404 Not Found
T+202ms:  Client must refresh manifest and retry (wasted round-trip)
```

## Example 8: Differential Update for Weekly Sync

**Scenario**: Developer laptop was offline for a week, needs to sync with cache.nixos.org.

**Initial State**:
```
Local epoch: 149
Remote manifest: { epoch: { current: 156, previous: 155 },
                   deltas: { oldest_base: 66 } }
Epochs behind: 7
```

**Update Process**:
```
1. Check: 149 >= 66 (oldest_base)? Yes, deltas available

2. For each epoch transition (149→150, 150→151, ..., 155→156):
   a. Fetch delta files for changed shards
   b. Apply deletions and additions
   c. Verify checksums

3. Bandwidth calculation:
   - 7 days × ~0.1% daily churn × 1.5 GB index ≈ 10 MB of changes
   - With zstd compression: ~3 MB total

4. Compare to full download: 1.5 GB

Result: ~500x bandwidth reduction
```

**Detailed Fetch Sequence**:
```
GET /nix-cache-index/deltas/149-150/b6.delta.zst  (if changed)
GET /nix-cache-index/deltas/149-150/a1.delta.zst  (if changed)
... (only shards that changed)
GET /nix-cache-index/deltas/checksums/150.json
(verify checksums)
... repeat for 150-151, 151-152, etc.
```

## Example 9: Client Too Far Behind for Deltas

**Scenario**: A machine was shelved for 6 months, now reconnecting.

**State**:
```
Local epoch: 20
Remote manifest: { epoch: { current: 156 }, deltas: { oldest_base: 66 } }
```

**Decision Process**:
```
1. Check: 20 >= 66 (oldest_base)? No
2. Deltas not available for epoch 20
3. Fall back to full shard download
4. Download shards/156/*.idx (~1.5 GB)
5. Update local epoch to 156
```

This is the expected behavior for clients that haven't synced in a very long time.

# Drawbacks
[drawbacks]: #drawbacks

## 1. Additional Infrastructure Complexity

Cache operators must run a compaction process (cron job or similar) to maintain the index. This adds operational burden compared to the current zero-maintenance model.

**Mitigation**: Provide reference implementations as NixOS modules and container images.

## 2. Index Staleness Window

There is an inherent delay between when an artifact is pushed and when the index reflects it. With 5-minute journal segments, the worst-case staleness is ~5 minutes for clients that don't fetch the current journal.

**Mitigation**: Clients SHOULD always fetch the current journal segment with a short cache TTL.

## 3. Privacy Concerns

Unlike Bloom filters, the HLSSI format stores actual hashes, allowing enumeration of cache contents. This may be undesirable for private caches.

**Mitigation**:
- For truly private caches, consider HMAC-transforming hashes with a shared secret
- Or accept this as a reasonable trade-off given that `.narinfo` URLs are already guessable
- The latency of a non-indexed binary cache may be acceptable.
- Critical private caches should require authentication. Authorization may be simple, or rely on HMAC instead.

## 4. Client Implementation Effort

Existing Nix clients must be modified to support this protocol. Until adoption is widespread, cache operators must maintain backward compatibility.

**Mitigation**: Design the protocol to be purely additive—index files don't interfere with existing cache access patterns.

## 5. Storage Overhead

The index adds ~10-15 bits per item of storage overhead.

**Calculation for cache.nixos.org** (~1.06 billion objects as of January 2026):
```
Index overhead = 1,064,244,619 * 12 bits ≈ 1.5 GB
```

For cache.nixos.org storing ~720 TiB of NARs, this overhead is negligible (~0.0002%).

## 6. Initial Bootstrap Requirement

New caches adopting this protocol must enumerate existing items once to seed the index. For large existing caches without a separate metadata database, this requires an S3 LIST operation.

**Clarification**: This one-time bootstrap cost is identical for any indexing solution (including Bloom filters). The key advantage of HLSSI is that *ongoing maintenance* never requires storage listing—only the initial seed.

**Note**: For cache.nixos.org specifically, the Hydra `buildstepoutputs` table already tracks ~99.5% of all narinfos in the bucket, potentially enabling bootstrap without a full S3 LIST operation. See the [garbage collection discussion](https://discourse.nixos.org/t/garbage-collecting-cache-nixos-org/74249) for details.

## 7. Delta Storage Overhead

Maintaining differential updates requires additional storage for delta files and checksums.

**Analysis for cache.nixos.org with 180-day retention**:
```
Raw deltas: 180 days × ~10 MB/day = 1.8 GB
Compressed (zstd): ~300-500 MB
Checksums: 180 × ~100 KB = ~18 MB
Total: ~500 MB
```

For cache.nixos.org storing ~720 TiB of NARs, this overhead is negligible.

# Alternatives
[alternatives]: #alternatives

## Alternative A: Hierarchical Bloom Filter Forest (HBFF)

### Description

Use probabilistic Bloom filters instead of deterministic hash storage. Partition filters by hash prefix and maintain a journal for freshness.

### Bloom Filter Mathematics

A Bloom filter is a bit array of `m` bits with `k` hash functions. For `n` items, the false positive probability is:

```
p ≈ (1 - e^(-kn/m))^k
```

Optimal number of hash functions:
```
k_opt = (m/n) * ln(2) ≈ 0.693 * (m/n)
```

At optimal `k`, the false positive rate simplifies to:
```
p ≈ (0.6185)^(m/n)
```

**Space requirement for target false positive rate**:
```
m = -n * ln(p) / (ln(2))²
```

| False Positive Rate | Bits per Item | Hash Functions |
|--------------------:|:-------------:|:--------------:|
| 1% | 9.6 | 7 |
| 0.1% | 14.4 | 10 |
| 0.01% | 19.2 | 14 |

### Why HBFF Was Rejected

**The Deletion Problem**:

Bloom filters cannot support true deletion. When an item is removed:
1. You cannot unset its bits (they may be shared with other items)
2. Tombstone lists grow unboundedly
3. False positive rate degrades over time

**Eventually, you need to rebuild from scratch**:
```
To build a clean Bloom filter, you need the exact set of current items.
The Bloom filter itself cannot tell you this (it's lossy).
Therefore, you must LIST the storage backend.
```

This violates the core constraint: **no S3 listing for ongoing maintenance**.

**Quantitative Comparison**:

| Metric | HBFF (Bloom) | HLSSI (This RFC) |
|--------|--------------|------------------|
| Bits per item | ~10 (at 1% FPR) | ~12 |
| Client verification needed | Yes (false positives) | No (exact) |
| Supports deletion | No (needs rebuild) | Yes (native) |
| S3 LIST required | Yes (periodic) | Never (after bootstrap) |
| Implementation complexity | Low | Medium |

### Verdict

HBFF trades ~2 bits per item for an operational dependency that violates our constraints. The marginal space savings do not justify the architectural fragility.

## Alternative B: Sorted Hash Lists (Uncompressed)

### Description

Store hashes as sorted, uncompressed lists. Use binary search for queries.

### Space Analysis

Each hash is 32 characters = 160 bits = 20 bytes.

For 1 billion items:
```
Uncompressed size = 1,000,000,000 * 20 bytes = 20 GB
```

With sharding depth 3 (32,768 partitions):
```
Average shard size = 20 GB / 32,768 = 625 KB
```

### Why Rejected

While simpler to implement, the space overhead is substantial:
- 20 bytes/item vs ~1.5 bytes/item with Golomb-Rice
- ~13x more bandwidth for clients
- ~13x more storage for operators

The implementation complexity of Golomb-Rice is justified by the space savings.

## Alternative C: Counting Bloom Filters

### Description

Use 4-bit counters instead of single bits to support deletion.

### Space Analysis

Counting Bloom filters require 4 bits per bucket instead of 1:
```
Space overhead = 4x standard Bloom filter
              = 4 * 10 bits/item
              = 40 bits/item
```

### Why Rejected

- 3x larger than HLSSI
- Still probabilistic (false positives)
- Counter overflow is possible under adversarial workloads
- Does not eliminate S3 listing for periodic cleanup/rebuild

## Alternative D: Cuckoo Filters

### Description

Cuckoo filters store fingerprints with cuckoo hashing, supporting deletion.

### Characteristics

- Space: ~12 bits per item at 3% FPR
- Supports deletion
- Lower false positive rate than Bloom at same space

### Why Rejected

1. **Insertion failure**: Cuckoo filters can fail to insert when load factor is high, requiring a full rebuild
2. **Implementation complexity**: More complex than HLSSI with no clear benefit
3. **Still probabilistic**: Requires HTTP verification on positive results

## Alternative E: Do Nothing

### Impact of Inaction

The current poll-and-pray model will continue to:
- Waste bandwidth on cache misses
- Impose unnecessary latency on builds
- Generate excess load on cache backends
- Prevent effective multi-cache federation

As the Nix ecosystem grows and more organizations run private caches, these inefficiencies will compound.

# Prior art
[prior-art]: #prior-art

## Bitcoin BIP-158: Compact Block Filters

Bitcoin uses Golomb-Rice coded sets (GCS) for light client block filtering. BIP-158 demonstrated that GCS is practical for large-scale membership testing in distributed systems.

**Key differences**:
- BIP-158 uses a fixed false positive rate (probabilistic)
- This RFC uses exact encoding (deterministic)
- BIP-158 encodes transaction outpoints; we encode store path hashes

**Learnings applied**: The choice of Golomb parameter significantly impacts compression ratio. We adopt the same optimization approach.

## LevelDB/RocksDB SSTable Format

Log-structured merge trees use sorted string tables for bulk data storage. Our shard format borrows concepts:
- Sorted keys with delta encoding
- Sparse index for efficient seeking
- Immutable files with epoch-based compaction

**Key differences**:
- LSM trees optimize for key-value storage; we optimize for membership testing
- LSM trees support range queries; we only need point queries
- Our "values" are implicit (presence = membership)

## nix-index Project

[nix-index](https://github.com/nix-community/nix-index) builds a local database of file-to-package mappings by querying cache.nixos.org for every package.

**Limitations addressed by this RFC**:
- nix-index requires querying each package individually
- It cannot determine cache membership without network access
- It doesn't support private caches or multi-cache federation

## Web Search: Inverted Index Compression

Search engines use similar techniques for posting list compression:
- Delta encoding of document IDs
- Variable-byte and Golomb coding
- Partitioning by term frequency

Our approach applies these techniques to a simpler domain (membership testing vs. ranked retrieval).

## Content Delivery Networks: Manifest Files

CDNs commonly use manifest files to describe available content:
- HLS/DASH use manifests for video segment discovery
- Package managers (apt, yum) use compressed package lists
- Container registries use manifest lists for multi-architecture images

This RFC follows the same pattern: a manifest describing index topology with efficient lookup structures.

## Rsync and Binary Delta Algorithms

The differential update mechanism draws inspiration from:
- rsync's rolling checksum algorithm for efficient file synchronization
- bsdiff/xdelta for binary patching
- Git's packfile delta compression

Our approach uses a simpler line-oriented format because the source data (sorted hashes) is already highly structured, making sophisticated binary diffing unnecessary.

## Hydra buildstepoutputs Table

The Hydra CI system maintains a `buildstepoutputs` table tracking store paths it has built. As of January 2026, this table covers ~99.5% of narinfos in cache.nixos.org. This demonstrates the viability of maintaining authoritative membership state outside of storage listing, and could serve as a bootstrap source for cache.nixos.org's HLSSI index.

# Unresolved questions
[unresolved]: #unresolved-questions

## 1. Golomb Parameter Selection Heuristics

What is the optimal strategy for selecting the Golomb parameter across different cache sizes and shard densities? Should it be:
- Fixed globally (simplest)
- Per-shard based on item count (optimal compression)
- Dynamically tuned during compaction

**Recommendation**: Start with a fixed parameter (k=8) and allow per-shard optimization in future versions.

## 2. Journal Segment Size Limits

Should journal segments have a maximum size limit? What happens if a CI system pushes 100,000 artifacts in 5 minutes?

**Recommendation**: Allow segments to grow unbounded but trigger early rotation at a configurable threshold (e.g., 10,000 entries).

## 3. Backward Compatibility Path

How should cache operators transition from no-index to indexed caches? Options:
- Manual opt-in via configuration
- Automatic index generation on first compaction
- Nix client version negotiation

**Recommendation**: Opt-in via presence of `manifest.json`. Clients that don't find it fall back to current behavior.

## 4. Index Integrity Verification

How should clients handle corrupted or malicious index files? Options:
- External signature file
- HTTP-level integrity (`ETag`, TLS)
- Treat index as advisory only (fall back to HTTP on any discrepancy)

**Recommendation**: Treat index as advisory. On any parse error or inconsistency, fall back to standard HTTP probing. Cryptographic signing is deferred to future work.

## 5. Build traces (CA realisations)

(Note: CA realisations are getting renamed to build traces)
In the current implementation of content addressing derivations in the binary cache, realisations (= build traces) are stored in a separate directory.
Either a separate index could be created for build traces, or they could be mapped into the same index.
A client knows whether it it wants a realisation or narinfo, and since realisation and narinfo hashes do not collide (probabilistic truth of course), we do not expect any problems there.
Remaining question: does a separate realisation index improve or degrade performance?


# Future work
[future]: #future-work

## 1. Index Signing and Trust

Extend the existing binary cache signing mechanism to cover index files, allowing clients to verify index authenticity before trusting membership results. This would include:
- Defining a signature file format (e.g., `.sig` files)
- Specifying which files are signed (manifest, shards, or both)
- Key distribution and trust model

## 2. Index Mirroring Protocol

Define a protocol for mirroring indices between caches, enabling CDN-style distribution of index files for cache.nixos.org.

## 3. Client-Side Index Caching

Specify standard paths for persistent client-side index caching:
```
~/.cache/nix/indices/<cache-hash>/manifest.json
~/.cache/nix/indices/<cache-hash>/shards/...
```

## 4. Integration with Nix Flake Registries

Explore automatic index URL discovery via flake registries, reducing configuration burden for common caches.

## 5. Compression Algorithm Alternatives

Evaluate alternative compression schemes as they mature:
- ANS (Asymmetric Numeral Systems) for better compression ratios
- SIMD-accelerated decoders for faster queries
- GPU-based batch queries for large dependency closures

## 6. Index-Aware Garbage Collection

Develop GC strategies that use index metadata to make smarter retention decisions:
- Keep items referenced by recent index epochs
- Prioritize deletion of items not queried recently (requires query logging)

## 7. P2P Index Distribution

Explore peer-to-peer distribution of index files and deltas, reducing load on central cache servers. This could leverage protocols like BitTorrent or IPFS for large index distribution.

## 8. Skip Deltas for Common Patterns

For clients that sync at predictable intervals (e.g., weekly), servers could generate "skip deltas" that jump multiple epochs at once:
```
/nix-cache-index/deltas/140-156/  # Skip delta covering 16 epochs
```

This would reduce round-trips for clients with predictable sync patterns, at the cost of additional server-side storage and computation.