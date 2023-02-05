{
  description = "rosettaboy nix flake";
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-22.11;
    flake-utils.url = github:numtide/flake-utils;
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nim-argparse = {
      url = "github:iffy/nim-argparse";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, gitignore, nim-argparse }: flake-utils.lib.eachDefaultSystem (system: let
    pkgs = nixpkgs.legacyPackages.${system};
    lib = pkgs.lib;
    inherit (gitignore.lib) gitignoreSource;


    # Get each directory with a `shell.nix`:
    languages = with builtins; lib.pipe ./. [
      readDir
      (lib.filterAttrs (_: value: value == "directory"))
      attrNames
      (filter (dir: pathExists (./${dir}/shell.nix)))
      # Exclude `utils`:
      (filter (dir: dir != "utils"))
    ];

    # For each language, expose `shell.nix` as a devShell:
    #
    # Also include the deps of `utils` in the shell.
    utilsShell = import utils/shell.nix { inherit pkgs; };
    langDevShells = lib.genAttrs languages (lang: pkgs.mkShell {
      name = "rosettaboy-${lang}";
      inputsFrom = [
        (import ./${lang}/shell.nix { inherit pkgs; })
        utilsShell
      ];
    });

    mkNim = {debugSupport ? false, speedSupport ? false}:
      pkgs.callPackage ./nim/derivation.nix {
        inherit (pkgs.nimPackages) buildNimPackage;
        inherit gitignoreSource nim-argparse debugSupport speedSupport;
        inherit (pkgs.llvmPackages_14) bintools;
      };
  in rec {
    packages = {
      nim = mkNim {};
      nim-debug = mkNim { debugSupport = true; };
      nim-speed = mkNim { speedSupport = true; };
    };
    
    devShells = langDevShells // {
      default = pkgs.mkShell { inputsFrom = builtins.attrValues langDevShells; };
      utils = utilsShell;
      nim = pkgs.mkShell { inputsFrom = [ packages.nim ]; buildInputs = packages.nim.devTools; };
    };
  });
}
