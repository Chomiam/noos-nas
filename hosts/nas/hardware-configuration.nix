# Configuration matérielle par défaut (générique x86_64)
# La configuration matérielle spécifique à chaque machine est isolée dans :
# - /etc/nixos/hardware-configuration.nix (générée à l'installation)
# - ou hosts/nas/hardware.local.nix (fichier ignoré par Git)
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Chargeur de démarrage UEFI
  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  # Montages par défaut basés sur les labels d'installation Noos NAS
  fileSystems."/" = lib.mkDefault {
    device = "/dev/disk/by-label/ROOT";
    fsType = "btrfs";
  };

  fileSystems."/home" = lib.mkDefault {
    device = "/dev/disk/by-label/ROOT";
    fsType = "btrfs";
    options = [ "subvol=home" ];
  };

  fileSystems."/nix" = lib.mkDefault {
    device = "/dev/disk/by-label/ROOT";
    fsType = "btrfs";
    options = [ "subvol=nix" ];
  };

  fileSystems."/boot" = lib.mkDefault {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
