{
  lib,
  stdenv,
  naersk,
  SDL2,
  pkg-config,
  libiconv,
  rustfmt,
  rustc,
  cargo,
  cleanSource,
  makeBuildTag,
  ltoSupport ? false,
  debugSupport ? false
} @ args:

let
  devTools = [ rustfmt rustc cargo ] ++ lib.optional stdenv.isDarwin [libiconv];
in

naersk.buildPackage rec {
  bname = "rosettaboy-rs";
  name = "${bname}-${makeBuildTag args}";

  src = cleanSource {
    name = bname;
    src = ./.;
    extraRules = ''
      test_pgo.sh
    '';
  };

  buildInputs = [ SDL2 ];
  nativeBuildInputs = [ pkg-config ];

  cargoBuildOptions = input: input ++ (lib.optional ltoSupport ["--profile release-lto"]);

  release = !debugSupport && !ltoSupport;

  passthru = { inherit devTools; };

  postInstall = ''
      mv $out/bin/$bname $out/bin/${name}
      ln -s $out/bin/${name} $out/bin/$bname
    '';

  meta = {
    description = name;
    mainProgram = name;
  };
}
