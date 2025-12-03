# All Typst packages will follow the output of $out/share/typst/packages/$NAMESPACE/$NAME/$VERSION
{
  lib,
  symlinkJoin,
  # This path must have a "typst.toml" in the top-level
  src,
  namespace ? "local",
  # To remove IFD
  version ? "",
  pname ? "",
}:
let
  # IFD :( I forgot I did this.
  manifest = lib.importTOML "${src}/typst.toml";
  pkgVersion =
    if version != "" then
      version
    else
      manifest.package.version or (throw "${src}/typst.toml missing version field");
  pkgName =
    if pname != "" then
      pname
    else
      manifest.package.name or (throw "${src}/typst.toml missing name field");
in
symlinkJoin {
  pname = pkgName;
  version = pkgVersion;

  paths = [
    "${src}"
  ];

  postBuild = ''
    shopt -s extglob
    mkdir -p $out/share/typst/packages/${namespace}/${pkgName}/${pkgVersion}

    mv $out/!(share) "$out/share/typst/packages/${namespace}/${pkgName}/${pkgVersion}"
  '';
}
