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
    gomod2nix = {
      url = "github:nix-community/gomod2nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "flake-utils";
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
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      inputs.flake-compat.follows = "flake-compat";
    };
    zig-sdl = {
      url = "github:MasterQ32/SDL.zig/6b33f1f4299ec8814e9fb3b206cda37791ced574";
      flake = false;
    };
    zig-clap = {
      url = "github:Hejsil/zig-clap/272d8e2088b2cae037349fb260dc05ec46bba422";
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
    self, nixpkgs, flake-utils, flake-compat,
    gitignore,
    gomod2nix,
    nim-argparse,
    php-sdl,
    naersk,
    zig-overlay, zig-sdl, zig-clap,
    gb-autotest-roms, cl-gameboy,
  }: flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs {
      inherit system;
      overlays = [
        naersk.overlay
        zig-overlay.overlays.default
        gomod2nix.overlays.default
      ];
    };
    inherit (pkgs) lib;
    inherit (builtins) mapAttrs;
    inherit (lib) hiPrio filterAttrs;

    callPackage = pkgs.newScope {
      inherit gb-autotest-roms cl-gameboy;
      inherit (gitignore.lib) gitignoreSource;
      inherit php-sdl;
      inherit nim-argparse;
      zig = pkgs.zigpkgs.master-2023-02-06;
      inherit zig-clap zig-sdl;
    };
    mk = dir: callPackage ./${dir};

    utils = mk "utils" {};
  in rec {
    packages = rec {
      inherit utils;

      c-debug = mk "c" { debugSupport = true; };
      c-lto = mk "c" { ltoSupport = true; };
      c-release = mk "c" { };
      c-clang-debug = mk "c" { debugSupport = true; stdenv = pkgs.clangStdenv; };
      c-clang-lto = mk "c" { ltoSupport = true; stdenv = pkgs.clangStdenv; };
      c-clang-release = mk "c" { stdenv = pkgs.clangStdenv; };
      c = hiPrio c-lto;

      cpp-release = mk "cpp" { };
      cpp-debug = mk "cpp" { debugSupport = true; };
      cpp-lto = mk "cpp" { ltoSupport = true; };
      cpp-clang-debug = mk "cpp" { debugSupport = true; stdenv = pkgs.clangStdenv; };
      cpp-clang-lto = mk "cpp" { ltoSupport = true; stdenv = pkgs.clangStdenv; };
      cpp-clang-release = mk "cpp" { stdenv = pkgs.clangStdenv; };
      cpp = hiPrio cpp-lto;

      go = mk "go" {};

      nim-release = mk "nim" {};
      nim-debug = mk "nim" { debugSupport = true; };
      nim-speed = mk "nim" { speedSupport = true; };
      nim = hiPrio nim-speed;

      php-release = mk "php" {};
      php-opcache = mk "php" { opcacheSupport = true; };
      php = hiPrio php-opcache;

      py = mk "py" {};
      mypyc = mk "py" { mypycSupport = true; };

      rs-debug = mk "rs" { debugSupport = true; };
      rs-release = mk "rs" { };
      rs-lto = mk "rs" { ltoSupport = true; };
      rs = hiPrio rs-lto;

      zig-fast = mk "zig" { fastSupport = true; };
      zig-safe = mk "zig" { safeSupport = true; };
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
      packagesToCheck = filterAttrs (n: _: n != "utils" && n != "zig-safe") packages;
    in mapAttrs utils.mkBlargg packagesToCheck;

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
        inherit shellHook;
      };
      # not yet implemented
      pxd = pkgs.callPackage ./pxd/shell.nix {};
      # something wrong with using it in `inputsFrom`
      py = pkgs.mkShell {
        buildInputs = packages.py.devTools;
        inherit shellHook;
      };
    };
  });
}
