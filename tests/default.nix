{
  lib,
  buildTypstDocument,
  fetchFromGitHub,
  fira-code,
  inconsolata,
  ripgrep,
  qpdf,
  imagemagick,
}:
let
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

    extendDrvArgs =
      finalAttrs:
      {
        name,
        file ? finalAttrs.name + ".typ",
        ...
      }@args:
      {
        inherit file;
        src = ./documents;
      };
  };
in
{
  basic = mkTest {
    name = "basic";
  };

  imports = mkTest {
    name = "import";
    typstEnv = p: [ p.note-me ];
  };

  fonts = mkTest {
    name = "fonts";
    fonts = [
      fira-code
      inconsolata
    ];

    nativeCheckInputs = [
      ripgrep
    ];
    doCheck = true;
    checkPhase = ''
      set -eu
      rg --binary "BaseFont [^\.]*FiraCode" $out
      rg --binary "BaseFont [^\.]*Inconsolata" $out
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
    nativeCheckInputs = [ qpdf ];
    checkPhase = ''
      numPages=$(qpdf --show-npages "$out")
      if [[ $numPages != "5" ]]; then
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
}
