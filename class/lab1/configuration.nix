{ pkgs, ... }:

let master_addr = "127.0.0.1"; in

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
  extraHosts = "${master_addr} ";
  firewall.enable = false;
}; in

{ inherit imports services environment networking; }
