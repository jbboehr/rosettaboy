{ lib
, stdenv
, cmake
, SDL2
, fmt_8
, pkg-config
, gitignoreSource
, clang-format ? null
, ltoSupport ? false
, debugSupport ? false
,
}:

stdenv.mkDerivation rec {
  name = "rosettaboy-cpp";

  src = gitignoreSource ./.;

  buildInputs = [ SDL2 fmt_8 ];
  nativeBuildInputs = [ cmake pkg-config ];

  passthru = {
    devTools = [ clang-format ];
  };

  cmakeFlags = [ ]
    ++ lib.optional debugSupport "-DCMAKE_BUILD_TYPE=Debug"
    ++ lib.optional (!debugSupport) "-DCMAKE_BUILD_TYPE=Release"
    ++ lib.optional ltoSupport "-DENABLE_LTO=On"
  ;

  meta = {
    description = name;
    mainProgram = name;
  };
}
