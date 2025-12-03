{
  lib,
  pkgsBuildBuild,
  callPackage,
  buildEnv,
  stdenvNoCC,
  applyPatches,
  makeBinaryWrapper,
  mkPackage,
  mkFonts,
  mkUserPackages,
  wrapTypst,
}:
let
  inherit (lib.asserts) assertMsg;

  # This copies the stripHash algorthim for all intents and purposes
  stripHash =
    path:
    lib.pipe path [
      builtins.baseNameOf
      (path: if lib.match "^[a-z0-9]{32}-.*" path == [ ] then lib.substring 33 (-1) path else path)
    ];
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
      nativeBuildInputs ? [ ],
      ...
    }@args:
    let
      # Setup all the packages
      #
      # TODO: When breaking changes are done, only accept packages that are
      # built with `pkgs.buildTypstPackge`. More work on the Nixpkgs side is
      # needed before that.
      userPackages =
        assert assertMsg (
          lib.isAttrs extraPackages && lib.all lib.isList (lib.attrValues extraPackages)
        ) "extraPackages must be of type 'AttributeSet (List TypstPackage)'";

        lib.pipe extraPackages [
          (lib.attrsets.mapAttrsToList (
            namespace:
            lib.map (
              pkgSpec:
              # Backwards compat for IFD usage
              if lib.isStorePath pkgSpec then
                let
                  manifest = lib.importTOML "${pkgSpec}/typst.toml";
                in
                mkPackage {
                  inherit namespace;
                  pname = manifest.package.name or (throw "${pkgSpec}/typst.toml missing package name");
                  version = manifest.package.version or (throw "${pkgSpec}/typst.toml missing version");
                  src = pkgSpec;
                }
              else
                mkPackage (
                  {
                    inherit namespace;
                  }
                  // pkgSpec
                )
            )
          ))

          lib.flatten
        ];

      typstWrapped = wrapTypst {
        inherit creationTimestamp;
        fonts = mkFonts {
          inherit (finalAttrs) name;
          inherit fonts;
        };
        # User-defined Typst packages, not using pkgs.typstPackages
        userPackages = mkUserPackages {
          inherit (finalAttrs) name;
          inherit userPackages;
        };
        # With nixpkgs typstPackages packages
        # Typst does not have target, so we just use the build platform's Typst so
        # it never tries to do anything weird like fail to build a PDF when targeting
        # something.
        typst = pkgsBuildBuild.typst.withPackages typstEnv;
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

      nativeBuildInputs = nativeBuildInputs ++ [ typstWrapped ];

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
        # Set root so adjacent directories can be used
        # Sandbox looks like `/build/$source-directory-name`
        "--root"
        "/build/${stripHash finalAttrs.src}"
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
        # bruh it's a PDF
        platforms = lib.platforms.all;
      };
    };
}
