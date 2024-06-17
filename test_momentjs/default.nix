with import <nixpkgs> {};

stdenv.mkDerivation rec {
  name = "nodejs-environment";
  buildInputs = [ nodejs_20 ];
}
