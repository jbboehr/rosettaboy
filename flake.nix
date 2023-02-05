{
  description = "rosettaboy nix flake";
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-22.11;
    flake-utils.url = github:numtide/flake-utils;
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gomod2nix-src = {
      url = "github:nix-community/gomod2nix";
      flake = false;
    };
    nim-argparse = {
      url = "github:iffy/nim-argparse";
      flake = false;
    };
    php-sdl = {
      url = "github:Ponup/php-sdl";
      flake = false;
    };
    naersk = {
      url = "github:nix-community/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zig-overlay = {
      url = "github:mitchellh/zig-overlay/17352071583eda4be43fa2a312f6e061326374f7";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zig-sdl = {
      url = "github:MasterQ32/SDL.zig/6a9e37687a4b9ae3c14c9ea148ec51d14e01c7db";
      flake = false;
    };
    zig-clap = {
      url = "github:Hejsil/zig-clap/e5d09c4b2d121025ad7195b2de704451e6306807";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    gitignore,
    gomod2nix-src,
    nim-argparse,
    php-sdl,
    naersk,
    zig-overlay,
    zig-sdl,
    zig-clap
  }: flake-utils.lib.eachDefaultSystem (system: let
    pkgs = nixpkgs.legacyPackages.${system};
    lib = pkgs.lib;
    inherit (lib) hiPrio filterAttrs;
    inherit (gitignore.lib) gitignoreSource;
    gomod2nix' = rec {
      gomod2nix = pkgs.callPackage "${gomod2nix-src}" { inherit (lib) buildGoApplication mkGoEnv; };
      lib = pkgs.callPackage "${gomod2nix-src}/builder" { inherit gomod2nix; };
    };
    naersk' = pkgs.callPackage naersk {};
    zig = zig-overlay.packages.${system}.master-2022-11-29;

    utilsShell = import ./utils/shell.nix { inherit pkgs; };

    mkCpp = {ltoSupport ? false, debugSupport ? false}:
      pkgs.callPackage ./cpp/derivation.nix {
        inherit gitignoreSource ltoSupport debugSupport;
      };
      
    mkGo = {...}: pkgs.callPackage ./go/derivation.nix {
      inherit gitignoreSource;
      inherit (gomod2nix'.lib) buildGoApplication;
      gomod2nix = gomod2nix'.gomod2nix;
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

    mkZig = {safeSupport ? false, fastSupport ? false}:
      pkgs.callPackage ./zig/derivation.nix {
        inherit zig zig-sdl zig-clap safeSupport fastSupport gitignoreSource;
      };

  in rec {
    packages = rec {
      cpp-release = mkCpp {};
      cpp-debug = mkCpp { debugSupport = true; };
      cpp-lto = mkCpp { ltoSupport = true; };
      cpp = hiPrio cpp-release;
      
      go = mkGo {};

      nim-release = mkNim {};
      nim-debug = mkNim { debugSupport = true; };
      nim-speed = mkNim { speedSupport = true; };
      nim = hiPrio nim-release;

      php-release = mkPhp {};
      php-opcache = mkPhp { opcacheSupport = true; };
      php = hiPrio php-release;

      py = mkPy {};
      # match statement support is only in myypc master
      # https://github.com/python/mypy/commit/d5e96e381f72ad3fafaae8707b688b3da320587d
      # mypyc = mkPy { mypycSupport = true; };
      
      rs-debug = mkRs { debugSupport = true; };
      rs-release = mkRs { };
      rs-lto = mkRs { ltoSupport = true; };
      rs = hiPrio rs-release;
      
      zig-fast = mkZig { fastSupport = true; };
      zig-safe = mkZig { safeSupport = true; };
      zig = hiPrio zig-fast;

      # I don't think we can join all of them because they collide
      default = pkgs.symlinkJoin {
        name = "rosettaboy";
        paths = [ cpp go nim php py rs zig ];
        # if we use this without adding build tags to the executable,
        # it'll build all variants but not symlink them
        # paths = builtins.attrValues (filterAttrs (n: v: n != "default") packages);
      };
    };

    devShells = with builtins; let
      langDevShells = mapAttrs (name: package: pkgs.mkShell {
        inputsFrom = [ package ];
        buildInputs = package.devTools or [];
      }) packages;
    in langDevShells // {
      default = pkgs.mkShell {
        inputsFrom = builtins.attrValues langDevShells;
      };
      utils = utilsShell;
      # not yet implemented
      pxd = pkgs.callPackage ./pxd/shell.nix {};
      # something wrong with using it in `inputsFrom`
      py = pkgs.mkShell { buildInputs = packages.py.devTools; };
    };
  });
}
