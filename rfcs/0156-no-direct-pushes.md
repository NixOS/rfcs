---
feature: no-direct-pushes
start-date: 2023-07-21
author: Silvan Mosberger
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: (will contain links to implementation PRs)
---

# Summary
[summary]: #summary

Require pull requests for all Nixpkgs commits.

# Motivation
[motivation]: #motivation

There are currently 197 people with commit access to Nixpkgs, all of whom can push directly to any branch without a pull request.
Such pushes generally[^1] do not notify anybody and do not trigger CI.

[^1]: There's no GitHub mechanism that takes care of notifying other people and there's no builtin way to get notified for new commits linked to [the direct push issue](https://github.com/NixOS/nixpkgs/issues/118661), but third-party tooling could be implemented to get notified explicitly for direct pushes

This makes such commits susceptible to:
- Be anonymous[^2]
- Include malicious code
- Be broken
- Have poor code quality

[^2]: GitHub does not require committers to match the pushing GitHub account, [here's](https://github.com/infinisil/github-test/commit/0553a1afe8ee38d45ef38c7055a7b6c3ee08f3d3) an example.

While requiring pull requests isn't a panacea, it does help by:
- Running CI (though there's no requirement for it to succeed, see [future work][future])
- Requesting reviews from [Nixpkgs maintainers](https://github.com/NixOS/rfcs/pull/39) via CI
- Requesting reviews from [code owners](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)
- Tying commits to a GitHub account
- Being discoverable in the pull request list using various filterable and sortable metadata such as (manually and [automatically](https://github.com/NixOS/nixpkgs/blob/e0d40b94732d0a077ea8e409d394bcd36750584e/.github/labeler.yml) assigned) [labels](https://github.com/NixOS/nixpkgs/labels), update time, authors, reviews, etc.


# Detailed design
[design]: #detailed-design

Turn on GitHub's "Require a pull request before merging" [branch protection rule](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/managing-a-branch-protection-rule#creating-a-branch-protection-rule) for all branches whose commits get propagated into channels.
This includes:
- `master`: Used for unstable channels and branched into new release branches
- `release-*`: Used for stable channels

Staging branches are intentionally not included, because they will already require a pull request when they inevitably need to get merged into one of the above branches.
The same applies to similar long-term branches like `haskell-packages`.

A NixOS GitHub organization owner needs to implement this change and should therefore review this proposal.

## Disable the direct push detection workflow

There is a [GitHub Actions workflow to detect directly pushed commits](https://github.com/NixOS/nixpkgs/blob/0b411c1e040870e89a3e598437e708979137b665/.github/workflows/direct-push.yml).
When detected, it creates a comment in the commit pointing out that this is discouraged and linking to [this issue](https://github.com/NixOS/nixpkgs/issues/118661), where it's easy to see all direct pushes.
The script occasionally has false positives[^3], which creates some unnecessary commit comment notifications.

[^3]: https://github.com/NixOS/nixpkgs/issues/240314

With this proposal accepted it won't be possible to directly push commits anymore, making that workflow unnecessary.
It can be removed and the above two issues can be closed.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

## Direct pushes listing

Out of the 112217 commits to master in the last year[^4], _at most_ 58 (0.0517%) of them were direct pushes.

[^4]: Unix epoch 1658361600 to 1689897600

To determine whether a commit was pushed directly, the GitHub API was queried for pull requests associated with that commit (see [`associatedPullRequests`](https://docs.github.com/en/graphql/reference/objects#commit)).
If this list includes a merged pull request to the Nixpkgs master branch, the commit is known to be merged with a pull request.
Otherwise the commit could be directly pushed or be a false positives, which is why the above count is only an upper bound.
All obvious false positives ([example](https://github.com/NixOS/nixpkgs/commit/b09d18903c24b8aca88100df86aa2fdd5f05dfcd)) have been removed from this count and listing already.

<details>
<summary>Complete listing of the 58 potentially directly pushed commits in the last year</summary>

- [`1ce07adbe05e`](https://github.com/NixOS/nixpkgs/commit/1ce07adbe05e36146e6c47dcad4bff1178b8c572) [@trofi](https://github.com/trofi) - mutt: use more ubiquitous "eee-" placeholder instead of one-off <<NIX>>
- [`205ee073b053`](https://github.com/NixOS/nixpkgs/commit/205ee073b053fc4d87d5adf2ebd44ebbef7bca4d) [@vcunat](https://github.com/vcunat) - Revert "texlive.combine: expose licensing information of combined packages"
- [`789271b2c8a4`](https://github.com/NixOS/nixpkgs/commit/789271b2c8a4cc01398316c211b0d597cde8324d) [@vcunat](https://github.com/vcunat) - python3Packages.hickle: fixed failing unit tests
- [`69867f9de40f`](https://github.com/NixOS/nixpkgs/commit/69867f9de40f0d24276eeaf957b36a34541214fe) [@vcunat](https://github.com/vcunat) - transmission: drop myself from .meta.maintainers
- [`82082e931fd7`](https://github.com/NixOS/nixpkgs/commit/82082e931fd7199c929fb7901aac05e54cd1e18c) [@vcunat](https://github.com/vcunat) - vtm: avoid using an alias
- [`62d347770a26`](https://github.com/NixOS/nixpkgs/commit/62d347770a26663db3332d3a04c5084f6a71dd9d) [@ehmry](https://github.com/ehmry) - nimPackages.eris: wontfix darwin
- [`e2ccc3dd9f4d`](https://github.com/NixOS/nixpkgs/commit/e2ccc3dd9f4da160bacf7da8d294b353678d2ce8) [@ehmry](https://github.com/ehmry) - cjdns: mark broken for aarch64
- [`2c28f1de7cdc`](https://github.com/NixOS/nixpkgs/commit/2c28f1de7cdc10be556d2106108411dd2482794b) [@RaitoBezarius](https://github.com/RaitoBezarius) - 23.11 is Tapir
- [`8607b80c8560`](https://github.com/NixOS/nixpkgs/commit/8607b80c85600c2ad439a8a198ff812b15d01c0c) [@sternenseemann](https://github.com/sternenseemann) - haskellPackages.memfd: mark supported on linux only
- [`d925734d3bb7`](https://github.com/NixOS/nixpkgs/commit/d925734d3bb7f12924e6016cd33222684b5435f5) [@ehmry](https://github.com/ehmry) - Nim: add meta.mainProgram
- [`6c43a3495a11`](https://github.com/NixOS/nixpkgs/commit/6c43a3495a11e261e5f41e5d7eda2d71dae1b2fe) [@vcunat](https://github.com/vcunat) - linux\_6\_1: fixup evaluation without aliases
- [`fa8367c2d507`](https://github.com/NixOS/nixpkgs/commit/fa8367c2d50781f3e49ed424ea61af0c77615069) [@vcunat](https://github.com/vcunat) - linux\_6\_1: rebuild on x86\_64-linux
- [`e25dc4a95ed6`](https://github.com/NixOS/nixpkgs/commit/e25dc4a95ed69f37ce443b8fcad00fb9337e6eed) [@jtojnar](https://github.com/jtojnar) - nixos/nginx: Fix listen string generation
- [`331e2a1c1075`](https://github.com/NixOS/nixpkgs/commit/331e2a1c1075d4c3f2660da9210ee54ba93d7bda) [@bjornfor](https://github.com/bjornfor) - prometheus-smokeping-prober: cleanup version
- [`fe2ecaf706a5`](https://github.com/NixOS/nixpkgs/commit/fe2ecaf706a5907b5e54d979fbde4924d84b65fc) [@vcunat](https://github.com/vcunat) - rocm-thunk: evaluate even on unsupported platforms again
- [`7486a74d9f5c`](https://github.com/NixOS/nixpkgs/commit/7486a74d9f5c3581c2db0e186d4763ff3a4ae782) [@vcunat](https://github.com/vcunat) - lisp-modules: avoid the replaced pkgs.webkitgtk\_5\_0
- [`1010c17591db`](https://github.com/NixOS/nixpkgs/commit/1010c17591db2553d4954cc6a143169604f150e4) [@web-flow](https://github.com/web-flow) - python3Packages.tensorflow: remove @jyp from `meta.maintainers`
- [`5a8991c6b34f`](https://github.com/NixOS/nixpkgs/commit/5a8991c6b34fc62793f3996cb4614595d5d13a6c) [@ulrikstrid](https://github.com/ulrikstrid) - Fix dune-configurator
- [`972b0fa87ffc`](https://github.com/NixOS/nixpkgs/commit/972b0fa87ffc622a690461a43c1608bef5b776ee) [@vcunat](https://github.com/vcunat) - xdp-tools: fix hash of the patch
- [`477de8d913e6`](https://github.com/NixOS/nixpkgs/commit/477de8d913e6e9b10ba1bb8c405002cada95e832) [@vcunat](https://github.com/vcunat) - olive-editor: don't use the alias openimageio2
- [`26f55176e776`](https://github.com/NixOS/nixpkgs/commit/26f55176e77696556658c04f2167db02f401d6b5) [@vcunat](https://github.com/vcunat) - Revert #222072: "directx-shader-compiler: remove workaround"
- [`006c8313427e`](https://github.com/NixOS/nixpkgs/commit/006c8313427efae41c59b76a9263c6cd27d0c985) [@vcunat](https://github.com/vcunat) - volk: fix eval without allowed aliases
- [`53fcb2e5859b`](https://github.com/NixOS/nixpkgs/commit/53fcb2e5859bfe7b8e88a405c242599efdfa215d) [@jtojnar](https://github.com/jtojnar) - liblouis: 3.24.0 → 3.25.0
- [`7b6e7dd796f8`](https://github.com/NixOS/nixpkgs/commit/7b6e7dd796f8fe17f673b7434e9366f2f7dbd67e) [@prusnak](https://github.com/prusnak) - electron-bin: move print-hashes.sh script
- [`0724cd4e4cf4`](https://github.com/NixOS/nixpkgs/commit/0724cd4e4cf44a926a594858f4cbec8967113721) [@dotlambda](https://github.com/dotlambda) - python310Packages.nextcord: 2.3.3 -> 2.4.0
- [`427d0b71b6f7`](https://github.com/NixOS/nixpkgs/commit/427d0b71b6f788769320391cb779f6387d1ecd9c) [@roberth](https://github.com/roberth) - protonup-qt: Fix CI
- [`91bf862e3c5c`](https://github.com/NixOS/nixpkgs/commit/91bf862e3c5c67b69797e9740a41e611f674a5a5) [@web-flow](https://github.com/web-flow) - arrow-cpp: fix meta.broken
- [`8030c64577a7`](https://github.com/NixOS/nixpkgs/commit/8030c64577a7973d07537e2bb446c14ccedaa14c) [@vcunat](https://github.com/vcunat) - Revert Merge #214786: libvmaf: fix build for BSD
- [`a0acf943cc65`](https://github.com/NixOS/nixpkgs/commit/a0acf943cc65d56e6708c6a63731473a5752dedb) [@vcunat](https://github.com/vcunat) - python3Packages.zipfile36: fixup meta
- [`9abbbc5979d7`](https://github.com/NixOS/nixpkgs/commit/9abbbc5979d7ddff0e479737460e725fb33f1b50) [@peterhoeg](https://github.com/peterhoeg) - nixos/plasma5: add tool needed for kinfocenter
- [`f265af55c584`](https://github.com/NixOS/nixpkgs/commit/f265af55c584fe7786e35e3dbd15de28c0d74c3a) [@peterhoeg](https://github.com/peterhoeg) - kinfocenter: add a bunch of tools for additional info
- [`880161efe12c`](https://github.com/NixOS/nixpkgs/commit/880161efe12c0b27e41fd1a45bb74a20c2877021) [@bennofs](https://github.com/bennofs) - Revert "burpsuite: 2021.12 -> 2022.12.7"
- [`8d45d82c71b9`](https://github.com/NixOS/nixpkgs/commit/8d45d82c71b91872e853f0bce3ed69993508ec5e) [@vcunat](https://github.com/vcunat) - Revert "nixos/tests/installer: test relative paths in initrd secrets"
- [`9089ee1796b8`](https://github.com/NixOS/nixpkgs/commit/9089ee1796b8d331d6ddfcb077e8ab0a9fea0288) [@peterhoeg](https://github.com/peterhoeg) - {libsForQt5.kpmcore,partition-manager}: * -> 22.12.1
- [`c73f29c723c2`](https://github.com/NixOS/nixpkgs/commit/c73f29c723c2dce97e8789c6cf96b36a1b158176) [@Mindavi](https://github.com/Mindavi) - classicube: move runHook postInstall
- [`235799128bfc`](https://github.com/NixOS/nixpkgs/commit/235799128bfccb6048f36a86e9d32545efca0372) [@Mindavi](https://github.com/Mindavi) - classicube: use makeDesktopItem
- [`52519fd12e63`](https://github.com/NixOS/nixpkgs/commit/52519fd12e639abdc4dbc8e054f73d68c923a505) [@Mindavi](https://github.com/Mindavi) - classicube: add .desktop file
- [`2c4b97d6a0eb`](https://github.com/NixOS/nixpkgs/commit/2c4b97d6a0eb6beead204afd4e67c63ea1ad06a0) [@zowoq](https://github.com/zowoq) - Revert "luaPackages.lsqlite3complete: init at 0.9.5-1"
- [`5be120bac3d3`](https://github.com/NixOS/nixpkgs/commit/5be120bac3d30631cd903010b20fbc80a5d81eba) [@bobby285271](https://github.com/bobby285271) - kubernetes-controller-tools: 0.10.0 -> 0.11.1
- [`5c52e8cbcb32`](https://github.com/NixOS/nixpkgs/commit/5c52e8cbcb32cfb13d3697ced2991a966a4fe4e3) Yt \<happysalada@proton.me\> - libsForQt5.mauikit-calendar: init at 1.0.0
- [`b660c76d0fbd`](https://github.com/NixOS/nixpkgs/commit/b660c76d0fbd26dd8735dff51bf4d4df9eda9c91) Yt \<happysalada@proton.me\> - cask-server: init at 0.5.6
- [`21e0f7502b31`](https://github.com/NixOS/nixpkgs/commit/21e0f7502b315de9cb798a6ac4c71629bd27218a) Yt \<happysalada@proton.me\> - libsForQt5.maui-core: init at 0.5.6
- [`58d84f7f0fb6`](https://github.com/NixOS/nixpkgs/commit/58d84f7f0fb6a079a5370c384fd6055640ca9fa9) Yt \<happysalada@proton.me\> - maui-shell: init at 0.5.6
- [`3c6d63d22ca8`](https://github.com/NixOS/nixpkgs/commit/3c6d63d22ca8b57adc4120f7c1ea5262925c8c2d) [@vcunat](https://github.com/vcunat) - rtw89-firmware: fixup build after rtw89 update
- [`92b4f173803f`](https://github.com/NixOS/nixpkgs/commit/92b4f173803f65531e066321934e7d1ee7eb5090) [@vcunat](https://github.com/vcunat) - tennix: avoid URL literal
- [`42a68e6a36b8`](https://github.com/NixOS/nixpkgs/commit/42a68e6a36b8d7fd7f0cec5ef3b2f0ca6693a5e6) [@jtojnar](https://github.com/jtojnar) - bundlerUpdateScript: Fix evaluation with `allowAliases = false`
- [`6184f635b3c3`](https://github.com/NixOS/nixpkgs/commit/6184f635b3c3d2794821bb31c04a4e7a99ee0fdb) [@maralorn](https://github.com/maralorn) - nixos/doc: Fix typo in 22.11 release manual
- [`cdad0ce127b0`](https://github.com/NixOS/nixpkgs/commit/cdad0ce127b0b32ae8c5c07233f44dd63a85661a) [@vcunat](https://github.com/vcunat) - nixos/filesystems: fix a typo in docs
- [`b68bd2ee5205`](https://github.com/NixOS/nixpkgs/commit/b68bd2ee52051aaf983a268494cb4fc6c485b646) [@mweinelt](https://github.com/mweinelt) - 23.05 is Stoat
- [`df109d0291d3`](https://github.com/NixOS/nixpkgs/commit/df109d0291d376e8edae58abd524bd219c65c1da) [@bobby285271](https://github.com/bobby285271) - go-graft: 0.2.14 -> 0.2.15
- [`9971f569a937`](https://github.com/NixOS/nixpkgs/commit/9971f569a93799dd2dc917d54f7bbf96ec296360) [@bobby285271](https://github.com/bobby285271) - goeland: 0.12.1 -> 0.12.3
- [`54be84c3ac01`](https://github.com/NixOS/nixpkgs/commit/54be84c3ac0122c2b2272fc68a9015304bc0bb73) [@teto](https://github.com/teto) - pass2csv: 0.3.2 -> 1.0.0
- [`636051e35346`](https://github.com/NixOS/nixpkgs/commit/636051e353461f073ac55d5d42c1ed062a345046) [@vcunat](https://github.com/vcunat) - linux: avoid NO\_HZ\_FULL on i686-linux
- [`0ab12ad0af7d`](https://github.com/NixOS/nixpkgs/commit/0ab12ad0af7d8a706cc2035339673ba8a54dd202) [@flokli](https://github.com/flokli) - borgbackup: remove myself from maintainers
- [`9e4c57c08966`](https://github.com/NixOS/nixpkgs/commit/9e4c57c08966ebd794a15437446c4d1cf30ac213) [@jtojnar](https://github.com/jtojnar) - sublime4-dev: 4136 → 4137
- [`738fe494da28`](https://github.com/NixOS/nixpkgs/commit/738fe494da28777ddeb2612c70a5dc909958df4b) [@shlevy](https://github.com/shlevy) - Merge branch 'nix-plugins-10'
- [`ad41e043760e`](https://github.com/NixOS/nixpkgs/commit/ad41e043760ed1da3d8c957b3bf168bdfc9bd9e2) [@jonringer](https://github.com/jonringer) - python310Packages.moto: disable failing tests after werkzeug update
- [`d6d2d6c6d7fc`](https://github.com/NixOS/nixpkgs/commit/d6d2d6c6d7fcd5b71e97b9ee5f25c72f30eb9127) [@mweinelt](https://github.com/mweinelt) - python3Packages.twisted: skip failing tests on aarch64-darwin

> **Note**
> This was generated with a fairly hacky and non-reusable script, but it can relatively easily be verified probabilistically by picking a random commit in the time range and checking if it belongs to a pull request, repeat to increase confidence.

</details>

## Emergency changes

Sometimes channels have blocking breakages and need to be fixed as soon as possible (citation needed).
Currently this can be done with direct pushes, but a pull request will be required with this proposal.
The time required to fix such breakages however is barely affected: Since there is currently no requirement for pull requests to be approved or pass CI, they can get merged immediately after opening if necessary.

## Staging workflow

The staging workflow is not affected because it [already uses pull requests](https://github.com/NixOS/nixpkgs/pull/241951) for all merges into the affected branches.

# Drawbacks
[drawbacks]: #drawbacks

- Even trivial changes that don't need a review now require a pull request, which takes more effort and creates noise for reviewers.
- It takes slightly longer to push a quick fix in emergency situations.

# Alternatives
[alternatives]: #alternatives

- It would be possible to implement a third-party interface to de-anonymize future commits (even if pushed directly to master) using the [push event GitHub webhook](https://docs.github.com/en/webhooks-and-events/webhooks/webhook-events-and-payloads#push), which includes the `sender` field to match the pushing GitHub user.
  - This would not solve the other problems with direct pushes though: It still wouldn't notify others, trigger CI or be discoverable.

# Prior art
[prior-art]: #prior-art

The previous [RFC 79](https://github.com/NixOS/rfcs/pull/79) attempted to do the same, but:
- It had a mistaken estimate for the percentage of direct master commits, calculating it to be 46.85% in the last year.
  The mistake was assuming that all non-merge commits were direct pushes.
  This made it seem like the change was much more impactful than it actually would've been.
- It was too ambitious by also proposing to require accepting reviews for all pull requests.

# Unresolved questions
[unresolved]: #unresolved-questions

# Future work
[future]: #future-work
More restrictions could be implemented in the future:
- Require all pull requests to have at least one approval, therefore preventing people from merging their own pull requests (it's not possible to approve your own pull request)
- Require an approval by a code owner, properly establishing code ownership over all parts of Nixpkgs
- Require CI to pass, maybe using GitHub's new [merge queue's](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-a-merge-queue)
