---
feature: binary-cache-ipfs
start-date: 2022-03-07
author: lucasew
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: John Ericson, Tom Bereknyei, Kevin Amado
shepherd-leader: Tom Bereknyei
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

In binary caches add an extra property on narinfo to reference the IPFS CID of the nar file

# Motivation
[motivation]: #motivation

IPFS is still not a present reality on the mainstream Nix ecosystem, altough it's not reliable to store long term data, it can reduce bandwith costs for both the servers and the clients but the question is where the NAR file could be obtained in IPFS.

Its not espected that, for example, cache.nixos.org would run a IPFS daemon for seeding but it could just calculate the hash using `ipfs add -nq $file` and provide it on the narinfo so other nodes can figure out alternative places to download the NAR files, even closer than a CDN could be.

Parallel binary caches could arise for regions that internet connectivity is a problem and a local distribution is preferred. If the payload is properly signed it shouldnt be a problem to prove that given path comes originally from given binary cache.

# Detailed design
[design]: #detailed-design

A narinfo file is a file provided by the binary cache server that provides metadata for an existent path in the binary cache. It has information about the nix store path, which compression algorithm is used, hashes, sizes, references, a signature and a relative direct path to download the compressed NAR file.

It has the sha256 hash of the file but from that it's still not possible to find out where to download it on the IPFS network so, to make it possible, the CID is required.

This extra step can be optional so if the cache provider don't provide the IPFS CID it's fine but the provider cannot leverage IPFS to reduce bandwidth costs.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

Today, a narinfo looks like this:

```
StorePath: /nix/store/gdh8165b7rg4y53v64chjys7mbbw89f9-hello-2.10
URL: nar/0i6ardx43rdg24ab1nc3mq7f5ykyiamymh1v37gxdv5xh5cm0cmb.nar.xz
Compression: xz
FileHash: sha256:0i6ardx43rdg24ab1nc3mq7f5ykyiamymh1v37gxdv5xh5cm0cmb
FileSize: 40360
NarHash: sha256:1ddv0iqq47j0awyw7a8dmm8bz71c6ifrliq53kmmsfzjxf3rwvb8
NarSize: 197528
References: 7gx4kiv5m0i7d7qkixq2cwzbr10lvxwc-glibc-2.27 gdh8165b7rg4y53v64chjys7mbbw89f9-hello-2.10
Deriver: 5sj6fdfym58sdaf3r5p87v4l8sj2zlvn-hello-2.10.drv
Sig: cache.nixos.org-1:K0thQEG60rzAK8ZS9f1whb7eRlIshlMDJAm7xvX1oF284H+PTqlicv/wGW6BIj+wWWONHvUZ2MYc+KDArekjDA==
```

This RFC proposes a new key-value pair that in this example would be:

```
IpfsCid: Qmf8NfV2hnq44RoQw9vxmSpGYTwAovA8FUCxeCJCqmXeNN
```

# Drawbacks
[drawbacks]: #drawbacks

It's an extra optional step for each cache entry

# Alternatives
[alternatives]: #alternatives

An alternative way is to use bittorrent, but bittorrent doesn't do file level deduplication so swarms can be easily divided but it's a lot battle proven and has a lot of clients that play well with each other. NARs are only single files so in this case it shouldn't be a problem.

# Unresolved questions
[unresolved]: #unresolved-questions

Who will seed?

IPFS and Nix stores are different things so IPFS would hold a chunked compressed nar file and Nix would hold the nar files extracted in it's stores. This could lead to double the usage of storage.

This RFC is only about easing binary cache propagation from a previously trusted entity (by default the NixOS official cache keys).

Is the signing system used in nix for cache entries robust enough?

# Future work
[future]: #future-work

Nix store integration with IPFS to avoid storing the same thing twice and improve seeder availability

Trustix: finding consensus about what is the right closure of the derivation
