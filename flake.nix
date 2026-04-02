{
  description = "A helper for building Typst document and importing non-Universe packages";
  outputs =
    {
      self,
    }:
    let
      overlay = import ./.;
    in
    {
      overlays = {
        default = overlay;
        buildTypst = overlay;
      };

      templates.default = {
        path = ./template;
        description = "A basic template using Press";
        welcomeText = ''
          # Getting started
          - run `npins init`
          - run `npins add github RossSmyth press --branch main`
          - run `npins add github ChHecker unify --branch main`

          Enjoy!
        '';
      };

      templates.flake = {
        path = ./flakeTemplate;
        description = "flake template";
      };
      checks.x86_64-linux =
      let
        tests = import ./tests/default.nix;
      in {
        inherit (tests)
          basic
          imports
          fonts
          patch
          html
          png
          svg
          gitImport
          gitImportAttrStr
          githubFetch
          inputs
          pages
          ppi
          standards
          timestamp
          project-root
          no-ifd
          single-file;
      };
    };
}
