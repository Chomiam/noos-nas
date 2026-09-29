{ config, lib, pkgs, ... }:

let
  tsCfg = config.steveos.services.tailscale;
  wgCfg = config.steveos.services.wireguard;
in
{
  config = {
    # Tailscale pour accès distant zéro-config
    services.tailscale = lib.mkIf tsCfg.enable {
      enable = true;
      useRoutingFeatures = "server"; # Permet de servir comme exit-node ou subnet router
    };

    # Pare-feu modulaire VPN
    networking.firewall = {
      allowedUDPPorts = lib.optional wgCfg.enable 51820;
      trustedInterfaces = lib.optional tsCfg.enable "tailscale0";
    };
  };
}
