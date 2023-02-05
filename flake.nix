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
    nim-argparse = {
      url = "github:iffy/nim-argparse";
      flake = false;
    };
    php-sdl = {
      url = "github:Ponup/php-sdl";
      flake = false;
    };
    naersk.url = "github:nix-community/naersk";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    gitignore,
    gomod2nix,
    nim-argparse,
    php-sdl,
    naersk
  }: flake-utils.lib.eachDefaultSystem (system: let
    pkgs = nixpkgs.legacyPackages.${system};
    lib = pkgs.lib;
    inherit (gitignore.lib) gitignoreSource;
    gomod2nix' = gomod2nix.packages.${system}.default;
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

    mkCpp = {ltoSupport ? false, debugSupport ? false}:
      pkgs.callPackage ./cpp/derivation.nix {
        inherit gitignoreSource ltoSupport debugSupport;
      };
      
    mkGo = {...}: pkgs.callPackage ./go/derivation.nix {
      inherit gitignoreSource;
      inherit (gomod2nix.lib.${system}) buildGoApplication;
      gomod2nix = gomod2nix';
    };
    
    mkNim = {debugSupport ? false, speedSupport ? false}:
      pkgs.callPackage ./nim/derivation.nix {
        inherit (pkgs.nimPackages) buildNimPackage;
        inherit gitignoreSource nim-argparse debugSupport speedSupport;
        inherit (pkgs.llvmPackages_14) bintools;
      };

    mkPhp = {opcacheSupport ? false}:
      pkgs.callPackage ./php/derivation.nix {
        inherit gitignoreSource php-sdl opcacheSupport;
      };

    mkPy = {mypycSupport ? false}:
      pkgs.callPackage ./py/derivation.nix {
        inherit mypycSupport gitignoreSource;
        pythonPackages = pkgs.python310Packages;
      };

    mkRs = {ltoSupport ? false, debugSupport ? false}:
      pkgs.callPackage ./rs/derivation.nix {
        naersk = naersk';
        inherit gitignoreSource ltoSupport debugSupport;
      };

  in rec {
    packages = rec {
      cpp = cpp-release;
      cpp-release = mkCpp {};
      cpp-debug = mkCpp { debugSupport = true; };
      cpp-lto = mkCpp { ltoSupport = true; };
      
      go = mkGo {};

      nim = mkNim {};
      nim-debug = mkNim { debugSupport = true; };
      nim-speed = mkNim { speedSupport = true; };

      php = mkPhp {};
      php-opcache = mkPhp { opcacheSupport = true; };

      py = mkPy {};
      # match statement support is only in myypc master
      # https://github.com/python/mypy/commit/d5e96e381f72ad3fafaae8707b688b3da320587d
      # mypyc = mkPy { mypycSupport = true; };
      
      rs-debug = mkRs { debugSupport = true; };
      rs-release = mkRs { };
      rs-lto = mkRs { ltoSupport = true; };
      rs = rs-release;

      default = pkgs.symlinkJoin {
        name = "rosettaboy";
        paths = [ cpp go nim php py rs ];
      };
    };

    devShells = langDevShells // {
      default = pkgs.mkShell { inputsFrom = builtins.attrValues langDevShells; };
      utils = utilsShell;
      cpp = pkgs.mkShell { inputsFrom = [ packages.cpp ]; buildInputs = packages.cpp.devTools; };
      go = pkgs.mkShell { buildInputs = with pkgs; [ go SDL2 pkg-config gomod2nix' ]; };
      nim = pkgs.mkShell { inputsFrom = [ packages.nim ]; buildInputs = packages.nim.devTools; };
      php = pkgs.mkShell { inputsFrom = [ packages.php ]; buildInputs = packages.php.devTools; };
      rs = pkgs.mkShell { inputsFrom = [ packages.rs ]; buildInputs = packages.rs.devTools; };
      # not yet implemented
      pxd = pkgs.callPackage ./pxd/shell.nix {};
      # something wrong with using it in `inputsFrom`
      py = pkgs.mkShell { buildInputs = packages.py.devTools; };
    };
  });
}
