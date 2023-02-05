{
  lib,
  pythonPackages,
  gitignoreSource,
  mypycSupport ? false
}:

let
  pyPackages = with pythonPackages; [ 
    pysdl2
    mypy
    black
    setuptools
  ];
  python = pythonPackages.python.withPackages (pypkgs: pyPackages);
  devTools = [python pythonPackages.pip] ++ pyPackages;
in

pythonPackages.buildPythonApplication rec {
  name = "rosettaboy-py";
  src = gitignoreSource ./.;

  passthru = {
    inherit devTools python;
  };

  propagatedBuildInputs = pyPackages;

  ROSETTABOY_USE_MYPYC = mypycSupport;

  meta = with lib; {
    inherit name;
    mainProgram = "rosettaboy-py";
  };
}