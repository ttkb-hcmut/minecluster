{ pkgs, ... }:

let imports = [ /etc/nixos/configuration.nix ]; in

let services = {
  kubernetes.roles = [ "master" "node" ];
  kubernetes.easyCerts = true;
  kubernetes.apiserver = { securePort = 6443; };
  kubernetes.addons.dns.enable = true;
}; in

{
  inherit imports services;
  environment.systemPackages = with pkgs; [ kubectl kubernetes ];
  networking.firewall.enable = false;
}
