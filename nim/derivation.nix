{
  lib,
  stdenvNoCC,
  cleanSource,
  llvmPackages_14,
  nimPackages,
  nim-argparse,
  git,
  cacert,
  bintools,
  makeBuildTag,
  debugSupport ? false,
  speedSupport ? false
} @ args:

let
  argparse = nimPackages.buildNimPackage rec {
    pname = "argparse";
    version = "master";
    src = nim-argparse;
  };

  # Upstream `nimPackages.sdl2` is marked broken on macOS but it actually works
  # fine:
  sdl2 = nimPackages.sdl2.overrideAttrs (o: {
    meta = o.meta // {
      platforms = o.meta.platforms ++ lib.platforms.darwin;
    };
  });
in

nimPackages.buildNimPackage rec {
  bname = "rosettaboy-nim";
  name = "${bname}-${makeBuildTag args}";

  src = cleanSource {
    name = bname;
    src = ./.;
  };

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

  buildInputs = [ argparse sdl2 ];

  # Wants `lld` on macOS:
  nativeBuildInputs = lib.optional stdenvNoCC.isDarwin llvmPackages_14.bintools;

  postInstall = ''
      mv $out/bin/rosettaboy $out/bin/$name
      ln -s $out/bin/$name $out/bin/$bname
    '';

  meta = {
    description = name;
    mainProgram = name;
  };
}
