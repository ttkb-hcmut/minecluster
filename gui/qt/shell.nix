{ nixpkgs ? import <nixpkgs> {} }:
let
	pkgs = with nixpkgs; [ qt5.qtbase ];
in nixpkgs.mkShell {
	packages = pkgs;
	shellHook = shellHook;
}

