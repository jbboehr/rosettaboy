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

stdenv.mkDerivation rec {
  name = "rosettaboy-zig";
  src = gitignoreSource ./.;

  buildInputs = [ SDL2 ];
  nativeBuildInputs = [ zig pkg-config ]
    ++ lib.optional (!stdenv.isDarwin) autoPatchelfHook;

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

    runHook postInstall
  '';

  meta = with lib; {
    description = "rosettaboy-zig";
    mainProgram = "rosettaboy";
  };
}
