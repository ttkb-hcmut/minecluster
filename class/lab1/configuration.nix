{ pkgs, ... }:

let imports = [ /etc/nixos/configuration.nix ]; in

let services = {
  kubernetes.roles = [ "master" "node" ];
  kubernetes.easyCerts = true;
  kubernetes.apiserver = { securePort = 6443; };
  kubernetes.addons.dns.enable = true;
}; in

let environment = {
  systemPackages = with pkgs; [ kubectl kubernetes ];
}; in

let networking = {
  firewall.enable = false;
}; in

{ inherit imports services environment networking; }
