{ nixpkgs ? import <nixpkgs> {} }:

let
	shellHook =
	''
	'';
	pkgs = with nixpkgs; [
		beam28Packages.elixir_1_19
		pnpm nodejs
	];
in
	nixpkgs.mkShell {
		packages = pkgs;
		shellHook = shellHook;
	}
