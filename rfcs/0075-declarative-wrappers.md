---
feature: Declarative Wrappers
start-date: (fill me in with today's date, YYYY-MM-DD)
author: Doron Behar <me@doronbehar.com>
co-authors: (find a buddy later to help out with the RFC)
shepherd-team: (names, to be nominated and accepted by RFC steering committee)
shepherd-leader: (name to be appointed by RFC steering committee)
related-issues: POC Implementation at [#85103](https://github.com/NixOS/nixpkgs/pull/85103).
---

# Summary
[summary]: #summary

Manage the environment of wrappers declaratively and deprecate shell based
methods for calculating runtime environment of packages. Make wrappers a
separate derivation so that mere changes to the environment will not trigger a
rebuild. Make it easier to debug why env vars are added to an executable, by
using Nix as the language to evaluate what env vars are needed, instead of not
documented good enough and not easily debug-able shell hooks.

# Motivation
[motivation]: #motivation

Every Nix build produced is stored in a separate path in the store. For a
build to find its runtime dependencies purely, they need to be hardcoded in
the build. Thus, a complete dependency specification is needed.

In case of compiled languages this process is already largely automated;
absolute paths to shared libraries are encoded in the `rpath` of binaries.
Executables that are invoked by binaries need to be dealt with manually,
however. The preferred choice is here to manually patch the source so that
binaries are invoked using absolute paths as well.

This is not always trivial and thus a common work-around is to wrap executables,
setting `$PATH` to include the locations of dependencies. This is a pragmatic
solution that typically works fine, but it comes with a risk: *environment
variables leak*. Executables that shell out may pass along the modified
variables, causing at times unwanted behaviour.

Programs written in interpreted languages tend to import their runtime
dependencies using some kind of search path. E.g., in case of Python there is a
process for building up the `sys.path` variable which is then considered when
importing modules. Like with compiled languages, the preferred choice would also
here be to embed the absolute paths in the code, which is often not done. Note
that in case of Python this *is* done. Like with compiled languages, programs
may shell out and likewise the preferred solution is to patch the invocations to
use absolute paths. Similarly, in case a programs wants to `dlopen` a shared
library this should be patched to include an absolute path, instead of using
`LD_LIBRARY_PATH`.

It is recognized that wrappers setting environment variables are typically not
the preferred choice because of the above mentioned leakage risk, however, often
there is simply not a better or reasonable alternative available.

We have numerous issues regarding wrappers and our wrapper shell hooks. Here's
a list of them, sorted to categories.

## Closure related

- [issue 95027](https://github.com/NixOS/nixpkgs/issues/95027)

@jtojnar & @yegortimoshenko How
hard would it be to test all of our wrapped `gobject-introspection` using
packages that the equivalent, `GI_GIR_PATH` environment should work? If our
wrappers were declarative, and they were a separate derivation, at least we
wouldn't have to rebuild tons of packages to do so - we'd have to rebuild only
the wrappers. Plus, since all of the environment is available to us via
`builtins.toJSON`, it should be possible to write a script that will compare
the environments to make the transition easier to review.

## Missing environment

- [pull 83321](https://github.com/NixOS/nixpkgs/pull/83321)
- [pull 53816](https://github.com/NixOS/nixpkgs/pull/53816)

@rnhmjoj & @timokau How unfortunate it is that Python's `buildEnv` doesn't know
to do anything besides setting `NIX_PYTHONPATH` - it knows nothing about other
env vars, which some deps rely upon when eventually used. Declarative wrappers
don't care about the meaning of env vars - all of them are treated equally,
considering all of the inputs of a derivation equally.

- [pull 75851](https://github.com/NixOS/nixpkgs/pull/75851)
- [issue 87667](https://github.com/NixOS/nixpkgs/issues/87667)

Fixable with our current wrapping tools (I guess?) but it's unfortunate that we
have to trigger a rebuild of VLC and potentially increase it's closure size,
just because of a missing env var for only _some_ users. If only our wrapping
requirements were accessible via Nix attrsets, we could have instructed our
modules to consider this information when building the wrappers of the packages
in `environment.systemPackages`.

- [issue 87883](https://github.com/NixOS/nixpkgs/issues/87883) (Fixed)

@jtojnar wouldn't it be wonderful if the wrapper of gimp would have known
exactly what `NIX_PYTHONPATH` to use when wrapping gimp, just because `pygtk`
was in it's inputs? Declarative wrappers would also allow us to merge the
wrappings of such derivation to reduce double wrappings, as currently done at
[`wrapper.nix`](https://github.com/NixOS/nixpkgs/blob/b7be00ad5ed0cdbba73fa7fd7fadcb842831f137/pkgs/applications/graphics/gimp/wrapper.nix#L16-L28)
and
[`default.nix`](https://github.com/NixOS/nixpkgs/blob/b7be00ad5ed0cdbba73fa7fd7fadcb842831f137/pkgs/applications/graphics/gimp/default.nix#L142-L145).

- [issue 85306](https://github.com/NixOS/nixpkgs/issues/85306)
- [issue 84249](https://github.com/NixOS/nixpkgs/issues/84249)

`git-remote-hg` and `qttools` are not wrapped properly.

- [issue 86048](https://github.com/NixOS/nixpkgs/issues/86048)

I guess we don't wrap HPLIP because not everybody want to use these binaries
and hence want these GUI deps in their closure (if they were wrapped with a
setup hook)? Declarative wrappers would allow _some_ users to use the wrapped
binaries and others not to need this wrapping. Via an override or a NixOS
config flag, without triggering a rebuild of HPLIP itself, these users would be
easily satisfied.

## Orchestrating wrapping hooks

- [issue 78792](https://github.com/NixOS/nixpkgs/issues/78792)

@worldofpeace you are correct. All of these setup-hooks are a mess. At least we
have documented, (yet not totally implemented) this section of the manual
https://nixos.org/nixpkgs/manual/#ssec-gnome-common-issues-double-wrapped

Declarative wrappers will deprecate the usage of our shell based hooks and will
wrap all executables automatically according to their needs, without requiring
the contributor a lot of knowledge of the wrapping system. Also, double
wrappings will become a problem of the past.

- [issue 86369](https://github.com/NixOS/nixpkgs/issues/86369) 

@ttuegel I get the sense [you support this idea of declarative
wrappers](https://github.com/NixOS/nixpkgs/issues/86369#issuecomment-626732191).
For anyone else interested in a summary, the issue is a bit complex, so once
you'll read the design of this RFC, and see examples of what the POC
implementation of declarative wrappers [is capable
of](https://github.com/NixOS/nixpkgs/pull/85103#issuecomment-614195666), I hope
you'll see how declarative wrappers will solve this issue.


## Issues _possibly_ fixable by declarative wrappers (?)

- [pull 61213](https://github.com/NixOS/nixpkgs/pull/61213) 

I'm not sure what's the issue there. But, I'm sure that a declarative, Nix
based builder of a Python environment, even if this environment is used only
for a build, should make it easier to control and alter it's e.g `$PATH`.

- [issue 83667](https://github.com/NixOS/nixpkgs/issues/83667)

@FRidh I see no reason for Python deps of Python packages to need to be in
`propagatedBuildInputs` and not regular `buildInputs` but please correct me if
I'm wrong. I think this was done so in the past so it'd be easy to know how to
wrap them? Declarative wrappers won't require runtime-env-requiring deps to be
only in `propagatedBuildInputs` or `buildInputs` - it should pick such deps
from both lists. Hence, (I think) it should be possible to make Python's static
builds consistent with other ecosystems.

- [issue 86054](https://github.com/NixOS/nixpkgs/issues/86054)

@ttuegel TBH I can't tell if declarative wrappers might help, but I'm linking
this issue here because @worldofpeace wrote it might be related to wrappers?
Feel free to suggest removing this in the RFC review.

- [issue 49132](https://github.com/NixOS/nixpkgs/issues/49132)
- [issue 54278](https://github.com/NixOS/nixpkgs/issues/54278)
- [issue 39493](https://github.com/NixOS/nixpkgs/issues/39493)

`GDK_PIXBUF` compatibilities? I haven't investigated them to the details, so feel
free @jtojnar to review me and tell me that declarative wrappers won't help.

## Unreported issues (AFAIK)

Issues that bother me personally, but I haven't bothered to open an issue since
I doubt it would be feasible to fix with our current wrapping ecosystem, excuse
my pessimism `wrap{G,Qt}AppsHook` authors.

`kdeconnect` has `kdoctools` in it's closure because it's wrapper has
`kdoctools` due to it picked by `wrapQtAppsHook`:

```
$ nix why-depends -f. kdeconnect kdoctools
/nix/store/sh42k6cz4j48br4cxi2qn173rys4japp-kdeconnect-1.3.5
╚═══bin/kdeconnect-cli: …xport XDG_DATA_DIRS='/nix/store/m16681i5dhhkhszi9w42ir037jvbnab9-kdoctools-5.71.0/share'${XDG_DA…
    => /nix/store/m16681i5dhhkhszi9w42ir037jvbnab9-kdoctools-5.71.0
```

A similar issue is with `kconfigwidgets.dev` and `kdeconnect`:

```
$ nix why-depends -f. kdeconnect kdeframeworks.kconfigwidgets.dev
 /nix/store/sh42k6cz4j48br4cxi2qn173rys4japp-kdeconnect-1.3.5
 ╚═══bin/kdeconnect-cli: …port QT_PLUGIN_PATH='/nix/store/qssjj6ki7jiskw2kfygvfiy8fxrclwrl-kconfigwidgets-5.71.0-dev/lib/q…
     => /nix/store/qssjj6ki7jiskw2kfygvfiy8fxrclwrl-kconfigwidgets-5.71.0-dev
```

Also similar (but possibly fixable by moving `gobject-introspection` to a
different inputs list?):
 
```
$ nix why-depends -f. beets gobject-introspection.dev
/nix/store/93lfrhm8vp17m8ziqi8vp6v4cff67wkb-beets-1.4.9
╚═══bin/beet: …-expat-2.2.8-dev/bin:/nix/store/y3ym76wrak3300vsjyf3klr52cnzmxwd-gobject-introspection-1.64.1-de…
    => /nix/store/y3ym76wrak3300vsjyf3klr52cnzmxwd-gobject-introspection-1.64.1-dev
```

## Other issues

- [issue 60260](https://github.com/NixOS/nixpkgs/issues/60260)

General, justified complaint about wrappers.

- [issue 95027](https://github.com/NixOS/nixpkgs/issues/95027)
- [issue 23018](https://github.com/NixOS/nixpkgs/issues/23018)
- [issue 11133](https://github.com/NixOS/nixpkgs/issues/11133)
- [pull 95569](https://github.com/NixOS/nixpkgs/pull/95569)

Since our wrappers are shell scripts, `gdb` can't run them. What if we had
written a C based wrapper, that perhaps would read what environment it needs to
set from a JSON file, and it will call the unwrapped original executable? I
need feedback regarding whether `gdb` will play nice with this.

This issue may not directly relate to declarative wrappers, and it is already
addressed in @FRidh's [pull 95569](https://github.com/NixOS/nixpkgs/pull/95569), but perhaps
both ideas could be integrated into an alternative, simpler creation method of
binary wrappers. See [my
comment](https://github.com/NixOS/nixpkgs/pull/95569#issuecomment-674508806).

- `hardware.sane` module installs sane impurly
- [issue 90201](https://github.com/NixOS/nixpkgs/issues/90201)
- [issue 90184](https://github.com/NixOS/nixpkgs/issues/90184)

The current way NixOS enables to configure access to scanner, is via the
`hardware.sane` module, which interacts [just a
bit](https://github.com/NixOS/nixpkgs/blob/5d8dd5c2598a74761411bc9bef7c9111d43d2429/nixos/modules/services/hardware/sane.nix#L34)
wish `saned`, but mostly does nothing besides setting `SANE_CONFIG_DIR` and
`LD_LIBRARY_PATH`. This is bad because:

1. Running `nixos-rebuild` after a change to sane or it's configuration,
   requires the user to logout and login, to see effects of the changes.  
   
2.
[Apparently](https://github.com/NixOS/nixpkgs/issues/90201#issuecomment-683304279)
`LD_LIBRARY_PATH` is cleared when an application runs with extra capabilities.
This causes the current gnome-shell wayland wrapper to unset the
`LD_LIBRARY_PATH` many scanner related programs now rely upon.

Declarative wrappers should enable us to make such applications that use a
`SANE_CONFIG_DIR` and `LD_LIBRARY_PATH` to be configured during the wrap phase,
and get rid of these global environment variables.

# Detailed design
[design]: #detailed-design

The current design is roughly implemented at
[pull 85103](https://github.com/NixOS/nixpkgs/pull/85103) .  

The idea is to have a Nix function, let us call it `wrapGeneric`, with an
interface similar to
[`wrapMpv`](https://github.com/NixOS/nixpkgs/blob/a5985162e31587ae04ddc65c4e06146c2aff104c/pkgs/applications/video/mpv/wrapper.nix#L9-L23)
and
[`wrapNeovim`](https://github.com/NixOS/nixpkgs/blob/a5985162e31587ae04ddc65c4e06146c2aff104c/pkgs/applications/editors/neovim/wrapper.nix#L11-L24)
which will accept a single derivation or an array of them and will wrap all of
their executables with the proper environment, based on their inputs.

`wrapGeneric` should iterate recursively all `buildInputs` and
`propagatedBuildInputs` of the input derivation(s), and construct an attrset with
which it'll calculate the necessary environment of the executables. Then either
via `wrapProgram` or a better method, it'll create the wrappers.

A contributor using `wrapGeneric` shouldn't _care_ what type of wrapping needs
to be performed on his derivation's executables - whether these are Qt related
wrappings or a Gtk / gobject related. `wrapGeneric` should know all there is to
know about environment variables every library / input may need during runtime,
and with this information at hand, construct the necessary wrapper.

In order for `wrapGenric` to know all of this information about our packaged
libraries - the information about runtime env, we need to write in the
`passthru`s of these libraries, what env vars they need. Such information was
added in the POC pull at [commit
@6283f15](https://github.com/NixOS/nixpkgs/pull/85103/commits/6283f15bb9b65af64571a78b039115807dcc2958).

Additional features / improvements are [already
available](https://github.com/NixOS/nixpkgs/pull/85103#issuecomment-614195666)
in the POC pull. For example:

- It should be **impossible** for multi-value env vars to have duplicates, as
  that's guaranteed by Nix' behavior when constructing arrays / attrsets.
- Asking the wrapper creator to use more links and less colon-separated values
  in env vars - should help avoid what [pull
  84689](https://github.com/NixOS/nixpkgs/pull/84689) fixed.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

All examples are copied from and based on the [POC
pull](https://github.com/NixOS/nixpkgs/pull/85103).

Here's a new method of creating a python environment:

```nix
  my-python-env = wrapGeneric python3 {
    linkByEnv = {
      # you can use "link" here and that will link only the necessary files
      # to the runtime environment.
      PYTHONPATH = "linkPkg";
    };
    extraPkgs = with python3.pkgs; [
      matplotlib
    ];
    wrapOut = {
      # tells wrapGeneric to add to the wrappers this value for PYTHONPATH.
      # Naturally, this should play along with the values given in
      # linkByEnv.PYTHONPATH.
      PYTHONPATH = "$out/${python3.sitePackages}";
    };
  };
```

Consider a package is wrapped without directly making accessible the unwrapped
derivation. Meaning, say `all-packages.nix` has:

```nix
  my-awesome-pkg = wrapGeneric (callPackage ../applications/my-awesome-pkg { }) { };
```

Assuming the user knows `my-awesome-pkg` is wrapped with `wrapGeneric`, they would
need to use an overlay like this, to override the unwrapped derivation:

```nix
self: super:

{
  my-awesome-pkg = super.wrapGeneric (
    super.my-awesome-pkg.unwrapped.overrideAttrs(oldAttrs: {
      preFixup = ''
        overriding preFixup from an overlay!!
      '';
    })
  ) {};
} 
```

And to override the wrapper derivation, e.g to add new optional features not
strictly necessary (as in [pull
83482](https://github.com/NixOS/nixpkgs/pull/83482)), it should be possible
using:

```nix
self: super:

{
  my-awesome-pkg = super.wrapGeneric super.my-awesome-pkg.unwrapped {
    extraPkgs = [
      super.qt5.certain-qt-plugin
    ];
  };
}
```

# Drawbacks
[drawbacks]: #drawbacks

The current design is heavily based on Nix, and knowing how to write and debug
Nix expressions is a skill not everyone are akin to learn. Also, overriding a
wrapped derivation is somewhat more awkward, due to this. Perhaps this
interface could be improved, and for sure proper documentation written should
help.

# Alternatives
[alternatives]: #alternatives

Perhaps our shell hooks _can_ be fixed / improved, and we could help make it
easier to debug them via `NIX_DEBUG`. Then it might help us track down e.g why
environment variables are added twice etc. Still though, this wouldn't solve
half of the other issues presented here. Most importantly, the shell hooks rely
upon being in the inputs during build of the original derivation. Hence, mere
requests for changes to an environment a wrapper sets, trigger rebuilds that
take a lot of time and resources from average users. See [this
comment](https://github.com/NixOS/nixpkgs/pull/88136#issuecomment-632674653).

# Unresolved questions
[unresolved]: #unresolved-questions

The POC implementation does 1 thing which I'm most sure could be done better,
and that's iterating **recursively** all `buildInputs` and
`propagatedBuildInputs` of the given derivations. This is currently implemented
with a recursive (Nix) function, prone to reach a state of infinite recursion.
This risk is currently mitigated using an array of packages we know don't need
any env vars at runtime, and for sure are very much at the bottom of the list
of all Nixpkgs' dependency graph. This part is implemented
[here](https://github.com/NixOS/nixpkgs/pull/85103/files#diff-44c2102a355f50131eb8f69fb7e7c18bR75-R131).

There are other methods of doing this recursive search, but I haven't yet
investigated all of them. For reference and hopefully for an advice, this need
was requested by others and discussed at:

- [nix issue 1245](https://github.com/NixOS/nix/issues/1245).
- [Interesting idea by @aszlig at nix issue
  1245](https://github.com/NixOS/nix/issues/1245#issuecomment-401642781).
- ~~[@nmattia's
  post](https://www.nmattia.com/posts/2019-10-08-runtime-dependencies.html)~~ -
  Using it will require IFD.
- [Discourse thread](https://discourse.nixos.org/t/any-way-to-get-a-derivations-inputdrvs-from-within-nix/7212/3).

# Future work
[future]: #future-work

Not that I can think of.
