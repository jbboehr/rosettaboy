{
  description = "rosettaboy nix flake";
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-22.11;
    flake-utils.url = github:numtide/flake-utils;
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gomod2nix.url = "github:jbboehr/gomod2nix/no-internal-overlay";
  };

  outputs = { self, nixpkgs, flake-utils, gitignore, gomod2nix }: flake-utils.lib.eachDefaultSystem (system: let
    pkgs = nixpkgs.legacyPackages.${system};
    lib = pkgs.lib;
    inherit (gitignore.lib) gitignoreSource;
    gomod2nix' = gomod2nix.packages.${system}.default;


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

    mkCpp = {ltoSupport ? false, debugSupport ? false}:
      pkgs.callPackage ./cpp/derivation.nix {
        inherit gitignoreSource ltoSupport debugSupport;
      };
    mkGo = {...}: pkgs.callPackage ./go/derivation.nix {
      inherit gitignoreSource;
      inherit (gomod2nix.lib.${system}) buildGoApplication;
    };
  in rec {
    packages = rec {
      cpp = cpp-release;
      cpp-release = mkCpp {};
      cpp-debug = mkCpp { debugSupport = true; };
      cpp-lto = mkCpp { ltoSupport = true; };
      go = mkGo {};

      default = pkgs.symlinkJoin {
        name = "rosettaboy";
        paths = [ cpp go ];
      };
    };

    devShells = langDevShells // {
      default = pkgs.mkShell { inputsFrom = builtins.attrValues langDevShells; };
      utils = utilsShell;
      cpp = pkgs.mkShell { inputsFrom = [ packages.cpp ]; buildInputs = packages.cpp.devTools; };
      go = pkgs.mkShell { buildInputs = with pkgs; [ go SDL2 pkg-config gomod2nix' ]; };
    };
  });
}
