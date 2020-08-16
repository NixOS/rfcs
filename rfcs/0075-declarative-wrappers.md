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

- https://github.com/NixOS/nixpkgs/issues/95027

@jtojnar & @yegortimoshenko How
hard would it be to test all of our wrapped `gobject-introspection` using
packages that the equivalent, `GI_GIR_PATH` environment should work? If our
wrappers were declarative, and they were a separate derivation, at least we
wouldn't have to rebuild tons of packages to do so - we'd have to rebuild only
the wrappers. Plus, since all of the environment is available to us via
`builtins.toJSON`, it should be possible to write a script that will compare
the environments to make the transition easier to review.

## Missing environment

- https://github.com/NixOS/nixpkgs/pull/83321 and
- https://github.com/NixOS/nixpkgs/pull/53816

@rnhmjoj & @timokau How unfortunate it is that Python's `buildEnv` doesn't know
to do anything besides setting `NIX_PYTHONPATH` - it knows nothing about other
env vars, which is totally legitimate for dependencies of the environment to
rely upon runtime.  Declarative wrappers don't care about the meaning of env
vars - all of them are treated equally, considering all of the inputs of a
derivation equally.

- https://github.com/NixOS/nixpkgs/pull/75851
- https://github.com/NixOS/nixpkgs/issues/87667

Fixable with our current wrapping tools (I guess?) but it's unfortunate that we
have to trigger a rebuild of VLC and potentially increase it's closure size,
just because of a missing env var for some users. If only our wrapping
requirements were accessible via Nix attrsets, we could have instructed our
modules to consider this information when building the wrappers of the packages
in `environment.systemPackages`.

- https://github.com/NixOS/nixpkgs/issues/87883 (Fixed)

@jtojnar wouldn't it be wonderful if the wrapper of gimp would have known
exactly what `NIX_PYTHONPATH` to use when wrapping gimp, just because `pygtk`
was in it's inputs? Declarative wrappers would also allow us to merge the
wrappings of such derivation to reduce double wrappings, as currently done at
[`wrapper.nix`](https://github.com/NixOS/nixpkgs/blob/b7be00ad5ed0cdbba73fa7fd7fadcb842831f137/pkgs/applications/graphics/gimp/wrapper.nix#L16-L28)
and
[`default.nix`](https://github.com/NixOS/nixpkgs/blob/b7be00ad5ed0cdbba73fa7fd7fadcb842831f137/pkgs/applications/graphics/gimp/default.nix#L142-L145).

- https://github.com/NixOS/nixpkgs/issues/85306
- https://github.com/NixOS/nixpkgs/issues/84249

`git-remote-hg` and `qttools` are not wrapped properly.

- https://github.com/NixOS/nixpkgs/issues/86048

I guess we don't wrap HPLIP because not everybody want to use these binaries
and hence want these GUI deps in their closure (if they were wrapped with a
setup hook)? Declarative wrappers would allow some users to use the wrapped
binaries and others not need it, via an override or a NixOS config flag,
without triggering a rebuild of HPLIP itself.

## Orchestrating wrapping hooks

- https://github.com/NixOS/nixpkgs/issues/78792

@worldofpeace you are correct. All of these setup-hooks are a mess, but at
least we have documented, yet not totally implemented this section of the
manual
https://nixos.org/nixpkgs/manual/#ssec-gnome-common-issues-double-wrapped

Declarative wrappers will deprecate the usage of our shell based hooks and will
wrap all executables automatically according to their needs.

- https://github.com/NixOS/nixpkgs/issues/86369 

@ttuegel I get the sense [you support this
idea](https://github.com/NixOS/nixpkgs/issues/86369#issuecomment-626732191).
But for anyone else interested, the issue is a bit complex, so once you'll read
the design of this RFC, and see examples of what the POC implementation of
declarative wrappers [is capable
of](https://github.com/NixOS/nixpkgs/pull/85103#issuecomment-614195666), I hope
you'll see how declarative wrappers can solve this issue.


## Other Issues only _possibly_ fixable by declarative wrappers

- https://github.com/NixOS/nixpkgs/pull/61213 

I'm not sure what's the issue there. But, I'm sure that a Nix based builder of
a Python environment should make it easier to control and alter if needed, what
environment is used even by builders, not only user facing Python environments.

- https://github.com/NixOS/nixpkgs/issues/83667

@FRidh I see no reason for Python deps of Python packages to need to be in
`propagatedBuildInputs` and not regular `buildInputs`. I think this was done so
in the past so it'd be easy to know how to wrap them? Declarative wrappers
won't require runtime-env-requiring deps to be only in `propagatedBuildInputs`
or `buildInputs` - it should pick such deps from both lists. Hence, I think it
should be possible to make Python's static builds consistent with other
ecosystems.

- https://github.com/NixOS/nixpkgs/issues/86054

@ttuegel TBH I can't tell if declarative wrappers might help, but I'm linking
this issue here as well because @worldofpeace wrote it might related to
wrappers? Feel free to suggest removing this in the RFC review.

- https://github.com/NixOS/nixpkgs/issues/49132
- https://github.com/NixOS/nixpkgs/issues/54278
- https://github.com/NixOS/nixpkgs/issues/39493

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

- https://github.com/NixOS/nixpkgs/issues/60260

General, justified complain about wrappers.

- https://github.com/NixOS/nixpkgs/issues/95027
- https://github.com/NixOS/nixpkgs/issues/23018
- https://github.com/NixOS/nixpkgs/issues/11133
- https://github.com/NixOS/nixpkgs/pull/95569

Since our wrappers are shell scripts, `gdb` can't run them. What if we had
written a C based wrapper, that perhaps would read what environment it needs to
set from a JSON file, and it will call the unwrapped original executable? I
need feedback regarding whether `gdb` will play nice with this.

# Detailed design [design]: #detailed-design

Consider every env var set by our shell hooks and our builders such as
`buildPythonPackage` and friends. Every such var is usually set because certain
packages used in the wrapped package's inputs, imply that this env var will be
needed during runtime. Many such vars' values are known to concatenated with
`:`.

Now, What if we'd write down in the `passthru`s of these packages, that "in order to
run something that requires this package, you need `THIS_ENV_VAR` to include
`$out/this/value`? Imagine this information was available to us in a consistent
manner. We could then write a Nix function, that will calculate the necessary
arguments to the shell functions `makeWrapper` or `wrapProgram`, somewhat
similarly to how our fixup hooks already do this.

This Nix function, let us call it `wrapGeneric`, should iterate recursively all
`buildInputs` and `propagatedBuildInputs` of a given derivation, and decide
what environment this derivation will need to run.  

# Examples and Interactions
[examples-and-interactions]: #examples-and-interactions

This section illustrates the detailed design. This section should clarify all
confusion the reader has from the previous sections. It is especially important
to counterbalance the desired terseness of the detailed design; if you feel
your detailed design is rudely short, consider making this section longer
instead.

# Drawbacks
[drawbacks]: #drawbacks

If we think our shell hooks can scale, and that they are easily manageable, and
that we are OK with 

# Alternatives
[alternatives]: #alternatives

What other designs have been considered? What is the impact of not doing this?

# Unresolved questions
[unresolved]: #unresolved-questions

What parts of the design are still TBD or unknowns?

# Future work
[future]: #future-work

What future work, if any, would be implied or impacted by this feature
without being directly part of the work?
