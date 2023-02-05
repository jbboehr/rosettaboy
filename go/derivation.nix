{
  lib,
  buildGoApplication,
  gitignoreSource,
  pkg-config,
  SDL2
}:

buildGoApplication {
  name = "rosettaboy-go";
  src = gitignoreSource ./.;
  modules = ./gomod2nix.toml;

  buildInputs = [ SDL2 ];
  nativeBuildInputs = [ pkg-config ];

  postInstall = ''
      mv $out/bin/src $out/bin/rosettaboy-go
    '';

  meta = with lib; {
    description = "rosettaboy-go";
    mainProgram = "rosettaboy-go";
  };
}
