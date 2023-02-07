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
  gitignoreSource,
  ltoSupport ? false,
  debugSupport ? false
}:

let
  devTools = [ rustfmt rustc cargo ] ++ lib.optional stdenv.isDarwin [libiconv];
in

naersk.buildPackage rec {
  name = "rosettaboy-rs";
  src = gitignoreSource ./.;

  buildInputs = [ SDL2 ];
  nativeBuildInputs = [ pkg-config ];

  cargoBuildOptions = input: input ++ (lib.optional ltoSupport ["--profile release-lto"]);

  release = !debugSupport && !ltoSupport;

  passthru = { inherit devTools; };

  meta = {
    description = name;
    mainProgram = name;
  };
}
