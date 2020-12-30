---
feature: input-aware-fetchers
start-date: 2020-12-30
author: @infinisil
co-authors: (find a buddy later to help our with the RFC)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Change the name of the main fixed-output derivations to contain a hash of all inputs that could affect the output hash, such that if any of them change, a previously-fetched path with the same hash won't be reused. This resolves the long-standing confusion about Nix using an old version of a source even though the url it should be fetched from was updated.

# Motivation
[motivation]: #motivation

Say we have a `fetchFromGitHub` call like
```nix
(import <nixpkgs> {}).fetchFromGitHub {
  owner = "NixOS";
  repo = "nix";
  rev = "2.3.9";
  sha256 = "0d4c3ddpqa1q4j15cl8d7g3igiw6clqczf8dcp4pbpvlm9a64rki";
}
```

With a current nixpkgs version, this can be built successfully, returning the result in store path
```
/nix/store/l98gjfznp8lpxi0hvj4i0rw34xnnqma8-source
```

However, if we now intuitively update the revision of the expression to the new 2.3.10 release like
```nix
(import <nixpkgs> {}).fetchFromGitHub {
  owner = "NixOS";
  repo = "nix";
  rev = "2.3.10";
  sha256 = "0d4c3ddpqa1q4j15cl8d7g3igiw6clqczf8dcp4pbpvlm9a64rki";
}
```

We can still build this successfully, getting the exact same store path
```
/nix/store/l98gjfznp8lpxi0hvj4i0rw34xnnqma8-source
```

This can't be right! Of course, people with Nix knowledge will tell you that you need to change the hash to something invalid first in order for it to attempt a refetch. This is because Nix already has a path with that exact output `sha256` hash, so it just reuses that. Indeed, changing the output hash to something invalid works:
```nix
(import <nixpkgs> {}).fetchFromGitHub {
  owner = "NixOS";
  repo = "nix";
  rev = "2.3.10";
  sha256 = "0000000000000000000000000000000000000000000000000000";
}
```

Building this we get a hash mismatch as expected:

```
hash mismatch in fixed-output derivation '/nix/store/5d3k20pzgjyccmpqfina1cvbl28zxz6a-source':
  wanted: sha256:0000000000000000000000000000000000000000000000000000
  got:    sha256:1cx9yv62rylfv8p09pidsmqy8qim1bbjaa8pj1j8xj7vkrm0dri1
```

Now we can copy the hash into the expression:
```nix
(import <nixpkgs> {}).fetchFromGitHub {
  owner = "NixOS";
  repo = "nix";
  rev = "2.3.10";
  sha256 = "1cx9yv62rylfv8p09pidsmqy8qim1bbjaa8pj1j8xj7vkrm0dri1";
}
```

And build it successfully to get the correct result in the output path
```
/nix/store/5d3k20pzgjyccmpqfina1cvbl28zxz6a-source
```

It is however very easy to forget to update the hash to something invalid, which as many know has been a source of much confusion, questions and frustration.

However it doesn't have to be this way!

# Detailed design
[design]: #detailed-design

This problem can be solved relatively easily by realizing that Nix not only uses the output hash of derivations to check whether they need to be built, but the _full_ store path, which notably also includes the _derivation name_. Thus, by ensuring that the derivation name changes if (and only if) relevant inputs change, we can force Nix to rebuild a derivation even if the output hash stays the same, therefore fixing above problem.

This RFC therefore proposes to use a hash of all relevant derivation inputs as the name of fixed-output derivations. The hash should be computed using `sha256`, and encoded using the [url-safe base64](https://tools.ietf.org/html/rfc4648#section-5), without any leading `=`, leading to a character count of 43. For reference, this hash can be computed in `nix-shell -p openssl` with
```
[nix-shell:~]$ echo -n 'example string' | openssl dgst -sha256 -binary | openssl base64 -A | cut -b1-42 | tr +/ -_
rt-5KzBTohoRT08wGgKjxq1d_1BNEk3CzuYRdiPuxw
```


The following describes exactly which string should be used as the hash input for each of the fetcher types. This is necessary since there are multiple ways to fetch the same resources, e.g. with the builtin `fetchTarball` and nixpkgs' `fetchzip`. In order for them to be able to reuse the same store path, they should use the same derivation name.

| Fetchers | Input string |
| --- | --- |
| `pkgs.fetchurl`, `<nix/fetchurl.nix>`, `builtins.fetchurl`, `nix-prefetch-url` | "fetchurl-" + first URL |
| `pkgs.fetchzip`, `<nix/fetchurl.nix>` (with `unpack = true`), `builtins.fetchTarball`, `nix-prefetch-url --unpack` | "fetchurl-unpack-" + URL |
| `pkgs.fetchgit`, `builtins.fetchGit` and co. | "fetchgit-" + url + "-" + rev |

Changing the name of a derivation doesn't change its fixed-output hash. Therefore there's no need to update existing fixed-output hashes.

## Example

```nix
(import <nixpkgs> {}).fetchzip {
  url = "mirror://gnupg/gnupg/gnupg-2.2.24.tar.bz2";
  sha256 = "0ilcp7m1dvwnri3i7q9wanf5pvhwxk7h106pd62g0d5fz80b944h";
}
```

yields store path
```
/nix/store/q1nsvfvzqzfsxcdcjnnfrw9cwmr1fb2j-DRzMDNAD89ZITk4wqEOz8oELAfOdOvvBfxE9vSbEDj
```

## Synchronizing Nix and nixpkgs changes

Since this proposal requires changes on both the Nix and nixpkgs side, it should be synchronized between the two, such that both Nix and nixpkgs fetchers always use the same store paths.

To manage this, nixpkgs should condition the change of behavior on `builtins.nixVersion` being above-or-equal the version where the change is done in Nix. Therefore both the previous and the new behavior need to be maintained in nixpkgs until `lib/minver.nix` is increased to the version where the change in Nix occured.

# Drawbacks
[drawbacks]: #drawbacks

- Using only the hash as the derivation name leads to store path names that don't indicate what they contain. This is already the case with the current `/nix/store/l98gjfznp8lpxi0hvj4i0rw34xnnqma8-source` store paths for `fetchzip`, but this RFC would also make it as such for `fetchurl` and `fetchgit`.

# Alternatives
[alternatives]: #alternatives

- The trivial alternative of keeping the status quo. This leads to the common beginner problem described in the motivation section.
- Adding a special `outputHashInputs` attribute to the Nix `derivation` primitive, which can be set to any attributes. These attributes then influence Nix's store path hash directly, without the need for using the derivation name as a hash influencer. This could be a much nicer solution, but is a much more indepth change to how Nix works.
- In order to keep the store path shorter, the `sha256` could be truncated to a shorter length. This was not done in order to not increase the chance of collisions.
- The derivation name could not only contain the hash, but also a descriptive name of the inputs, such as `baseNameOf url`, which is what `fetchurl` currently does. While possible, this is more complicated than just `baseNameOf`, since URLs can also have characters that are invalid in a derivation name (see https://github.com/NixOS/nixpkgs/pull/107515). To keep it simple this was not done.

# Unresolved questions
[unresolved]: #unresolved-questions

- Should the hash be truncated? (see alternatives)
- Should the name also contain a descriptive name of the inputs? (see alternatives)

# Future work
[future]: #future-work

- [Restricting fixed-output derivations](https://github.com/NixOS/nix/issues/2270) would indicate moving all fetchers into Nix itself. Therefore this change wouldn't have to be synchronized across Nix and nixpkgs
