{
  buildEnv,
  name,
  userPackages,
}:
buildEnv {
  name = name + "-deps";
  pathsToLink = [ "/share/typst/packages" ];
  paths = userPackages;
}
