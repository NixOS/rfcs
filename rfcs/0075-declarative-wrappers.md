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
methods for calculating runtime environment of packages.

# Motivation
[motivation]: #motivation

- Make wrappers a separate derivation to make mere changes to the environment
  not trigger a heavy rebuild.
- Make it easier to debug why env vars are added to an executable, by using Nix
  as the language to evaluate what env vars are needed, instead of not
  documented good enough and not easily debug-able shell hooks.

We have numerous issues regarding wrappers and our wrapper shell hooks. Here's
a list of them, sorted by categories.

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
env vars, which is totally legitimate for dependencies of the environment to
rely upon runtime.  Declarative wrappers don't care about the meaning of env
vars - all of them are treated equally, considering all of the inputs of a
derivation equally.

- [pull 75851](https://github.com/NixOS/nixpkgs/pull/75851)
- [issue 87667](https://github.com/NixOS/nixpkgs/issues/87667)

Fixable with our current wrapping tools (I guess?) but it's unfortunate that we
have to trigger a rebuild of VLC and potentially increase it's closure size,
just because of a missing env var for some users. If only our wrapping
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
setup hook)? Declarative wrappers would allow some users to use the wrapped
binaries and others not need it, via an override or a NixOS config flag,
without triggering a rebuild of HPLIP itself.

## Orchestrating wrapping hooks

- [issue 78792](https://github.com/NixOS/nixpkgs/issues/78792)

@worldofpeace you are correct. All of these setup-hooks are a mess, but at
least we have documented, yet not totally implemented this section of the
manual
https://nixos.org/nixpkgs/manual/#ssec-gnome-common-issues-double-wrapped

Declarative wrappers will deprecate the usage of our shell based hooks and will
wrap all executables automatically according to their needs.

- [issue 86369](https://github.com/NixOS/nixpkgs/issues/86369) 

@ttuegel I get the sense [you support this
idea](https://github.com/NixOS/nixpkgs/issues/86369#issuecomment-626732191).
But for anyone else interested, the issue is a bit complex, so once you'll read
the design of this RFC, and see examples of what the POC implementation of
declarative wrappers [is capable
of](https://github.com/NixOS/nixpkgs/pull/85103#issuecomment-614195666), I hope
you'll see how declarative wrappers can solve this issue.


## Other Issues only _possibly_ fixable by declarative wrappers

- [pull 61213](https://github.com/NixOS/nixpkgs/pull/61213) 

I'm not sure what's the issue there. But, I'm sure that a Nix based builder of
a Python environment should make it easier to control and alter if needed, what
environment is used even by builders, not only user facing Python environments.

- [issue 83667](https://github.com/NixOS/nixpkgs/issues/83667)

@FRidh I see no reason for Python deps of Python packages to need to be in
`propagatedBuildInputs` and not regular `buildInputs`. I think this was done so
in the past so it'd be easy to know how to wrap them? Declarative wrappers
won't require runtime-env-requiring deps to be only in `propagatedBuildInputs`
or `buildInputs` - it should pick such deps from both lists. Hence, I think it
should be possible to make Python's static builds consistent with other
ecosystems.

- [issue 86054](https://github.com/NixOS/nixpkgs/issues/86054)

@ttuegel TBH I can't tell if declarative wrappers might help, but I'm linking
this issue here as well because @worldofpeace wrote it might related to
wrappers? Feel free to suggest removing this in the RFC review.

- [issue 49132](https://github.com/NixOS/nixpkgs/issues/49132)
- [issue 54278](https://github.com/NixOS/nixpkgs/issues/54278)
- [issue 39493](https://github.com/NixOS/nixpkgs/issues/39493)

`GDK_PIXBUF` compatibilities? I haven't investigated them to the details, so feel
free @jtojnar to review me and tell me that declarative wrappers won't help.

## Unreported issues (AFAIK)

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
different inputs list?
 
```
$ nix why-depends -f. beets gobject-introspection.dev
/nix/store/93lfrhm8vp17m8ziqi8vp6v4cff67wkb-beets-1.4.9
╚═══bin/beet: …-expat-2.2.8-dev/bin:/nix/store/y3ym76wrak3300vsjyf3klr52cnzmxwd-gobject-introspection-1.64.1-de…
    => /nix/store/y3ym76wrak3300vsjyf3klr52cnzmxwd-gobject-introspection-1.64.1-dev
```

## Other issues

- [issue 60260](https://github.com/NixOS/nixpkgs/issues/60260)

General, justified complain about wrappers.

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
binary wrappers. See
[comment](https://github.com/NixOS/nixpkgs/pull/95569#issuecomment-674508806)

# Detailed design
[design]: #detailed-design

The current design is roughly implemented at
[pull 85103](https://github.com/NixOS/nixpkgs/pull/85103) .  

The idea is to have a Nix function, called `wrapGeneric` with an interface
similar to [`wrapMpv`](https://github.com/NixOS/nixpkgs/blob/a5985162e31587ae04ddc65c4e06146c2aff104c/pkgs/applications/video/mpv/wrapper.nix#L9-L23) and [`wrapNeovim`](https://github.com/NixOS/nixpkgs/blob/a5985162e31587ae04ddc65c4e06146c2aff104c/pkgs/applications/editors/neovim/wrapper.nix#L11-L24) which will accept a single derivation or
an array of them and it'll wrap all of their executables with the proper
environment, based on their inputs.

`wrapGeneric` should iterate recursively all `buildInputs` and
`propagatedBuildInputs` of the input derivations, and construct an attrset with
which it'll calculate the necessary environment of the executables. Then either
via `wrapProgram` or a better method, it'll create the wrappers.

A contributor using `wrapGeneric` shouldn't _care_ what type of wrapping needs
to be performed on his derivation's executables - whether these are Qt related
wrappings or a Gtk / gobject related. `wrapGeneric` should know all there is to
know about environment variables every library / input may need during runtime,
and with this information at hand, construct the necessary wrapper.

In order for `wrapGenric` to know all of this information about our packaged
libraries - the information about runtime env, we need to write in the
`passthru`s of these libraries, what env vars they need.

This Nix function, let us call it `wrapGeneric`, should iterate recursively all
`buildInputs` and `propagatedBuildInputs` of a given derivation, and decide
what environment this derivation will need to run. Such information was added
in the [POC pull's
@6283f15](https://github.com/NixOS/nixpkgs/pull/85103/commits/6283f15bb9b65af64571a78b039115807dcc2958).

Additional features / improvements are [already
available](https://github.com/NixOS/nixpkgs/pull/85103#issuecomment-614195666)
in the POC pull. For example:

- It should be impossible for multi-value env vars to have duplicates, as
  that's guaranteed by Nix' behavior when constructing arrays.
- Asking the wrapper creator to use more links and less colon-separated values
  in env vars - should help avoid what [pull
  84689](https://github.com/NixOS/nixpkgs/pull/84689) fixed.

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

All examples are copied from and based on the [POC
pull](https://github.com/NixOS/nixpkgs/pull/85103).

The new method of creating a python environment:

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

Assuming the user knows my-awesome-pkg is wrapped with wrapGeneric, they would
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

And to override the wrapper derivation, it should be possible using:

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
upon being in the inputs during build of the original derivation, hence mere
changes to an environment may trigger rebuilds that take a lot of time and
resources from avarage users. See [this
comment](https://github.com/NixOS/nixpkgs/pull/88136#issuecomment-632674653).

# Unresolved questions
[unresolved]: #unresolved-questions

The POC implementation does 1 thing which I'm most sure could be done better,
and that's iterating **recursively** all `buildInputs` and
`propagatedBuildInputs` of the input derivations. This is currently implemented
via a recursive (Nix) function, that's is prone to stack overflow due reach a
state of infinite recursion. But this risk is currently mitigated using an
array of packages we know don't need any env vars at runtime, and for sure are
very much at the bottom of the list of very common inputs. This is implemented [here](https://github.com/NixOS/nixpkgs/pull/85103/files#diff-44c2102a355f50131eb8f69fb7e7c18bR75-R131).

There are other methods of doing this which might be better, but TBH I haven't
yet investigated all of them. For reference and hopefully for an advice, this
need was requested by others and discussed at:

- [nix issue](https://github.com/NixOS/nix/issues/1245).
- [Interesting idea by @aszlig](https://github.com/NixOS/nix/issues/1245#issuecomment-401642781) I haven't tested.
- [@nmattia's post](https://www.nmattia.com/posts/2019-10-08-runtime-dependencies.html).
- [Discourse thread](https://discourse.nixos.org/t/any-way-to-get-a-derivations-inputdrvs-from-within-nix/7212/3).

# Future work
[future]: #future-work

Not that I can think of.
