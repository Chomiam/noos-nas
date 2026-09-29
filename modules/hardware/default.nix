{ pkgs, ... }:

{
  imports = [
    ./intel.nix
    ./amd.nix
    ./nvidia.nix
    ./nvidia-legacy.nix
    ./power.nix
  ];

  # Activation globale de la couche graphique matérielle
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Outils universels de détection et d'inspection matérielle
  environment.systemPackages = with pkgs; [
    libva-utils # vainfo
    pciutils    # lspci
    usbutils    # lsusb
  ];
}
