{ config, lib, pkgs, ... }:

let
  isNvidia = config.noos.hardware.gpu == "nvidia";
  codecs = config.noos.hardware.enableCodecs;
in
{
  config = lib.mkIf isNvidia {
    # 🟢 Pilote propriétaire Nvidia moderne (Turing GTX 1650, RTX 20/30/40/50, Ampere, Ada Lovelace)
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      modesetting.enable = true;
      powerManagement.enable = true;
      powerManagement.finegrained = false;
      open = false;            # Pilote propriétaire complet pour débloquer NVENC / NVDEC et CUDA
      nvidiaSettings = false;  # Serveur NAS headless (pas besoin d'interface graphique X11)
    };

    # 🐳 Passthrough GPU vers les conteneurs Docker (Jellyfin, Plex, Arcane)
    hardware.nvidia-container-toolkit.enable = true;

    # 🎮 Couche graphique & tous les codecs Nvidia (NVDEC / NVENC via VA-API & VDPAU)
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = lib.mkIf codecs (with pkgs; [
        nvidia-vaapi-driver   # Traduction matérielle VA-API vers NVDEC (indispensable pour Jellyfin / FFmpeg)
        libva                 # Interface Video Acceleration API
        libva-utils           # Outils de vérification des profils vidéo (vainfo)
        libvdpau              # Interface VDPAU native
        libvdpau-va-gl        # Passerelle VDPAU
        egl-wayland           # Couche EGL pour rendu matériel moderne
      ]);
    };

    # 🛠️ Utilitaires d'inspection et monitoring Nvidia
    environment.systemPackages = with pkgs; [
      libva-utils           # Commande 'vainfo'
      nvtopPackages.nvidia  # Commande 'nvtop' affichant la charge GPU, VRAM et sessions d'encodage NVENC
    ];

    # ⚙️ Variables d'environnement pour accélérer le transcodage matériel Nvidia
    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "nvidia";
      NVD_BACKEND = "direct";
      MOZ_DISABLE_RDD_SANDBOX = "1";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    };
  };
}
