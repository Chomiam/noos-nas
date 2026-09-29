{ config, lib, pkgs, ... }:

let
  wgCfg = config.steveos.services.wireguard;
in
{
  config = lib.mkIf (wgCfg.enable or true) {
    # Dépendances et outils WireGuard (gestion tunnel + QR code pour clients mobiles)
    environment.systemPackages = with pkgs; [
      wireguard-tools
      qrencode
      iptables
      iproute2
    ];

    # Pare-feu modulaire WireGuard
    networking.firewall = {
      allowedUDPPorts = [ (wgCfg.port or 51820) ];
      trustedInterfaces = [ (wgCfg.interface or "wg0") ];
    };

    # Activation de l'IP Forwarding pour le routage du tunnel VPN vers le LAN et les conteneurs
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };
  };
}

