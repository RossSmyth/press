{
  lib,
  newScope,
}:
lib.makeScope newScope (self: {
  mkFonts = args: self.callPackage ./mkFonts.nix args;
  mkPackage = args: self.callPackage ./mkPackage.nix args;
  mkUserPackages = args: self.callPackage ./mkUserPkgs.nix args;
  wrapTypst = self.callPackage ./wrap-typst.nix { };

  buildTypstDocument = self.callPackage ./buildTypstDocument.nix { };
})
