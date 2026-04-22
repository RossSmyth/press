{
  lib,
  buildEnv,
}:
lib.extendMkDerivation {
  constructDrv = buildEnv;
  excludeDrvArgNames = [
    "fonts"
  ];

  extendDrvArgs =
    finalAttrs:
    {
      fonts,
      pname,
      version,
    }:
    {
      name = pname + version + "-fonts";
      paths = fonts;
    };
}
