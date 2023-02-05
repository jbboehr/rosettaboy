{
  lib,
  stdenvNoCC,
  makeWrapper,
  python3,
  wget,
  cacert,
  parallel,
  elfutils,
  gb-autotest-roms,
  cl-gameboy
}:

stdenvNoCC.mkDerivation {
  name = "rosettaboy-utils";

  src = ./.;

  passthru = {
    devTools = [ wget cacert parallel ]
      ++ lib.optional (!stdenvNoCC.isDarwin) elfutils;
  };

  dontConfigure = true;
  dontBuild = true;

  buildInputs = [ python3 ];
  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
      mkdir -p $out/bin $out/libexec/rosettaboy-utils/
      cp bench.py blargg.py cpudiff.py $out/libexec/rosettaboy-utils/
      
      makeWrapper $out/libexec/rosettaboy-utils/bench.py $out/bin/rosettaboy-bench \
        --set-default "GB_DEFAULT_BENCH_ROM" "${cl-gameboy}/roms/opus5.gb"

      makeWrapper $out/libexec/rosettaboy-utils/cpudiff.py $out/bin/rosettaboy-cpudiff

      makeWrapper $out/libexec/rosettaboy-utils/blargg.py $out/bin/rosettaboy-blargg \
        --set-default "GB_DEFAULT_AUTOTEST_ROM_DIR" "${gb-autotest-roms}"
    '';
}
