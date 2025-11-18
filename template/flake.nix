{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    press = {
      url = "github:RossSmyth/press";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Put your non-Universe packages in the input section
    # Declare them to not be a flake.
    #
    # You can also use normal FODs like fetchFromGithub
    unify = {
      url = "github:ChHecker/unify";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      press,
      unify,
    }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        overlays = [ (import press) ];
      };
    in
    {
      packages.${system}.default = pkgs.buildTypstDocument {
        # [Optional] The name of the derivation
        # Default: ${pname}-${version}
        name = "example";
        # Source directory to copy to the store.
        src = ./.;
        # [Optional] The entry-point to the document, default is "main.typ"
        # This is relative to the directory input above.
        # Default: "main.typ"
        file = "main.typ";
        # [Optional] Key-value attribute set passed as --input arguments to typst
        # (available as the `sys.inputs` dictionary)
        inputs = {
          "language" = "fr";
        };
        # [Optional] Typst universe package selection
        #
        # Pass in a function that accept an attrset of Typst pacakges,
        # and returns a list of packages.
        #
        # The input parameter is from the pkgs.typstPackages attributes
        # in nixpkgs. See this section of the nixpkgs reference for patching
        # and overriding
        # https://nixos.org/manual/nixpkgs/unstable/#typst
        #
        # Default: (_: [])
        typstEnv = (p: [ p.note-me ]);
        # [Optional] Any non-universe packages. The attribute key is the namespace.
        # The package must have a typst.toml file in its root.
        # Default: {}
        extraPackages = {
          local = [ unify ];
        };
        # [Optional] The format to output
        # Default: "pdf"
        # Can be either "pdf", "html", "svg", or "png"
        format = "pdf";
        # [Optional] The fonts to include in the build environment
        # Note that they must follow the standard of nixpkgs placing fonts
        # in $out/share/fonts/. Look at Inconsolta or Fira Code for reference.
        # Default: []
        fonts = [
          pkgs.roboto
        ];
        # [Optional] Whether to have a verbose Typst compilation session
        # Default: false
        verbose = false;
        # [Optional, String]
        # Pages to export. See Typst documentation for the format. Automatically
        # inserts commas.
        #
        # Examples:
        #
        # Only export pages 2 and 5
        # pages = [ "2" "5" ];
        #
        # Export pages 2, 3 through 6 (inclusive), and then page 8 and any pages after
        # pages = [ "2" "3-6" "8-" ]
        pages = [ ];
      };

      devShells.${system}.default = pkgs.mkShellNoCC {
        inputsFrom = [ self.packages.${system}.default ];
        packages = [
          pkgs.tinymist
          pkgs.typstyle
        ];
      };
    };
}
