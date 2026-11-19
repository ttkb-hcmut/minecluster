{ pkgs, ... }:

let imports = [ /etc/nixos/configuration.nix ]; in

{
  inherit imports;
  environment.systemPackages = with pkgs; [ kubectl kubernetes ];
  services.kubernetes.roles = [ "master" "node" ];
  services.kubernetes.easyCerts = true;
  services.kubernetes.apiserver = { securePort = 6443; };
  services.kubernetes.addons.dns.enable = true;
  networking.firewall.enable = false;
}
