{ nixpkgs ? import <nixpkgs> {} }:
let
	pkgs = with nixpkgs; [
		beam28Packages.elixir_1_19 ];
	shellHook =
	''
	alias iex='iex --erl "-kernel shell_history enabled"'
	'';
in nixpkgs.mkShell {
	packages = pkgs;
	shellHook = shellHook;
}
