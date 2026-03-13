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
    };
}
