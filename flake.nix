{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    universe = {
      url = "github:typst/packages/main";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    universe,
  }: let
    overlay = (import ./.) universe;
  in {
    overlays = {
      default = overlay;
      buildTypst = overlay;
    };

    checks.x86_64-linux = let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [overlay];
      };
    in
      builtins.removeAttrs (pkgs.callPackage ./tests {}) ["override" "overrideDerivation"];

    devShells = let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
      };
    in {
      ${system}.default = pkgs.mkShell {
        stdenv = pkgs.stdenvNoCC;
        packages = let
          p = pkgs;
        in [
          p.nil
          p.alejandra
          p.typstyle
        ];
      };
    };
  };
}
