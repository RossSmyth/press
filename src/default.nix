{
  lib,
  newScope,
}:
lib.makeScope newScope (self: {
  mkFonts = self.callPackage ./mkFonts.nix { };
  mkUserPackages = self.callPackage ./mkUserPkgs.nix { };
  mkPackage = self.callPackage ./mkPackage.nix { };
  wrapTypst = self.callPackage ./wrap-typst.nix { };

  buildTypstDocument = self.callPackage ./buildTypstDocument.nix { };
})
