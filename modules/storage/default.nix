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

  # Support FUSE pour les montages distants (sshfs)
  programs.fuse.userAllowOther = true;

  # Utilitaires de partitionnement, gestion des systèmes de fichiers et montages réseau distants
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
    sshfs        # Montage de serveurs sFTP distants (FUSE)
    cifs-utils   # Montage de partages SMB/CIFS distants
  ];

  # Répertoires et persistance pour montages distants et disques épinglés
  systemd.tmpfiles.rules = [
    "d /mnt/remote 0755 root root -"
    "d /mnt/remote/sftp 0755 root root -"
    "d /mnt/remote/smb 0755 root root -"
    "d /var/lib/noos 0755 root root -"
    "f /var/lib/noos/pinned_mounts.json 0644 root root -"
    "f /var/lib/noos/remote_mounts.json 0644 root root -"
    "d /var/lib/steveos 0755 root root -"
    "f /var/lib/steveos/pinned_mounts.json 0644 root root -"
    "f /var/lib/steveos/remote_mounts.json 0644 root root -"
  ];
}
