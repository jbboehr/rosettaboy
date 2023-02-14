{
  lib,
  stdenv,
  cmake,
  SDL2,
  fmt_8,
  pkg-config,
  cleanSource,
  makeBuildTag,
  clang-format ? null,
  ltoSupport ? false,
  debugSupport ? false,
} @ args:

stdenv.mkDerivation rec {
  bname = "rosettaboy-cpp";
  name = "${bname}-${makeBuildTag args}";

  src = cleanSource {
    name = bname;
    src = ./.;
    extraRules = ''
      .clang-format
    '';
  };

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

  postInstall = ''
      mv $out/bin/rosettaboy-cpp $out/bin/${name}
      ln -s $out/bin/${name} $out/bin/rosettaboy-cpp
    '';

  meta = {
    description = name;
    mainProgram = name;
  };
}
