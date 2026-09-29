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
      # Isolation stricte : bloquer tout transit (FORWARD) depuis wg0 vers d'autres réseaux (accès hôte NAS exclusif)
      extraCommands = ''
        iptables -D FORWARD -i ${wgCfg.interface or "wg0"} -j DROP 2>/dev/null || true
        iptables -I FORWARD 1 -i ${wgCfg.interface or "wg0"} -j DROP
      '';
    };

    # Déclaration du serveur WireGuard wg0
    networking.wireguard.interfaces.${wgCfg.interface or "wg0"} = {
      ips = [ (wgCfg.ip or "10.100.0.1/24") ];
      listenPort = wgCfg.port or 51820;
      generatePrivateKeyFile = true;
      privateKeyFile = "/var/lib/steveos/server_private.key";
      postSetup = ''
        mkdir -p /var/lib/steveos
        ${pkgs.wireguard-tools}/bin/wg pubkey < /var/lib/steveos/server_private.key > /var/lib/steveos/server_public.key || true
      '';
    };
  };
}

