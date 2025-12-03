{
  lib,
  callPackage,
  buildEnv,
  stdenvNoCC,
  applyPatches,
  makeBinaryWrapper,
  typst,
  mkPackage,
  mkFonts,
  wrapTypst,
}:
let
  inherit (lib.asserts) assertMsg;
in
lib.extendMkDerivation {
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
      creationTimestamp ? null,
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
    let

      # Setup all the packages
      userPackages =
        let
          inherit (builtins) typeOf;
        in
        assert assertMsg (
          typeOf extraPackages == "set"
        ) "extraPackages must be of type 'AttributeSet List TypstPackage'";
        lib.attrsets.foldlAttrs (
          pkgs: namespace: paths:
          assert assertMsg (typeOf paths == "list") "the attrset values must be lists of typst packages";
          lib.lists.foldl (accum: src: accum ++ [ (mkPackage { inherit src namespace; }) ]) pkgs paths
        ) [ ] extraPackages;

      typstWrapped = wrapTypst {
        inherit creationTimestamp;
        fonts = mkFonts {
          inherit fonts name;
        };
        # User-defined Typst packages, not using pkgs.typstPackages
        userPackages = buildEnv {
          name = name + "-deps";
          pathsToLink = [ "/share/typst/packages" ];
          paths = userPackages;
        };
        # With nixpkgs typstPackages packages
        typst = typst.withPackages typstEnv;
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
      inherit (typstWrapped) shellHook;

      # The good stuff
      strictDeps = true;
      __structuredAttrs = true;

      nativeBuildInputs = args.nativeBuildInputs or [ ] ++ [ typstWrapped ];

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
      ++ lib.optionals (creationTimestamp != null) [
        "--creation-timestamp"
        (builtins.toString creationTimestamp)
      ]
      ++ [
        # This allows for files to reference files in adjacent directories.
        # See the test "project-root"
        "--root"
        ("/build/" + (builtins.baseNameOf finalAttrs.src))
        # Output format
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

      # Allow the user to access the wrapped Typst compiler
      passthru.typst-wrapped = typstWrapped;

      meta = meta // {
        badPlatforms = meta.badPlatforms or [ ] ++ typst.badPlatforms or [ ];
        platforms = lib.intersectLists meta.platforms or lib.platforms.all typst.meta.platforms or [ ];
      };
    };
}
