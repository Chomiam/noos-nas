{
  # =========================================================================
  # ⚙️ VARIABLES UTILISATEUR : STEvE_OS NAS EDITION
  # Modifiez ce fichier pour adapter le NAS à votre matériel et vos besoins.
  # Les valeurs non spécifiées ici hériteront de vars-defaults.nix.
  # =========================================================================

  hostName = "steveos-nas";

  # Choix du GPU pour le transcodage matériel ("intel", "amd", "nvidia", "headless")
  gpuDriver = "intel";
  enableHardwareCodecs = true;

  # Sécurité et pare-feu
  firewall = {
    enable = true;
    strictLanOnly = false;
  };

  # Stockage & Volumes de données persistants (optionnel)
  # Vous pouvez déclarer vos disques ici ou dans hosts/nas/storage.local.nix.
  # Supporte tout système de fichiers (btrfs, ext4, xfs, zfs, etc.)
  # storage = {
  #   disks = [
  #     {
  #       device = "/dev/disk/by-label/STORAGE"; # ou "/dev/vg1/storage"
  #       mountPoint = "/mnt/storage";
  #       fsType = "btrfs"; # "ext4", "xfs", etc.
  #       options = [ "defaults" "compress=zstd" "noatime" "nofail" ];
  #     }
  #   ];
  # };

  # Services activés
  services = {
    dashboard = {
      enable = true;
      port = 9339;
    };
    samba = {
      enable = true;
      sharesPath = "/mnt/storage/shares";
    };
    sftp = {
      enable = true;
      port = 22;
    };
    jellyfin = {
      enable = true;
    };
    docker = {
      enable = true;
    };
    cockpit = {
      enable = true;
    };
  };
}
