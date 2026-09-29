{ config, lib, pkgs, ... }:

let
  dockerCfg = config.steveos.services.docker;
  podmanCfg = config.steveos.services.podman;
in
{
  config = {
    # Moteur Docker
    virtualisation.docker = lib.mkIf dockerCfg.enable {
      enable = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
      # Support Nvidia GPU dans Docker si activé
      enableNvidia = dockerCfg.enableNvidia;
    };

    # Moteur Podman
    virtualisation.podman = lib.mkIf podmanCfg.enable {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };

    # Utilitaires de gestion des conteneurs
    environment.systemPackages = with pkgs; [
      docker-compose
    ];
  };
}
