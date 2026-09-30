{ config, lib, pkgs, ... }:

let
  isIntel = config.steveos.hardware.gpu == "intel";
  codecs = config.steveos.hardware.enableCodecs;
in
{
  config = lib.mkIf isIntel {
    # 🎮 Couche graphique matérielle & tous les codecs Intel (iHD, i965, oneVPL, OpenCL)
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = lib.mkIf codecs (with pkgs; [
        intel-media-driver    # Pilote moderne iHD (Broadwell, Skylake, Comet/Alder Lake, N100, Core Ultra, Arc Alchemist DG2)
        intel-vaapi-driver    # Pilote i965 historique pour CPU/iGPU plus anciens (Haswell, Ivy Bridge)
        libva                 # Bibliothèque d'abstraction Video Acceleration API
        libva-utils           # Outils d'inspection et test des codecs matériels (vainfo)
        vpl-gpu-rt            # Runtime Intel oneVPL pour décodage et encodage matériel avancé (AV1, HEVC 10-bit)
        intel-compute-runtime # OpenCL moderne pour le tonemapping HDR vers SDR matériel (Jellyfin, Plex, FFmpeg)
        libvdpau-va-gl        # Passerelle VDPAU vers VA-API pour compatibilité logicielle universelle
      ]);
    };

    # 🚀 Modules noyau DRM & virtualisation
    boot.initrd.kernelModules = [ "i915" ];
    boot.kernelModules = [ "kvm-intel" ];

    # 🛠️ Utilitaires d'inspection et monitoring GPU en temps réel
    environment.systemPackages = with pkgs; [
      libva-utils          # Commande 'vainfo' pour lister tous les profils de décodage/encodage supportés
      intel-gpu-tools      # Commande 'intel_gpu_top' pour suivre la charge du moteur de transcodage (Video / VideoEnhance)
      clinfo               # Commande 'clinfo' pour vérifier les plateformes de calcul OpenCL
      nvtopPackages.intel  # Moniteur interactif temps réel (fréquence GPU, ventilateurs, VRAM, processus de transcodage)
    ];

    # ⚙️ Variables d'environnement optimales pour le transcodage matériel Intel
    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD";
      VDPAU_DRIVER = "va_gl";
    };
  };
}
