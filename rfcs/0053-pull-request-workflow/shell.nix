with import <nixpkgs> {};

stdenv.mkDerivation rec {

  name = "rfc-53";

  env = buildEnv {
    name = name;
    paths = buildInputs;
  };

  buildInputs = [
    yed
  ];

}
