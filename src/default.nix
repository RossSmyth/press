{
  lib,
  newScope,
}:
lib.makeScope newScope (self: {
  mkFonts = args: self.callPackage ./mkFonts.nix args;
  mkPackage = args: self.callPackage ./mkPackage.nix args;

  buildTypstDocument = self.callPackage ./buildTypstDocument.nix { };
})
