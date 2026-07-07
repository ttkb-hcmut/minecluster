{ nixpkgs ? import <nixpkgs> {} }:

let
	shellHook =
	''
	'';
	pkgs = with nixpkgs; [
		elixir erlang
		pnpm nodejs
	];
in
	nixpkgs.mkShell {
		packages = pkgs;
		shellHook = shellHook;
	}
