{
  python310,
  cleanSource,
  makeBuildTag
} @ args:

let
  python = python310;
  pythonPackages = python.pkgs;

  runtimeDeps = with pythonPackages; [ setuptools pysdl2 cython_3 ];
  devDeps = with pythonPackages; [ black ];
in

pythonPackages.buildPythonApplication rec {
  bname = "rosettaboy-pxd";
  name = "${bname}-${makeBuildTag args}";

  src = cleanSource {
    name = bname;
    src = ./.;
    extraRules = ''
      py_env.sh
    '';
  };

  passthru.python = python.withPackages (p: runtimeDeps ++ devDeps);
  passthru.devTools = [ python ];
 
  propagatedBuildInputs = runtimeDeps;

  dontUseSetuptoolsCheck = true;

  postInstall = ''
      mv $out/bin/$bname $out/bin/$name
      ln -s $out/bin/$name $out/bin/$bname
    '';

  meta = {
    description = name;
    mainProgram = name;
  };
}
