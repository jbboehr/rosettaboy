{ 
  pkgs,
  stdenv,
  lib,
  darwin,
  libiconv,
  zig,
  pkg-config,
  SDL2,
  zig-sdl,
  zig-clap,
  symlinkJoin,
  autoPatchelfHook,
  gitignoreSource,
	safeSupport ? false,
	fastSupport ? false
}:

let
  # Apparently, Nix capitalizing "SDL2" creates an incompatibility:
  # https://github.com/MasterQ32/SDL.zig/issues/14
  # I'm not sure what the "right" way to do it is. `zig build` seems to just be running `lld -lsdl2`, the SDL2 `.so` files are also capitalized as "libSDL2" on my non-Nix system, and GH:andrewrk/sdl-zig-demo does `exe.linkSystemLibrary("SDL2")` capitalized, so I'm inclined to call this a bug in GH:MasterQ32/SDL.zig for trying to link to non-existent lower-case "sdl2". But then presumably it works in the Docker, so IDK.
  # @todo verify this is still necessary
	SDL2-lowercase = symlinkJoin {
    name =  "${SDL2.pname}-lowercase";
    paths = [ SDL2 ];
    postBuild = ''
      cd $out/lib/
      for _file in libSDL2*; do
        if [[ ! -f "''${_file,,}" ]]; then
          ln -s "$_file" "''${_file,,}"
        fi
      done;
    '';
  };

  # `apple_sdk` defaults to `10_12` instead of `11_0` on `x86_64-darwin` but we
  # need `CoreHaptics` to successfully link against `SDL2` and `CoreHaptics` is
  # not available in `10_12`.
  #
  # So, we use `11_0`, even on x86_64.
  inherit (darwin.apple_sdk_11_0) frameworks;
in

stdenv.mkDerivation rec {
  name = "rosettaboy-zig";
  src = gitignoreSource ./.;

  passthru = {
    devTools = [ zig ];
  };

  buildInputs = [(if stdenv.isDarwin then SDL2-lowercase else SDL2)]
    ++ lib.optionals stdenv.isDarwin (with frameworks; [
      IOKit GameController CoreAudio AudioToolbox QuartzCore Carbon Metal
      Cocoa ForceFeedback CoreHaptics
    ])
    ++ lib.optional stdenv.isDarwin libiconv
    ;
  
  nativeBuildInputs = [ zig pkg-config ]
    ++ lib.optional (!stdenv.isDarwin) autoPatchelfHook
    ;

  dontConfigure = true;
  dontBuild = true;

  # Unforunately `zig`'s parsing of `NIX_LDFLAGS` bails when it encounters any
  # flags it does not expect.
  # https://github.com/ziglang/zig/blob/fe6dcdba1407f00584725318404814571cdbd828/lib/std/zig/system/NativePaths.zig#L79
  #
  # When `zig` sees the `-liconv` flag that's in `NIX_LDFLAGS` on macOS, it
  # bails, causing it to miss the `-L` path for SDL.
  #
  # Really, this should be fixed in upstream (zig) but for now we just strip out
  # the `-l` flags:
  preInstall = ''
    readonly ORIGINAL_NIX_LDFLAGS=($NIX_LDFLAGS)

    NIX_LDFLAGS=""
    for c in "''${ORIGINAL_NIX_LDFLAGS[@]}"; do
      # brittle, bad, etc; this presumes `-l...` style args (no space)
      if [[ $c =~ ^-l.* ]]; then
        echo "dropping link flag: $c"
        continue
      else
        echo "keeping link flag: $c"
        NIX_LDFLAGS="$NIX_LDFLAGS $c"
      fi
    done

    export NIX_LDFLAGS
  '';

  ZIG_FLAGS = []
    ++ lib.optional fastSupport "-Doptimize=ReleaseFast"
    ++ lib.optional safeSupport "-Doptimize=ReleaseSafe"
    ;

  installPhase = ''
    runHook preInstall

    export HOME=$TMPDIR
    mkdir -p lib
    cp -aR ${zig-sdl}/ lib/sdl
    cp -aR ${zig-clap}/ lib/clap
    zig build $ZIG_FLAGS --prefix $out install
    mv $out/bin/rosettaboy $out/bin/rosettaboy-zig

    runHook postInstall
  '';

  meta = {
    description = name;
    mainProgram = name;
  };
}
