# Press
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/RossSmyth/press/.github%2Fworkflows%2Fmain.yml?branch=main&style=for-the-badge)

A library for building Typst documents with Nix. Goals:

1. Hermetic document building
2. Support non-Typst Universe packages

## Status

Usable. Needs a few more things before I'd say it's "complete," but it does build documents.

## Usage

Just import the overlay.

```nix
pkgs = import nixpkgs {
  overlays = [ (import press) ];
};
...
document = pkgs.buildTypstDocument {
  name = "myDoc";
  src = ./.;
};
```

If you want to use a non-Universe package:
```nix
documents = pkgs.buildTypstDocument {
  name = "myDoc";
  src = ./.;
  extraPackages = {
    local = [ somePackage anotherPack ];
    foospace = [ fooPackage ];
  };
};
```

If you want to use custom fonts:
```nix
documents = pkgs.buildTypstDocument {
  name = "myDoc";
  src = ./.;
  fonts = [
    pkgs.roboto
  ];
};
```
Where `local` is the package namespace, and `somePackage` is a store path that has a `typst.toml` file in it.
You can put packages in whatever namespace you want, not just local.

See the [template](./template/flake.nix) for more API details.
