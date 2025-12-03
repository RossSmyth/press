{
  lib,
  stdenvNoCC,
  makeBinaryWrapper,
}:
lib.extendMkDerivation {
  constructDrv = stdenvNoCC.mkDerivation;

  excludeDrvArgNames = [
    "fonts"
    "userPackages"
    "typst"
  ];

  inheritFunctionArgs = false;
  extendDrvArgs =
    finalAttrs:
    {
      fonts,
      userPackages,
      typst,
      creationTimestamp ? null,
    }:
    {
      strictDeps = true;
      dontUnpack = true;
      dontConfigure = true;
      dontInstall = true;

      name = "typst-wrapped";
      buildInputs = [ makeBinaryWrapper ];
      buildPhase = ''
        runHook preBuild

        makeWrapper ${lib.getExe typst} $out/bin/typst \
          --prefix TYPST_FONT_PATHS : ${fonts}/share/fonts \
          --set TYPST_PACKAGE_PATH ${userPackages}/share/typst/packages

        runHook postBuild
      '';

      shellHook = ''
        export TYPST_PACKAGE_CACHE_PATH="${typst}/lib/typst/packages"
        export TYPST_PACKAGE_PATH="${userPackages}/share/typst/packages"
        export TYPST_FONT_PATHS="${fonts}/share/fonts"
        export SOURCE_DATE_EPOCH=${
          if creationTimestamp != null then builtins.toString creationTimestamp else "315532800"
        }
      '';

      # Use the base Typst's meta block, but use this Typst's position.
      meta = builtins.removeAttrs typst.meta [ "position" ];
    };
}
