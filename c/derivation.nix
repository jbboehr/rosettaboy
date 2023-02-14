{
 lib,
 stdenv,
 cmake,
 SDL2,
 pkg-config,
 cleanSource,
 makeBuildTag,
 clang-tools ? null,
 ltoSupport ? false,
 debugSupport ? false
} @ args:

stdenv.mkDerivation rec {
  bname = "rosettaboy-c";
  name = "${bname}-${makeBuildTag args}";

  src = cleanSource {
    name = bname;
    src = ./.;
    extraRules = ''
      .clang-format
    '';
  };

  passthru.devTools = [ clang-tools ];

  enableParallelBuilding = true;

  buildInputs = [ SDL2 ];
  nativeBuildInputs = [ cmake pkg-config ];

  cmakeFlags = [ ]
    ++ lib.optional debugSupport "-DCMAKE_BUILD_TYPE=Debug"
    ++ lib.optional (!debugSupport) "-DCMAKE_BUILD_TYPE=Release"
    ++ lib.optional ltoSupport "-DENABLE_LTO=On"
  ;

  postInstall = ''
      mv $out/bin/$bname $out/bin/$name
      ln -s $out/bin/$name $out/bin/$bname
    '';

  meta = {
    description = name;
    mainProgram = name;
  };
}
