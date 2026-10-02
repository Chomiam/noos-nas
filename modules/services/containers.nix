{ config, lib, pkgs, ... }:

let
  dockerCfg = config.noos.services.docker;
  podmanCfg = config.noos.services.podman;
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

    # Autoriser l'interface bridge Docker et le forwarding dans le pare-feu NixOS
    networking.firewall.trustedInterfaces = lib.mkIf dockerCfg.enable [ "docker0" ];
    networking.firewall.extraCommands = lib.mkIf dockerCfg.enable ''
      # Autoriser le transit vers les conteneurs publiés via la chaîne DOCKER-USER officielle
      iptables -I DOCKER-USER -j ACCEPT 2>/dev/null || true
    '';

    # Backend OCI pour conteneurs déclaratifs
    virtualisation.oci-containers.backend = lib.mkIf dockerCfg.enable "docker";

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
