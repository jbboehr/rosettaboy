{
  buildGoApplication,
  cleanSource,
  pkg-config,
  SDL2,
  gomod2nix,
  makeBuildTag
} @ args:

buildGoApplication rec {
  bname = "rosettaboy-go";
  name = "${bname}-${makeBuildTag args}";

  src = cleanSource {
    name = bname;
    src = ./.;
  };

  modules = ./gomod2nix.toml;

  passthru.devTools = [ gomod2nix ];

  buildInputs = [ SDL2 ];
  nativeBuildInputs = [ pkg-config ];

  postInstall = ''
      mv $out/bin/src $out/bin/$name
      ln -s $out/bin/$name $out/bin/$bname
    '';

  meta = {
    description = name;
    mainProgram = name;
  };
}
