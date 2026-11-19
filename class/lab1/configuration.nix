{ pkgs, ... }:

let master_addr = "127.0.0.1"; master_name = "kubernetes"; in

let imports = [ ./system-configuration.nix ]; in

let networking = { extraHosts = "${master_addr} ${master_name}"; firewall.enable = false; }; in

let services = {
  kubernetes.roles = [ "master" "node" ];
	kubernetes.masterAddress = master_addr;
	kubernetes.apiserverAddress = "https://${master_name}:${toString 6443}";
  kubernetes.easyCerts = true;
  kubernetes.apiserver = { securePort = 6443; advertiseAddress = master_addr; };
  kubernetes.addons.dns.enable = true;
}; in

let environment = { systemPackages = with pkgs; [ kubectl kubernetes ]; }; in

{ inherit imports services environment networking; }
