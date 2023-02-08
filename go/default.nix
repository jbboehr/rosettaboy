{
  lib,
  buildGoApplication,
  gitignoreSource,
  pkg-config,
  SDL2,
  gomod2nix
}:

buildGoApplication rec {
  name = "rosettaboy-go";
  src = gitignoreSource ./.;
  modules = ./gomod2nix.toml;

  passthru = {
    devTools = [ gomod2nix ];
  };

  buildInputs = [ SDL2 ];
  nativeBuildInputs = [ pkg-config ];

  postInstall = ''
    mv $out/bin/src $out/bin/rosettaboy-go
  '';

  meta.description = name;
}
