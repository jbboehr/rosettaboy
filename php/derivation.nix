{ stdenv
, lib
, fetchFromGitHub
, makeWrapper
, php
, php-sdl
, SDL2
, gitignoreSource
, opcacheSupport ? false
}@args:

let
  sdl = php.buildPecl {
    pname = "sdl";
    version = "master";
    src = php-sdl;
    buildInputs = [ SDL2 ];
  };

  php = args.php.buildEnv {
    extensions = ({ enabled, all }: enabled ++ [ sdl ] ++ lib.optional opcacheSupport all.opcache);
    extraConfig = lib.optionalString opcacheSupport ''
      opcache.enable_cli=1
      opcache.jit_buffer_size=100M
    '';
  };
in

stdenv.mkDerivation {
  name = "rosettaboy-php";

  src = gitignoreSource ./.;

  passthru = {
    inherit php;
    devTools = [ sdl php ];
  };

  buildInputs = [ php ];
  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/libexec/$name
    cp src/* $out/libexec/$name

    makeWrapper $out/libexec/$name/main.php $out/bin/$name

    runHook postInstall
  '';

  meta = with lib; {
    description = "rosettaboy-php";
    mainProgram = "rosettaboy-php";
  };
}
