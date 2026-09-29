{ config, lib, pkgs, ... }:

let
  isNvidiaLegacy = config.steveos.hardware.gpu == "nvidia-legacy";
  codecs = config.steveos.hardware.enableCodecs;
  branch = config.steveos.hardware.nvidiaLegacyBranch;
in
{
  config = lib.mkIf isNvidiaLegacy {
    # 🟡 Pilote propriétaire Nvidia Legacy (pour GPU en-dessous de la GTX 1650 : Kepler, Maxwell, Pascal, Fermi)
    # Branche 470xx recommandée par défaut pour GTX 600, 700, 800 et équivalents Quadro/Tesla
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia = {
      package =
        if branch == "390"
        then config.boot.kernelPackages.nvidiaPackages.legacy_390
        else config.boot.kernelPackages.nvidiaPackages.legacy_470;
      modesetting.enable = true;
      powerManagement.enable = false; # INDISPENSABLE : la gestion d'énergie moderne fige les bus PCIe legacy
      open = false;                   # INDISPENSABLE : les modules Open ne fonctionnent qu'à partir de Turing (GTX 1650+)
      nvidiaSettings = false;         # NAS headless sans interface X11
    };

    # 🐳 Passthrough GPU vers les conteneurs Docker
    hardware.nvidia-container-toolkit.enable = true;

    # 🎮 Couche graphique & codecs matériels legacy (NVDEC, VDPAU, VA-API)
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = lib.mkIf codecs (with pkgs; [
        nvidia-vaapi-driver   # Traduction VA-API vers NVDEC pour transcodage Jellyfin / FFmpeg
        libva                 # Interface Video Acceleration API
        libva-utils           # vainfo
        libvdpau              # Pilote VDPAU matériel historique Nvidia
        libvdpau-va-gl        # Wrapper de compatibilité VDPAU vers VA-API
      ]);
    };

    # 🛠️ Utilitaires d'inspection et monitoring Nvidia
    environment.systemPackages = with pkgs; [
      libva-utils           # Commande 'vainfo'
      nvtopPackages.nvidia  # Commande 'nvtop'
    ];

    # ⚙️ Variables d'environnement pour accélérateur Nvidia Legacy
    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "nvidia";
      NVD_BACKEND = "direct";
      MOZ_DISABLE_RDD_SANDBOX = "1";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    };
  };
}
