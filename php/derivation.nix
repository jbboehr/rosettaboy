{ stdenv
, lib
, fetchFromGitHub
, makeWrapper
, php
, php-sdl-src
, SDL2
, gitignoreSource
, opcacheSupport ? false
}@args:

let
  sdl = php.buildPecl {
    pname = "sdl";
    version = "master";
    src = php-sdl-src;
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

stdenv.mkDerivation rec {
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

    # Note: we have to invoke the interpreter explicitly instead of letting the
    # shebang on `main.php` take care of it for us because the interpreter is
    # actually a shell script (because of the PHP extensions we're adding) which
    # is problematic on macOS: https://stackoverflow.com/a/67101108
    makeWrapper ${lib.getBin php}/bin/php $out/bin/$name \
      --add-flags $out/libexec/$name/main.php

    runHook postInstall
  '';

  meta = {
    description = name;
    mainProgram = name;
  };
}
