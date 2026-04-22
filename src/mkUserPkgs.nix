{
  lib,
  buildEnv,
}:
lib.extendMkDerivation {
  constructDrv = buildEnv;
  excludeDrvArgNames = [
    "userPackages"
  ];

  extendDrvArgs =
    finalAttrs:
    {
      userPackages,
      pname,
      version,
    }:
    {
      name = pname + version + "-fonts";
      pathsToLink = [ "/share/typst/packages" ];
      paths = userPackages;
    };
}
