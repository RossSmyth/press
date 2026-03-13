{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    press.url = "github:RossSmyth/press";
  };

  outputs =
    {
      self,
      nixpkgs,
      press,
    }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        overlays = [ (import press) ];
      };

      fs = pkgs.lib.fileset;

      files = fs.unions [
        ./main.typ
      ];
    in
    {
      packages.${system}.default = pkgs.buildTypstDocument {
        pname = "someDoc";
        version = "1.0";

        src = fs.toSource {
          root = ./.;
          fileset = files;
        };
      };
    };
}
