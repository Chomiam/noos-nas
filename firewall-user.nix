{ config, pkgs, ... }:

{
  # =========================================================================
  # 🛡️ RÈGLES DE PARE-FEU PERSONNALISÉES (NOOS NAS EDITION)
  # Ce fichier permet d'ajouter des ports manuellement sans modifier les modules.
  # =========================================================================

  networking.firewall = {
    # Ports TCP supplémentaires
    allowedTCPPorts = [
      # Exemples :
      # 80 443 # Reverse proxy web / Nginx
    ];

    # Ports UDP supplémentaires
    allowedUDPPorts = [
      # Exemples :
      # 51820 # WireGuard custom
    ];

    allowedTCPPortRanges = [];
    allowedUDPPortRanges = [];
  };
}
