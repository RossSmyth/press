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
in
{
  buildTypstDocument = lib.extendMkDerivation {
    # No need for CC here
    constructDrv = stdenvNoCC.mkDerivation;

    # No need to expose really anything.
    excludeDrvArgNames = [
      "verbose"
      "fonts"
      "typstEnv"
      "extraPackages"
      "file"
      "inputs"
      "format"
      "pages"
      "pdfTags"
      "pngPpi"
      "pdfStandards"
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
        inputs ? { },
        format ? "pdf",
        pages ? [ ],
        pdfTags ? true,
        pngPpi ? null,
        pdfStandards ? [ ],
        ...
      }@args:

      # Everything Typst supports
      assert assertMsg (builtins.elem format [
        "pdf"
        "html"
        "svg"
        "png"
      ]) "Typst supports pdf, png, svg, and png output formats.";

      let

        # Setup all the packages
        userPackages =
          let
            inherit (builtins) typeOf;

            userPack = callPackage ./src/mkPackage.nix;
          in
          assert assertMsg (
            typeOf extraPackages == "set"
          ) "extraPackages must be of type AttributeSet[String, List[TypstPackage]]";
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
          pathsToLink = [ "/share/typst/packages" ];
          paths = userPackages;
        };
        typstUni = typst.withPackages typstEnv;

        # A wrapped Typst compiler, this is needed for
        # the dev shell
        typstWrap = stdenvNoCC.mkDerivation {
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

        # Put the inputs in the right format
        typstInputs = lib.pipe inputs [
          (lib.mapAttrsToList (
            name: value: [
              "--input"
              "${name}=${value}"
            ]
          ))
          lib.flatten
        ];
      in
      {
        # The good stuff
        strictDeps = true;
        __structuredAttrs = true;

        nativeBuildInputs = args.nativeBuildInputs or [ ] ++ [ typstWrap ];

        typstArgs = [
          "c"
          "${file}"
        ]
        ++ lib.optionals verbose [
          "--verbose"
        ]
        ++ lib.optionals (format == "html") [
          "--features"
          "html"
        ]
        ++ typstInputs
        ++ lib.optionals (pages != [ ]) [
          "--pages"
          (lib.concatStringsSep "," pages)
        ]
        ++ lib.optionals (!pdfTags) [
          "--no-pdf-tags"
        ]
        ++ lib.optionals (pngPpi != null) [
          "--ppi"
          (builtins.toString pngPpi)
        ]
        ++ lib.optionals (pdfStandards != [ ]) [
          "--pdf-standard"
          (lib.concatStringsSep "," pdfStandards)
        ]
        ++ [
          "-f"
          format
        ];

        buildPhase =
          args.buildPhase or ''
            runHook preBuild

            echo "Calling Typst with 'typst ''${typstArgs[@]}'"
            typst "''${typstArgs[@]}" $out

            runHook postBuild
          '';

        shellHook = ''
          export TYPST_PACKAGE_CACHE_PATH="${typstUni}/lib/typst/packages"
          export TYPST_PACKAGE_PATH="${pkgsDrv}/share/typst/packages"
          export TYPST_FONT_PATHS="${fontsDrv}/share/fonts"
        '';

        # Allow the user to access the wrapped Typst compiler
        passthru.typst-wrapped = typstWrap;

        meta = meta // {
          badPlatforms = meta.badPlatforms or [ ] ++ typst.badPlatforms or [ ];
          platforms = lib.intersectLists meta.platforms or lib.platforms.all typst.meta.platforms or [ ];
        };
      };
  };
}
