# All Typst packages will follow the output of $out/share/typst/packages/$NAMESPACE/$NAME/$VERSION
{
  lib,
  stdenvNoCC,
}:
lib.extendMkDerivation {
  constructDrv = stdenvNoCC.mkDerivation;

  excludeDrvArgNames = [
    "namespace"
    "meta"
  ];

  extendDrvArgs =
    finalAttrs:
    {
      pname,
      version,
      src,
      namespace ? "local",
      meta ? { },
    }@args:
    {
      __structuredAttrs = true;

      pkgpath = "${placeholder "out"}/share/typst/packages/${namespace}/${finalAttrs.pname}/${finalAttrs.version}";

      installPhase = ''
        runHook preInstall

        mkdir -p "$pkgpath"

        cp -r . "$pkgpath"

        runHook postInstall
      '';

      meta = {
        platforms = lib.platforms.all;
        homepage = if src ? url then src.url else null;
      }
      // meta;
    };
}
