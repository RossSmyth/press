# All Typst packages will follow the output of $out/share/typst/packages/$NAMESPACE/$NAME/$VERSION
{
  # This path must have a "typst.toml" in the top-level
  src,
  namespace ? "local",

  lib,
  symlinkJoin,
}:
let
  manifest = lib.importTOML "${src}/typst.toml";
  version = manifest.package.version or (throw "${src}/typst.toml missing version field");
  name = manifest.package.name or (throw "${src}/typst.toml missing name field");
in
symlinkJoin {
  name = name + "-typstPkg";
  paths = [
    "${src}"
  ];
  postBuild = ''
    shopt -s extglob
    mkdir -p $out/share/typst/packages/${namespace}/${name}/${version}

    mv $out/!(share) "$out/share/typst/packages/${namespace}/${name}/${version}"
  '';
}
