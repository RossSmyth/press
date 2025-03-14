{
  buildTypstDocument,
  fetchFromGitHub,
  fira-code,
  inconsolata,
}: {
  basic = buildTypstDocument (self: {
    name = "basic";
    src = ./documents;
    typstUniverse = false;
    file = "basic.typ";
  });

  imports = buildTypstDocument (self: {
    name = "import";
    src = ./documents;
    file = "import.typ";
  });

  fonts = buildTypstDocument (self: {
    name = "fonts";
    src = ./documents;
    file = "fonts.typ";
    fonts = [
      fira-code
      inconsolata
    ];
  });
  
  gitImport = buildTypstDocument (self: {
    name = "gitImport";
    src = ./documents;
    file = "gitImport.typ";
    extraPackages = {
      local = [
        (fetchFromGitHub {
          owner = "FlandiaYingman";
          repo = "note-me";
          rev = "03310b70607e13bdaf6928a6a9df1962af1005ff";
          hash = "sha256-Bpmdt59Tt4DNBg8G435xccH/W3aYSK+EuaU2ph2uYTY=";
        })
      ];
    };
  });
}
