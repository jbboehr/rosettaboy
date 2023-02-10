{
  description = "rosettaboy nix flake";
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-22.11;
    flake-utils.url = github:numtide/flake-utils;
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
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
    php-sdl-src = {
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
      inputs.flake-utils.follows = "flake-utils";
    };
    zig-sdl = {
      url = "github:MasterQ32/SDL.zig/6a9e37687a4b9ae3c14c9ea148ec51d14e01c7db";
      flake = false;
    };
    zig-clap = {
      url = "github:Hejsil/zig-clap/e5d09c4b2d121025ad7195b2de704451e6306807";
      flake = false;
    };
    gb-autotest-roms = {
      url = "github:shish/gb-autotest-roms";
      flake = false;
    };
    cl-gameboy = {
      url = "github:sjl/cl-gameboy";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    flake-compat,
    gitignore,
    gomod2nix-src,
    nim-argparse,
    php-sdl-src,
    naersk,
    zig-overlay,
    zig-sdl,
    zig-clap,
    gb-autotest-roms,
    cl-gameboy
  }: flake-utils.lib.eachDefaultSystem (system: let
    pkgs = nixpkgs.legacyPackages.${system};
    lib = pkgs.lib;
    inherit (builtins) mapAttrs;
    inherit (lib) hiPrio filterAttrs;
    gomod2nix' = rec {
      gomod2nix = pkgs.callPackage "${gomod2nix-src}" { inherit buildGoApplication mkGoEnv; };
      inherit (pkgs.callPackage "${gomod2nix-src}/builder" { inherit gomod2nix; }) buildGoApplication mkGoEnv;
    };
    callPackage = pkgs.newScope {
      inherit gb-autotest-roms cl-gameboy;
      inherit (gitignore.lib) gitignoreSource;
      inherit php-sdl-src;
      inherit nim-argparse;
      inherit (gomod2nix') gomod2nix buildGoApplication;
      naersk = pkgs.callPackage naersk {};
      zig = zig-overlay.packages.${system}.master-2022-11-29;
      inherit zig-clap zig-sdl;
    };

    utils = callPackage ./utils/derivation.nix {};

    mkC = {clangSupport ? false, ltoSupport ? false, debugSupport ? false}: 
      callPackage ./c/derivation.nix {
        stdenv = if clangSupport then pkgs.clangStdenv else pkgs.stdenv;
        inherit ltoSupport debugSupport;
      };

    mkCpp = {ltoSupport ? false, debugSupport ? false}:
      callPackage ./cpp/derivation.nix {
        inherit ltoSupport debugSupport;
      };
      
    mkGo = {...}:
        callPackage ./go/derivation.nix {
      };

    mkNim = {debugSupport ? false, speedSupport ? false}:
      callPackage ./nim/derivation.nix {
        inherit debugSupport speedSupport;
        inherit (pkgs.llvmPackages_14) bintools;
      };

    mkPhp = {opcacheSupport ? false}:
      callPackage ./php/derivation.nix {
        inherit opcacheSupport;
      };

    mkPy = {mypycSupport ? false}:
      callPackage ./py/derivation.nix {
        inherit mypycSupport;
      };

    mkRs = {ltoSupport ? false, debugSupport ? false}:
      callPackage ./rs/derivation.nix {
        inherit ltoSupport debugSupport;
      };

    mkZig = {safeSupport ? false, fastSupport ? false}:
      callPackage ./zig/derivation.nix {
        inherit safeSupport fastSupport;
      };

  in rec {
    packages = rec {
      inherit utils;
      
      c-debug = mkC { debugSupport = true; };
      c-lto = mkC { ltoSupport = true; };
      c-release = mkC { };
      c-clang-debug = mkC { debugSupport = true; clangSupport = true; };
      c-clang-lto = mkC { ltoSupport = true; clangSupport = true; };
      c-clang-release = mkC { clangSupport = true; };
      c = hiPrio c-release;

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
        paths = [ c cpp go nim php py rs zig ];
        # if we use this without adding build tags to the executable,
        # it'll build all variants but not symlink them
        # paths = builtins.attrValues (filterAttrs (n: v: n != "default") packages);
      };
    };

    checks = let
      # zig-safe is too slow - skip
      packagesToCheck = filterAttrs (n: p: p.meta ? mainProgram && n != "zig-safe") packages;
    in mapAttrs (_: utils.mkBlargg) packagesToCheck;

    devShells = let
      shellHook = ''
          export GB_DEFAULT_AUTOTEST_ROM_DIR=${gb-autotest-roms}
          export GB_DEFAULT_BENCH_ROM=${cl-gameboy}/roms/opus5.gb
        '';
      langDevShells = mapAttrs (name: package: pkgs.mkShell {
        inputsFrom = [ package ];
        buildInputs = package.devTools or [];
        inherit shellHook;
      }) packages;
    in langDevShells // {
      default = pkgs.mkShell {
        inputsFrom = builtins.attrValues langDevShells;
      };
      # not yet implemented
      pxd = callPackage ./pxd/shell.nix {};
      # something wrong with using it in `inputsFrom`
      py = pkgs.mkShell {
        buildInputs = packages.py.devTools;
        inherit shellHook;
      };
    };
  });
}
