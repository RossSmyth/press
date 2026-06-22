let
  inputs = import ./npins { };
  pkgs = import inputs.nixpkgs {
    system = builtins.currentSystem or "x86_64-linux";
    overlays = [
      (import ../.)
    ];
  };
  inherit (pkgs)
    lib
    buildTypstDocument
    fetchFromGitHub
    fira-code
    inconsolata
    pdfcpu
    jq
    writableTmpDirAsHomeHook
    ripgrep
    imagemagick
    ;

  note-me = fetchTree {
    type = "github";
    narHash = "sha256-Bpmdt59Tt4DNBg8G435xccH/W3aYSK+EuaU2ph2uYTY=";
    owner = "FlandiaYingman";
    repo = "note-me";
    rev = "03310b70607e13bdaf6928a6a9df1962af1005ff";
  };

  note-meGh = fetchFromGitHub {
    inherit (note-me) rev;
    hash = note-me.narHash;
    owner = "FlandiaYingman";
    repo = "note-me";
  };

  mkTest = lib.extendMkDerivation {
    constructDrv = buildTypstDocument;

    excludeDrvArgNames = [
      "name"
    ];

    extendDrvArgs =
      finalAttrs:
      {
        name,
        file ? name + ".typ",
        src ? ./documents,
        ...
      }:
      {
        pname = name + "-test";
        version = "none";
        inherit file src;
      };
  };
in
{
  basic = mkTest {
    name = "basic";
  };

  imports = mkTest {
    name = "import";
    typstEnv = p: [ p.note-me_0_5_0 ];
  };

  fonts = mkTest {
    name = "fonts";
    fonts = [
      fira-code
      inconsolata
    ];

    nativeCheckInputs = [
      ripgrep
      jq
      pdfcpu
      writableTmpDirAsHomeHook
    ];
    doCheck = true;
    checkPhase = ''
      set -eu
      # pdfpcu requires a .pdf extension for now
      # And you must run it once first so that it does some useless things otherwise it outputs junk json
      cp "$out" out.pdf
      pdfcpu version

      pdfcpu --offline info --fonts --json out.pdf | jq '.infos[0].fonts.[].name'
      pdfcpu --offline info --fonts --json out.pdf | jq '.infos[0].fonts.[].name' | rg FiraCode
      pdfcpu --offline info --fonts --json out.pdf | jq '.infos[0].fonts.[].name' | rg Inconsolata
    '';
  };

  patch = mkTest {
    name = "patch";
    patches = [
      ./patch.patch
    ];
  };

  html = mkTest {
    name = "html";
    format = "html";
    doCheck = true;
    checkPhase = ''
      set -eu
      grep "html" "$out"
    '';
  };

  png = mkTest {
    name = "png";
    file = "html.typ";
    format = "png";
    doCheck = true;
    checkPhase = ''
      set -eu
      mime=
      mime=$(file -b --mime-type "$out")

      if [[ $mime != "image/png" ]]; then
        echo "mime is: $mime"
        exit 1
      fi
    '';
  };

  svg = mkTest {
    name = "svg";
    file = "html.typ";
    format = "svg";
    doCheck = true;
    checkPhase = ''
      set -eu
      grep "svg" "$out"
    '';
  };

  gitImport = mkTest {
    name = "gitImport";
    extraPackages = {
      local = [ note-me ];
    };
  };

  gitImportAttrStr = mkTest {
    name = "gitImport";
    extraPackages = {
      local = [ "${note-me}" ];
    };
  };

  githubFetch = mkTest {
    name = "githubFetch";
    file = "gitImport.typ";
    extraPackages = {
      local = [ note-meGh ];
    };
  };

  inputs = mkTest {
    name = "inputs";
    inputs = {
      language = "en";
      name = "John Doe";
    };
  };

  pages = mkTest {
    name = "pages";
    pages = [
      "1"
      "3-6"
    ];
    doCheck = true;
    nativeCheckInputs = [
      writableTmpDirAsHomeHook
      pdfcpu
      jq
    ];
    checkPhase = ''
      set -eu

      pdfcpu version

      cp "$out" out.pdf

      pdfcpu info --fonts --json out.pdf | jq '.infos[0].pageCount'
      if [[ "$(pdfcpu info --fonts --json out.pdf | jq '.infos[0].pageCount')" -ne 5 ]]; then
        echo "Number of pages detected: $numPages"
        exit 1
      fi
    '';
  };

  ppi = mkTest {
    name = "png-ppi";
    file = "basic.typ";
    format = "png";
    pngPpi = 100;
    doCheck = true;
    nativeCheckInputs = [ imagemagick ];
    # Hardcoded resolution since Typst does not set the units
    checkPhase = ''
      identify -verbose "$out" | grep 1169
    '';
  };

  standards = mkTest {
    name = "pdf-standards";
    file = "basic.typ";
    pdfStandards = [
      "1.4"
    ];
  };

  timestamp = mkTest {
    name = "timestamp";
    creationTimestamp = 1;
  };

  project-root = mkTest {
    name = "project-root";
    src = ./documents/project-root;
    file = "mydoc/main.typ";
  };

  no-ifd = mkTest {
    name = "no-ifd";
    file = "gitImport.typ";
    extraPackages = {
      local = [
        {
          pname = "note-me";
          version = "0.5.0";
          src = note-me;
        }
      ];
    };
  };

  single-file = mkTest {
    name = "single-file";
    src = lib.fileset.toSource {
      root = ./documents;
      fileset = ./documents/basic.typ;
    };
    file = "basic.typ";
  };
}
