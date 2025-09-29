# Press
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/RossSmyth/press/.github%2Fworkflows%2Fmain.yml?branch=main&style=for-the-badge)

A library for building Typst documents with Nix. Goals:

1. Hermetic document building
2. Support non-Typst Universe packages
3. Easy devShell support, just use `inputsFrom` and it supports your packages and fonts with incremental development.
4. Integrates with Nixpkg's `typstPackages` 
5. Supports key-values inputs (Typst's `sys.inputs` dictionary)
6. Nixpkg's fonts

## Status

Basically done. In "maintenence mode". Let me know if you find any issues or have feature requests.

See the [template](./template/flake.nix) for full API details and documentation.

Limitations:

- Cannot automatically detect third-party package dependencies (i.e. through the `extraPackages` attribute)

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

With Nixpkg's [Typst Universe integration](https://search.nixos.org/packages?channel=unstable&show=typstPackages.note-me&query=note-me):
```nix
document = pkgs.buildTypstDocument {
  name = "myDoc";
  src = ./.;
  # Adds note-me from Nixpkgs
  typstEnv = p: [ p.note-me ];
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

Then for a devShell:
```nix
devShell = mkShell {
  inputsFrom = [ document ];
  packages = [
    tinymist
    typstyle
  ];
};
```

Where `local` is the package namespace, and `somePackage` is a store path that has a `typst.toml` file in it.
You can put packages in whatever namespace you want, not just local.

See the [template](./template/flake.nix) for more API details.
