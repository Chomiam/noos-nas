{ config, lib, pkgs, ... }:

let
  isAmd = config.steveos.hardware.gpu == "amd";
  codecs = config.steveos.hardware.enableCodecs;
in
{
  config = lib.mkIf isAmd {
    # 🚀 Modules noyau pour GPU / APU AMD et virtualisation
    boot.initrd.kernelModules = [ "amdgpu" ];
    boot.kernelModules = [ "amdgpu" "kvm-amd" ];

    # 🎮 Couche graphique & codecs matériels AMD (Mesa radeonsi, ROCm OpenCL, VDPAU)
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = lib.mkIf codecs (with pkgs; [
        libva                 # Bibliothèque Video Acceleration API
        libva-utils           # Utilitaires de diagnostic vidéo (vainfo)
        rocmPackages.clr.icd  # Runtime OpenCL ROCm moderne pour le tonemapping HDR et calcul
        libvdpau-va-gl        # Passerelle VDPAU vers VA-API pour compatibilité applicative
        vulkan-loader         # Chargeur d'API Vulkan pour calculs haute performance
      ]);
    };

    # 🛠️ Outils système de diagnostic et monitoring AMD
    environment.systemPackages = with pkgs; [
      libva-utils  # Commande 'vainfo'
      radeontop    # Commande 'radeontop' pour suivre l'utilisation du GPU et de la VRAM en direct
      clinfo       # Commande 'clinfo' pour vérifier la disponibilité d'OpenCL
    ];

    # ⚙️ Variables d'environnement pour forcer le pilote VA-API AMD
    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "radeonsi";
      VDPAU_DRIVER = "va_gl";
    };
  };
}
