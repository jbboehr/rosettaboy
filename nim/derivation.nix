{
  lib,
  stdenvNoCC,
  buildNimPackage,
  gitignoreSource,
  nimPackages,
  nim-argparse,
  git,
  cacert,
  bintools,
  debugSupport ? false,
  speedSupport ? false
}:

let
  argparse = buildNimPackage rec {
    pname = "argparse";
    version = "master";
    src = nim-argparse;
  };
in

buildNimPackage {
  name = "rosettaboy-nim";
  src = gitignoreSource ./.;

  passthru = {
    devTools = [ nimPackages.nim git cacert ];
  };

  nimBinOnly = true;

  nimFlags = []
    ++ lib.optional debugSupport "-d:debug"
    ++ lib.optional (!debugSupport) "-d:release"
    ++ lib.optional (!speedSupport) "-d:nimDebugDlOpen"
    ++ lib.optionals speedSupport [ "-d:danger" "--opt:speed" "-d:lto" "--mm:arc" "--panics:on" ]
    ;

  buildInputs = with nimPackages; [ argparse ]
    ++ lib.optional (!stdenvNoCC.isDarwin) sdl2;

  postInstall = ''
      mv $out/bin/rosettaboy $out/bin/rosettaboy-nim
    '';
    
  meta = with lib; {
    description = "rosettaboy-nim";
    mainProgram = "rosettaboy-nim";
  };
}
