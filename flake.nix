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
      };
    };
}
