{ 
  pkgs,
  stdenv,
  lib,
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
in

stdenv.mkDerivation rec {
  name = "rosettaboy-zig";
  src = gitignoreSource ./.;

  passthru = {
    devTools = [ zig ];
  };

  buildInputs = []
    ++ lib.optional (!stdenv.isDarwin) SDL2
    ++ lib.optional stdenv.isDarwin SDL2-lowercase
    ;
  
  nativeBuildInputs = [ zig pkg-config ]
    ++ lib.optional (!stdenv.isDarwin) autoPatchelfHook
    ;

  dontConfigure = true;
  dontBuild = true;

	ZIG_FLAGS = []
		++ lib.optional safeSupport "-Drelease-safe=true"
		++ lib.optional fastSupport "-Drelease-fast=true"
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

  meta = with lib; {
    description = "rosettaboy-zig";
    mainProgram = "rosettaboy-zig";
  };
}
