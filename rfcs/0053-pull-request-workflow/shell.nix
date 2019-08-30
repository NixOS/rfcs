with import <nixpkgs> {};

stdenv.mkDerivation rec {

  name = "nixos-diagrams";

  env = buildEnv {
    name = name;
    paths = buildInputs;
  };

  buildInputs = [
    feh
    plantuml
    yed
  ];

  shellHook = ''
    HISTFILE=${toString ./.}/.history
  '';

}
