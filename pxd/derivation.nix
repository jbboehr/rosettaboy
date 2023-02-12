{
  python310,
  gitignoreSource
}:

let
  python = python310;
  pythonPackages = python.pkgs;

  runtimeDeps = with pythonPackages; [ setuptools pysdl2 cython_3 ];
  devDeps = with pythonPackages; [ black ];
in

pythonPackages.buildPythonApplication rec {
  name = "rosettaboy-pxd";
  src = gitignoreSource ./.;

  passthru.python = python.withPackages (p: runtimeDeps ++ devDeps);
  passthru.devTools = [ python ];
 
  propagatedBuildInputs = runtimeDeps;

  dontUseSetuptoolsCheck = true;

  meta = {
    description = name;
    mainProgram = name;
  };
}
