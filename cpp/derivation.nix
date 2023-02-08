{ lib
, stdenv
, cmake
, SDL2
, autoPatchelfHook
, pkg-config
, gitignoreSource
, clang-format ? null
, ltoSupport ? false
, debugSupport ? false
}:

stdenv.mkDerivation rec {
  name = "rosettaboy-cpp";

  src = gitignoreSource ./.;

  enableParallelBuilding = true;

  buildInputs = [ SDL2 ];
  nativeBuildInputs = [ cmake pkg-config ]
    ++ lib.optional (!stdenv.isDarwin) autoPatchelfHook;

  passthru = {
    devTools = [ clang-format ];
  };

  cmakeFlags = [ ]
    ++ lib.optional debugSupport "-DCMAKE_BUILD_TYPE=Debug"
    ++ lib.optional (!debugSupport) "-DCMAKE_BUILD_TYPE=Release"
    ++ lib.optional ltoSupport "-DENABLE_LTO=On"
  ;

  meta.description = name;
}
