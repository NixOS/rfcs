---
feature: Default name of fetchFromGithub FOD to include revision
start-date: 2024-03-15
author: Jonathan Ringer
co-authors: 
shepherd-team:  
shepherd-leader: 
related-issues:
---

# Summary
[summary]: #summary

Updating the hash on Fixed-Output Derivations (FODs) is a very error prone process. It's not intuitive to invalidate the existing hash, attempt to realize the FOD, then replace the hash value with the value that Nix just calculated. This RFC advocates for influencing the default derivation name of the fetchFromGithub helper with the "repo" and "rev" values to ensure that changed URLs force the FOD to be re-built.

# Motivation
[motivation]: #motivation

This will hopefully provide immediate feedback that an FOD contains a stale hash. One must either build the FOD without the previous FOD in their Nix store, or run the FOD build with `--check` to verify that the FOD is not stale. Although fetchFromGithub is one of many fetchers; it is very common, and generally has a user specify granular source information which makes differentiating between sources easy.

As a secondary effect, this will also give a more meaningful name to the FODs than "source". E.g. `/nix/store/...-source -> /nix/store/...-protobuf-v24.1-src`

# Detailed design
[design]: #detailed-design

Change the default name of fetchFromGithub fetcher from `"source"` to `lib.sanitizeDerivationName "${repo}-${rev}-src"`.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

```
# previous sha256 is still valid
$ nix-build -A nix-template.src --check
checking outputs of '/nix/store/ib74331l6pl6f8s2hsakf68lhg2jsl5i-nix-template-0.1.4-src.drv'...

trying https://github.com/jonringer/nix-template/archive/v0.1.4.tar.gz
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   130  100   130    0     0    425      0 --:--:-- --:--:-- --:--:--   426
100 27955    0 27955    0     0  36653      0 --:--:-- --:--:-- --:--:--  311k
unpacking source archive /build/v0.1.4.tar.gz
/nix/store/lfbgmqvpq5365q5ivv6ccck7xg88syw5-nix-template-0.1.4-src

# explicit commit hash example
$ nix-build -A artyFX.src
this derivation will be built:
  /nix/store/ir4k3n5q7nmb2wh533pq1ma1cabyr8h7-openAV-ArtyFX-8c542627d9-src.drv
building '/nix/store/ir4k3n5q7nmb2wh533pq1ma1cabyr8h7-openAV-ArtyFX-8c542627d9-src.drv'...

trying https://github.com/openAVproductions/openAV-ArtyFX/archive/8c542627d936a01b1d97825e7f26a8e95633f7aa.tar.gz
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   173  100   173    0     0    754      0 --:--:-- --:--:-- --:--:--   755
100  627k    0  627k    0     0   604k      0 --:--:--  0:00:01 --:--:-- 1014k
unpacking source archive /build/8c542627d936a01b1d97825e7f26a8e95633f7aa.tar.gz
/nix/store/dkvcfm90ckrlgmv89s8sr15vcidwlxhs-openAV-ArtyFX-8c542627d9-src
```

# Drawbacks
[drawbacks]: #drawbacks

- All derivations which don't pass a "name" parameter will need to be re-realized
    - This will be a download-intensive one-time cost to realize the new FOD derivations.
    - NAR hash should not need to be recomputed assuming it was deterministic and not stale.
    - Cache should be minimally impacted as NARs are content addressable, thus deterministic sources should not contribute to cache bloat.
    - Potential for sources which are no longer available to be broken.
        - These can have their name manually set to "source" to perserve previous behavior.
        - Ideally source availability would be remedied with more appropriate methods. E.g. being made available.
- "Interchangeability" with other fetchers is diminished as the derivation name is different
    - In practice, fetchFromGitHub is never used in this way. It is generally the only fetcher, so there is never another FOD to dedupilicate.
- Out-of-tree repositories may get hash mismatch errors
    - If the cause of the mismatch is staleness, this is good and working as intended
    - If the cause is non-determinism, this is frustrating.
- Some derivations assume "source" to be the name of sourceRoot
    - This has been mitigated over two years within Nixpkgs
    - Out-of-tree code may break if they assume "source" is the name
        - Can be mitigated with release notes describing the issue

# Alternatives
[alternatives]: #alternatives

- Do nothing. Retain current status quo.

- In https://github.com/NixOS/nixpkgs/pull/153386#issuecomment-1007729116, @Ericson2314 mentioned that this may be solved at the Nix tooling level. And that a year should be give to see if an implementation can be done.
    - That was 2+ years ago, and an ounce of prevention today is worth ten ounces of remedy tomorrow.

# Prior art
[prior-art]: #prior-art

- https://github.com/NixOS/nixpkgs/pull/153386

# Unresolved questions
[unresolved]: #unresolved-questions

- Full commit hashes could be truncated. This sacrifices a bit of simplicity for better looking derivation names:
```
let
  version = builtins.replaceStrings [ "refs/tags/" ] [ "" ] rev;
  # Git commit hashes are 40 characters long, assume that very long versions are version-control labels
  ref = if (builtins.stringLength rev) > 15 then builtins.substring 0 8 version else version;
in lib.sanitizeDerivationName "${repo}-${ref}-src";
```

- Similar treatment to similar fetchFromGitX helpers?

# Future work
[future]: #future-work

- Apply name change to fetchFromGitHub in PR to staging:
    - Resolve stale FODs, most of these can be PRs made against master
    - Resolve assumed usage of "source" as `src.name`, most of these changes can be made against master
    - Revert name to "source" for removed source urls.
- Add release notes for potential breakages when assuming the name of the unpacked directory is "source"

