{ lang
, system ? builtins.currentSystem
, lib ? import <nixpkgs/lib>
}:

checks: lib.pipe checks.${system} [
  builtins.attrNames
  (builtins.filter (lib.hasPrefix "${lang}-"))
  (builtins.map (x: ".#checks.${system}.${x}"))
  (builtins.concatStringsSep " ")
]
