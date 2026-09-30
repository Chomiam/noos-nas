{ config, pkgs, lib, ... }:

let
  userFirewallPath = ../../firewall-user.nix;
  customRulesPath = ../../firewall-rules.json;
  customStatePath = ../../firewall-state.json;
  customRules = if builtins.pathExists customRulesPath
    then (builtins.fromJSON (builtins.readFile customRulesPath))
    else [];
  customState = if builtins.pathExists customStatePath
    then (builtins.fromJSON (builtins.readFile customStatePath))
    else {};
  firewallEnabled = if (builtins.hasAttr "is_enabled" customState)
    then customState.is_enabled
    else config.steveos.firewall.enable;
  activeRules = builtins.filter (r: r.enabled or true) customRules;
  customTcpPorts = map (r: r.port) (builtins.filter (r: (r.protocol or "TCP") == "TCP" || (r.protocol or "TCP") == "BOTH") activeRules);
  customUdpPorts = map (r: r.port) (builtins.filter (r: (r.protocol or "UDP") == "UDP" || (r.protocol or "UDP") == "BOTH") activeRules);
in
{
  # Importe les surcharges utilisateur si présentes
  imports = lib.optional (builtins.pathExists userFirewallPath) userFirewallPath;

  # =========================================================================
  # 📊 HISTORIQUE & STATISTIQUES DE BANDE PASSANTE RÉSEAU (VNSTAT)
  # =========================================================================
  services.vnstat.enable = true;

  # =========================================================================
  # 🛡️ CŒUR DU PARE-FEU MODULAIRE STEvE_OS NAS EDITION
  # Les services (Samba, NFS, Jellyfin, SSH) injectent leurs propres ports
  # de manière dynamique et déclarative.
  # Les ports personnalisés définis via le Dashboard Web (firewall-rules.json)
  # sont automatiquement injectés ici.
  # L'état d'activation (firewall-state.json / vars.nix) est respecté.
  # =========================================================================

  networking.firewall = {
    enable = firewallEnabled;

    # Protection contre les paquets falsifiés / usurpation d'adresse
    checkReversePath = "loose";

    allowedTCPPorts = customTcpPorts;
    allowedUDPPorts = customUdpPorts;

    allowedTCPPortRanges = [];
    allowedUDPPortRanges = [];
  };
}
