{ pkgs, ... }:

{
  imports = [
    ./mounts.nix
    ./smartd.nix
    ./spindown.nix
    ./scrub.nix
  ];

  # Modules noyau indispensables pour le stockage RAID (LVM2 RAID, mdadm, Device Mapper)
  boot.kernelModules = [
    "dm-mod"
    "dm-raid"
    "raid0"
    "raid1"
    "raid456"
    "raid10"
  ];

  # Service de gestion et montage automatique des périphériques amovibles (USB, disques externes, lecteurs optiques)
  services.udisks2.enable = true;
  services.devmon.enable = true;

  # Utilitaires de partitionnement et gestion des systèmes de fichiers
  environment.systemPackages = with pkgs; [
    parted       # Partitionnement GPT/MBR
    eject        # Éjection physique et logicielle (CD/DVD, USB)
    dosfstools   # Support FAT32/vfat (mkfs.vfat)
    exfatprogs   # Support exFAT (clés USB modernes)
    ntfs3g       # Support NTFS (disques Windows)
    e2fsprogs    # Support ext4/ext3
    btrfs-progs  # Support Btrfs
    xfsprogs     # Support XFS (mkfs.xfs)
    udisks2      # Outil udisksctl
  ];
}
