{
  lang,
  attr ? "checks",
  system ? builtins.currentSystem,
  prefix ? ".#${attr}.${system}.",
  lib ? import <nixpkgs/lib>
}:

attrs: lib.pipe attrs.${system} [
  builtins.attrNames
  (builtins.filter (lib.hasPrefix "${lang}-"))
  (builtins.map (x: "${prefix}${x}"))
  (builtins.concatStringsSep "\n")
]
