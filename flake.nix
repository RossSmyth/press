{
  description = "A helper for building Typst document and importing non-Universe packages";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      overlay = import ./.;
    in
    {
      overlays = {
        default = overlay;
        buildTypst = overlay;
      };

      checks.x86_64-linux =
        let
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            overlays = [ (import self) ];
          };
        in
        builtins.removeAttrs (pkgs.callPackage ./tests { }) [
          "override"
          "overrideDerivation"
        ];

      templates.default = {
        path = ./template;
        description = "A basic template using Press";
      };

      devShells =
        let
          system = "x86_64-linux";
          pkgs = import nixpkgs {
            inherit system;
          };
        in
        {
          ${system}.default = pkgs.mkShell {
            stdenv = pkgs.stdenvNoCC;
            packages =
              let
                p = pkgs;
              in
              [
                p.nil
                p.nixfmt-tree
                p.typstyle
              ];
          };
        };
    };
}
