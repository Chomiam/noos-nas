{ config, lib, pkgs, ... }:

let
  isIntel = config.steveos.hardware.gpu == "intel";
  codecs = config.steveos.hardware.enableCodecs;
in
{
  config = lib.mkIf isIntel {
    # Active la couche graphique headless pour le transcodage
    hardware.graphics = {
      enable = true;
      extraPackages = lib.mkIf codecs (with pkgs; [
        intel-media-driver    # Pilote moderne iHD pour Broadwell, Skylake, Alder Lake, N100, Core Ultra
        intel-vaapi-driver    # Pilote i965 pour matériels plus anciens
        libva
        libva-utils           # vainfo pour le diagnostic
        vpl-gpu-rt            # Runtime Intel oneVPL moderne (décodage/encodage matériel AV1, HEVC)
        intel-compute-runtime # OpenCL pour tonemapping HDR et calcul IA
      ]);
    };

    # Charge les modules de virtualisation et DRM dans le noyau
    boot.kernelModules = [ "kvm-intel" ];
  };
}
