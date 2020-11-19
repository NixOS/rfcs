---
feature: run-phase-changes-for-better-nix-shell-use
start-date: 2018-08-26
author: @globin
co-authors: @dezgeg
related-issues: https://github.com/dezgeg/nixpkgs/tree/better-run-phases
shepherd-team: Samuel Dionne-Reil, John Ericson, Linus Heckemann
shepherd-leader: Linus Heckemann
---

# Summary
[summary]: #summary

The intent of this proposal is to tweak a bit how the stdenv runs phases during a build to achieve these two goals:
1. Improve the UX of nix-shell by making it easier to manually run phases inside a nix-shell
2. Improve the consistency of pre/post hooks by always running such hooks instead of only running them in non-overridden phases

# Motivation
[motivation]: #motivation

The primary goal of this RFC is to make it easier to run build phases manually inside a nix-shell.
Currently, it's a bit annoying because to run say, `buildPhase` the only invocation that works correctly in all cases is:

````sh
eval "${buildPhase:-buildPhase}"
````

The goal is to be able to replace the above with the obvious:
````sh
buildPhase
````

The secondary goal is to change how hooks (like `preBuild`, `postBuild` etc.) interact with overridden phases.
For example a derivation `foo-package` doing,
````nix
stdenv.mkDerivation {
    # ...
    
    buildPhase = ''
        ./my-funky-build-script.sh
    '';
    
    # ...
}
````
causes `preBuild` and `postBuild` not to be called anymore.
In 99% of the cases this isn't a problem, but it can cause hidden annoyances when using `.overrideAttrs`, for instance:
````
    foo-package.overrideAttrs (attrs: {
        postBuild = (attrs.postBuild or "") + ''
            # whatever
        '';
    })
````
Which has led to some people adding explicit `runHook preFoo` and `runHook postFoo` calls to a (small) number of packages.

Thus, to counter this inconsistency, this RFC proposes that those hooks will be run even when the phase is overridden.

# Detailed design
[design]: #detailed-design

All the 'phase' functions in Nixpkgs need to be reworked a bit. Conceptually, the following diff will be applied to each of them:
````diff
-buildPhase() {
+defaultBuildPhase() {
-    runHook preBuild
-
     # set to empty if unset
     : ${makeFlags=}
 
@@ -1008,14 +1104,14 @@ buildPhase() {
         make ${makefile:+-f $makefile} "${flagsArray[@]}"
         unset flagsArray
     fi
-
-    runHook postBuild
 }
+
+buildPhase() {
+    runHook preBuild
+
+    if [ -n "$buildPhase" ]; then
+        eval "$buildPhase"
+    else
+        defaultBuildPhase
+    fi
+
+    runHook postBuild
+}
 
````
That is, the logic of 'if variable `$buildPhase` is set, then eval the contents of `$buildPhase`, otherwise call the function `buildPhase` which contains the default implementation' is pulled down from `genericBuild` to the `buildPhase` function itself
and the function responsible for the default implementation is now renamed to `defaultBuildPhase`.
Then, the `runHook` calls are pulled up from the default phase implementation to the new `buildPhase` function itself.

The actual logic is abstracted to helper function I've named `commonPhaseImpl` (bikeshedding on the name welcome). Thus the implementation of `buildPhase` presented above will be this one-liner:
````sh
buildPhase() {
    commonPhaseImpl buildPhase --default defaultBuildPhase --pre-hook preBuild --post-hook postBuild
}
````

## Backwards compatibility

The changed semantics proposed here might break some out-of-tree packages.
Fortunately most of it should be avoidable by writing some backwards-compatibility code that will allow extra time for out-of-tree code to migrate.
In the order of how frequent the problem will happen (in my view), the following things are problematic:

1. Out-of-tree packages which have explicit `runHook preFoo` and `runHook postFoo` in their overridden `fooPhase`.
2. Out-of-tree custom phases.
3. Out-of-tree packages that expect calls like `buildPhase` to call the default implementation.

For 1., the problem is that the `preFoo` and `postFoo` hooks would get executed twice.
We can avoid this by having `commonPhaseImpl` 'poison' the hooks for the duration of the overridden phase
by temporarily setting `preFoo` and `postFoo` to some function that just prints a warning message.

For 2., the problem is what should `genericBuild` do if both `$fooPhase` the variable and `fooPhase` the function exists.
 - For "new-style" phases (i.e. ones migrated to use `commonPhaseImpl`) the only right thing to do is to call the function `fooPhase`.
 - For "old-style" phases (i.e. ones that have not migrated to `commonPhaseImpl` yet) the only right thing to do is `eval "$fooPhase"`.
Thus, a way to detect between the two cases needs to be made. I currently have a check among the lines of `declare -f "$curPhase" | grep -q commonPhaseImpl`.
That is, grep the definition of the function to see if the word `commonPhaseImpl` appears there, which is a quite crude hack but will probably work in practice.
An alternative would be to have a associative array where the phases could declare that they are 'new-style' (e.g. stdenv's setup.sh would have `isNewStylePhase[buildPhase]=1` somewhere and so on).

For 3., the specific problem is that some (very few) packages do something like this:
````
stdenv.mkDerivation {
    # ...
    
    buildPhase = ''
        buildPhase
        (cd foo; buildPhase)
        (cd bar; buildPhase)
    '';
    
    # ...
}
````
Which will now call the overridden `buildPhase` and recurse infinitely until Bash crashes with a segfault.
To counter this, `commonPhaseImpl` will detect recursion from a phase to itself and fail the build with an error message,
instructing that the code here needs to be changed to `defaultBuildPhase`.

Of these three, only 3. needs immediate changes to out-of-tree code. The other two can be kept as a notice/warning for some time,
enabling users to write Nix expressions that are compatible with both old and new Nixpkgs versions simply by not migrating immediately.

# Drawbacks
[drawbacks]: #drawbacks

This proposal will (eventually) force some users to change their code as previously listed in the 'Backwards compatibility' section.

Nixpkgs developers will have to learn this new way of implementing phases.

# Alternatives
[alternatives]: #alternatives

An alternative which has been discussed at some point is to have a function like:
````sh
runPhase() {
    local phase="$1"
    eval "${!phase:-$phase}"
}
````
which would mean a nix-shell user would write e.g. `runPhase buildPhase` to run `buildPhase` and have it always work correctly.

While that would be an improvement to status quo, I don't feel that is a sufficient solution,
because there still would be a function `buildPhase` in scope, where running just `buildPhase` would work *sometimes*,
but silently do the wrong thing sometimes.

Not doing this RFC at all would also be an option, given that the issue being fixed is a pure UX issue, not fixing it wouldn't prevent any other work from happening.

# Unresolved questions
[unresolved]: #unresolved-questions

All resolved.

# Future work
[future]: #future-work

There's an open ticket (at https://github.com/NixOS/nixpkgs/issues/5483) titled 'Does it make sense for propagatedBuildInputs to get written out in fixupPhase?'
which point out that `propagatedBuildInputs` file doesn't get written out if `fixupPhase` is disabled.
This RFC opens the door for having some parts of a phase not user-overridable, which could be used to avoid the `propagatedBuildInputs`-not-written problem.
