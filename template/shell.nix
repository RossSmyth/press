{
  pkgs ? import <nixpkgs> { inherit system; },
  document ? import ./.,
}:
pkgs.mkShellNoCC {
  inputsFrom = [ document ];
  packages = [
    pkgs.tinymist
    pkgs.typstyle
  ];
}
