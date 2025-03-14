final: prev: let
  inherit (final) lib typst symlinkJoin;

  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  uniGit = lock.nodes.universe.locked;
  universe = fetchTarball {
    url = "https://api.github.com/repos/${uniGit.owner}/${uniGit.repo}/tarball/${uniGit.rev}";
    sha256 = uniGit.narHash;
  };
in {
  buildTypstDocument = lib.extendMkDerivation {
    constructDrv = final.stdenvNoCC.mkDerivation;

    excludeDrvArgNames = ["extraPackages" "fonts"];

    extendDrvArgs = finalAttrs: {
      name ? "${args.pname}-${args.version}",
      src ? null,
      typstPatches ? [],
      patches ? [],
      logLevel ? "",
      buildInputs ? [],
      nativeBuildInputs ? [],
      meta ? {},
      fonts ? [],
      typstUniverse ? true,
      extraPackages ? {},
      file ? "main.typ",
      format ? "pdf",
      ...
    } @ args: let
      universe' = lib.optionalString typstUniverse ''
        mkdir -p $XDG_DATA_HOME/typst/packages
        cp -r ${universe}/packages/preview $XDG_DATA_HOME/typst/packages/
      '';

      userPackages = lib.attrsets.foldlAttrs (shString: namespace: paths:
        lib.lists.foldl (accum: path: let
          manifest = lib.importTOML "${path}/typst.toml";
          version = manifest.package.version or (throw "${path}/typst.toml missing version field");
          name = manifest.package.name or (throw "${path}/typst.toml missing name field");
        in
          accum
          + ''
            mkdir -p $XDG_DATA_HOME/typst/packages/${namespace}/${name}/${version}
            cp -r ${path}/* $XDG_DATA_HOME/typst/packages/${namespace}/${name}/${version}
          '')
        shString
        paths) ""
      extraPackages;

      fontsDrv = symlinkJoin {
        name = "typst-fonts";
        paths = fonts;
        stripPrefix = "/share/fonts";
      };
    in {
      nativeBuildInputs = nativeBuildInputs ++ [typst];
      patches = typstPatches ++ patches;
      strictDeps = true;

      env.TYPST_FONT_PATHS = "${fontsDrv}";
      
      buildPhase =
        args.buildPhase
        or (''
            runHook preBuild

            export XDG_DATA_HOME=$(mktemp -d)
          ''
          + universe'
          + userPackages
          + ''
            typst c ${file} -f ${format} $out

            runHook postBuild
          '');

      meta =
        meta
        // {
          badPlatforms = meta.badPlatforms or [] ++ typst.badPlatforms or [];
          platforms = lib.intersectLists meta.platforms or lib.platforms.all typst.meta.platforms or [];
        };
    };
  };
}
