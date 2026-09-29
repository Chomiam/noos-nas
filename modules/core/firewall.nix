{ config, pkgs, lib, ... }:

let
  userFirewallPath = ../../../firewall-user.nix;
in
{
  # Importe les surcharges utilisateur si présentes
  imports = lib.optional (builtins.pathExists userFirewallPath) userFirewallPath;

  # =========================================================================
  # 🛡️ CŒUR DU PARE-FEU MODULAIRE STEvE_OS NAS EDITION
  # Les services (Samba, NFS, Jellyfin, SSH) injectent leurs propres ports
  # de manière dynamique et déclarative.
  # =========================================================================

  networking.firewall = {
    enable = config.steveos.firewall.enable;

    # Protection contre les paquets falsifiés / usurpation d'adresse
    checkReversePath = "loose";

    # Ports de base toujours accessibles pour l'administration système
    allowedTCPPorts = [
      # SSH / sFTP ouvert par défaut ou par modules/services/openssh.nix
    ];

    allowedUDPPorts = [
    ];

    allowedTCPPortRanges = [];
    allowedUDPPortRanges = [];
  };
}
