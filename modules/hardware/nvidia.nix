{ config, lib, pkgs, ... }:

let
  isNvidia = config.steveos.hardware.gpu == "nvidia";
in
{
  config = lib.mkIf isNvidia {
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      open = false; # Pilote propriétaire pour NVENC / NVDEC complet
      nvidiaSettings = false; # Serveur headless sans GUI
    };

    # Intégration pour conteneurs Docker/Podman
    hardware.nvidia-container-toolkit.enable = true;

    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        nvidia-vaapi-driver
        libva
        libva-utils
      ];
    };
  };
}
