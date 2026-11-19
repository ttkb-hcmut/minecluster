{ pkgs, ... }:

let imports = [ /etc/nixos/configuration.nix ]; in

{
  inherit imports;
  environment.systemPackages = with pkgs; [ kubectl kubernetes ];
  services.kubernetes.roles = [ "master" "node" ];
  services.kubernetes.easyCerts = true;
}
