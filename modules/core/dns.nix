{ config, lib, pkgs, ... }:

let
  dnsJsonPath = ../../dns.json;
  dnsConfig = if builtins.pathExists dnsJsonPath
    then (builtins.fromJSON (builtins.readFile dnsJsonPath))
    else {};

  freePort53 = dnsConfig.free_port_53 or true;
  primaryServers = dnsConfig.primary_servers or [ "1.1.1.1" "1.0.0.1" ];
  fallbackServers = dnsConfig.fallback_servers or [ "9.9.9.9" ];
  customServers = dnsConfig.custom_servers or [];

  effectiveServers = if (dnsConfig.mode or "popular") == "custom" && customServers != []
    then customServers ++ fallbackServers
    else primaryServers ++ (lib.filter (s: !(builtins.elem s primaryServers)) fallbackServers);
in
{
  # =========================================================================
  # 🌐 CONFIGURATION DNS DÉCLARATIVE & GESTION DU PORT 53
  # Les serveurs DNS définis via le Dashboard Web (dns.json)
  # sont automatiquement injectés ici.
  # =========================================================================

  # 1. Résolveurs DNS amonts durables
  networking.nameservers = effectiveServers;

  # 2. Gestion de systemd-resolved pour libérer le port 53 (0.0.0.0:53 / 127.0.0.53:53)
  # Indispensable pour éviter tout conflit lors du déploiement d'AdGuard Home ou Pi-hole
  services.resolved = lib.mkIf freePort53 {
    settings = {
      Resolve = {
        DNSStubListener = "no";
      };
    };
  };
}
