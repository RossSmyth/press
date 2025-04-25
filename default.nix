final: prev:
let
  inherit (final)
    lib
    stdenvNoCC
    buildEnv
    applyPatches
    makeBinaryWrapper
    callPackage
    typst
    ;
  inherit (final.xorg) lndir;
  inherit (lib.asserts) assertMsg;

  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  uniGit = lock.nodes.universe.locked;
  universe = fetchTarball {
    url = "https://api.github.com/repos/${uniGit.owner}/${uniGit.repo}/tarball/${uniGit.rev}";
    sha256 = uniGit.narHash;
  };
in
{
  buildTypstDocument = lib.extendMkDerivation {
    # No need for CC here
    constructDrv = stdenvNoCC.mkDerivation;

    # IDK exactly but at least extraPackages is required
    # or things break.
    excludeDrvArgNames = [
      "extraPackages"
      "fonts"
      "typstEnv"
    ];

    # All the drv args
    # Put sane defualts.
    extendDrvArgs =
      finalAttrs:
      {
        name ? "${args.pname}-${args.version}",
        verbose ? false,
        meta ? { },
        fonts ? [ ],
        typstEnv ? (_: [ ]),
        extraPackages ? { },
        file ? "main.typ",
        format ? "pdf",
        ...
      }@args:
      assert assertMsg (builtins.elem format [
        "pdf"
        "html"
      ]) "Typst only supports html or pdf output.";
      let
        userPackages =
          let
            inherit (builtins) typeOf;
            
            userPack = callPackage ./src/mkPackage.nix;
          in
          assert assertMsg (typeOf extraPackages == "set") "extraPackages must be of type AttributeSet[String, List[TypstPackage]]";
            lib.attrsets.foldlAttrs (
              pkgs: namespace: paths:
              assert assertMsg (typeOf paths == "list") "the attrset values must be lists of typst packages";
                lib.lists.foldl (accum: src: accum ++ [ (userPack { inherit src namespace; }) ]) pkgs paths
            ) [ ] extraPackages;

        # All fonts in nixpkgs should follow this.
        fontsDrv = callPackage ./src/mkFonts.nix { inherit fonts name; };

        # Combine all the packages to one drv
        pkgsDrv = buildEnv {
          name = name + "-deps";
          pathsToLink = [ "/share/typst/packages"];
          paths = userPackages;
        };

        typstWrap =
          let
            typstUni = typst.withPackages typstEnv;
          in
          stdenvNoCC.mkDerivation {
            strictDeps = true;
            dontUnpack = true;
            dontConfigure = true;
            dontInstall = true;

            name = "typst-wrapped";
            buildInputs = [ makeBinaryWrapper ];
            buildPhase = ''
              runHook preBuild

              makeWrapper ${lib.getExe typstUni} $out/bin/typst \
                --prefix TYPST_FONT_PATHS : ${fontsDrv}/share/fonts \
                --set TYPST_PACKAGE_PATH ${pkgsDrv}/share/typst/packages

              runHook postBuild
            '';
            meta.mainProgram = "typst";
          };
      in
      {
        nativeBuildInputs = args.nativeBuildInputs or [ ] ++ [ typstWrap ];
        strictDeps = true;

        buildPhase =
          args.buildPhase or ''
            runHook preBuild

            typst c ${file} ${lib.optionalString verbose "--verbose"} ${
              lib.optionalString (format == "html") "--features html"
            } -f ${format} $out

            runHook postBuild
          '';

        meta = meta // {
          badPlatforms = meta.badPlatforms or [ ] ++ typst.badPlatforms or [ ];
          platforms = lib.intersectLists meta.platforms or lib.platforms.all typst.meta.platforms or [ ];
        };
      };
  };
}
