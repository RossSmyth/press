{
  lib,
  newScope,
}:
lib.makeScope newScope (self: {
  # TODO: When https://github.com/NixOS/nixpkgs/pull/432957 is merged,
  # make this fixed-point helpers rather than these weirdos
  mkFonts = self.callPackage ./mkFonts.nix;
  mkUserPackages = self.callPackage ./mkUserPkgs.nix;
  mkPackage = self.callPackage ./mkPackage.nix { };
  wrapTypst = self.callPackage ./wrap-typst.nix { };

  buildTypstDocument = self.callPackage ./buildTypstDocument.nix { };
})
