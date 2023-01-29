{ pkgs ? import <nixpkgs> {} } : pkgs.mkShell {
	name  = "rosettaboy-utils";
	buildInputs = with pkgs; [
		wget cacert
	];
}
