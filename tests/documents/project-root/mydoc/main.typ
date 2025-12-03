// NOTE: Ignore the `file not found` error from the LSP.
// This should works in a nix derivation.
#import "/lib/mylib.typ"

#mylib.importme // => "This is imported from mylib!"
