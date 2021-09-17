# with import ../config.nix;
with import <nixpkgs> {};
with pkgs;
with stdenv;

# A simple content-addressed derivation.
# The derivation can be arbitrarily modified by passing a different `seed`,
# but the output will always be the same
rec {
  root = mkDerivation {
    # Name must be identical to the name of "dependent" because the name is
    # part of the hash scheme
    name = "text-hashed-root";
    buildCommand = ''
      set -x
      echo "Building a CA derivation"
      mkdir -p $out
      echo "Hello World" > $out/hello
    '';
    __contentAddressed = true;
    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
  };
  recursive-test = mkDerivation {
    name = "dir-of-text-hashed-root";
    buildCommand = ''
      echo "Copying the derivation"
      export NIX_PATH=nixpkgs=${pkgs.path}

      # replace this with assumeDerivation
      # nix-instantiate is okay, not nix-build
      # does assumeDerivation enforces the "tail-call recursion"

      # HASH=$(readLockFile {./Go.mod} {./go.sum})

      # builtins.fetchThisForMe
      # builtins.instantiate

      # Pros
      # cleaner
      # no nested builds, only instantiation
      # easier to stabilize

      # Cons
      # not same power?

      # 1) recursive-nix
      # 2) RFC92 can output .drv
      # 3) "full recursive-nix": complexity

      # ninja2nix, splice Nix into derivations

      THING=$(${pkgs.nix}/bin/nix-instantiate -E '
         derivation {
          name = "text-hashed-root";
          system = "x86_64-linux";
          builder = "/bin/sh";
          args = ["-c" "echo hi there ''${(import <nixpkgs>{}).blender} > $out"];

          ## Assert that .drv IS a derivation and _contentAddressed, correct everything

          __contentAddressed = true;
          outputHashMode = "recursive"; # flat (hash a file), text, recursive (hash a dir)
          outputHashAlgo = "sha256";
         }')

      mkdir $out
      echo $THING
      cp $THING $out/out1
      cp $THING $out/out2
    '';
    outputs = ["out" ];
    __contentAddressed = true; outputHashMode = "recursive"; outputHashAlgo = "sha256";
  };
  nixSourceGenerator ::: drv -> Nix Source Code
  nixSourceGenerator = drv: runCommand some_name {} ''
    export NIX_PATH=nixpkgs=${pkgs.path}
    cat > $out <<EOF
      derivation {
       name = "text-hashed-root";
       system = "x86_64-linux";
       builder = "/bin/sh";
       args = ["-c" "echo hi there ''${(import <nixpkgs>{}).${drv.buildInputs.pname} > $out"];
       __contentAddressed = true;
       outputHashMode = "recursive";
       outputHashAlgo = "sha256";
      }')
    EOF
    '';


  dependent2 = mkDerivation { # {{{
    name = "text-hashed-root.drv";
    buildCommand = ''
      echo "Link the derivation"
      ln -s ${root.drvPath} $out
    '';
    # Can we link it instead? It will resolve symlink?
    __contentAddressed = true;
    outputHashMode = "text";
    outputHashAlgo = "sha256";
  }; # }}}

  # Part two allows this?
  #splitter-new = builtins.assumeDerivation dependent;

  # this is awkward, needs the right name
  splitter = mkDerivation {
    name = "text-hashed-root.drv";
    buildCommand = ''
      cp ${recursive-test}/out2 $out
    '';
    __contentAddressed = true; outputHashMode = "text"; outputHashAlgo = "sha256";
    # BUG outputHashMode is not used?
    # contentAddressed T/F is not checked?
  };
  wrapper = mkDerivation {
    name = "put-it-all-together";
    buildCommand = ''
      echo "Copying the output of the dynamic derivation"
      cp -r ${builtins.outputOf splitter.out "out"} $out
    '';
    __contentAddressed = true; outputHashMode = "recursive"; outputHashAlgo = "sha256";
  };
}
