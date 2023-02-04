{
  description = "rosettaboy nix flake";
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-22.11;
    flake-utils.url = github:numtide/flake-utils;
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    naersk.url = "github:nix-community/naersk";
  };

  outputs = { self, nixpkgs, flake-utils, gitignore, naersk }: flake-utils.lib.eachDefaultSystem (system: let
    pkgs = nixpkgs.legacyPackages.${system};
    lib = pkgs.lib;
    inherit (gitignore.lib) gitignoreSource;
    naersk' = pkgs.callPackage naersk {};


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

    mkRs = {ltoSupport ? false, debugSupport ? false}:
      pkgs.callPackage ./rs/derivation.nix { naersk = naersk'; inherit gitignoreSource ltoSupport debugSupport; };
  in rec {
    packages = rec {
      rs = rs-release;
      rs-debug = mkRs { debugSupport = true; };
      rs-release = mkRs { };
      rs-lto = mkRs { ltoSupport = true; };
    };

    checks = packages;
    
    devShells = langDevShells // {
      default = pkgs.mkShell { inputsFrom = builtins.attrValues langDevShells; };
      utils = utilsShell;
      rs = pkgs.mkShell {
        inputsFrom = [ packages.rs ];
        buildInputs = packages.rs.devTools;
      };
    };
  });
}
