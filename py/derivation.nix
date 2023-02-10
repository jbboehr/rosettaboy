{ lib
, python311
, gitignoreSource
, mypycSupport ? false
}:

let
  python = python311;
  pythonPackages = python.pkgs;
  runtimeDeps = with pythonPackages; [ setuptools pysdl2 ];
  devDeps = with pythonPackages; [ mypy black ];
in

pythonPackages.buildPythonApplication rec {
  name = "rosettaboy-py";
  src = gitignoreSource ./.;

  nativeBuildInputs = lib.optional mypycSupport pythonPackages.mypy;

  passthru.python = python.withPackages (p: runtimeDeps ++ devDeps);
  passthru.devTools = [ python ];

  propagatedBuildInputs = runtimeDeps;

  ROSETTABOY_USE_MYPYC = mypycSupport;
  dontUseSetuptoolsCheck = true;

  meta = {
    description = name;
    mainProgram = name;
  };
}
