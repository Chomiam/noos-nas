{
  # =========================================================================
  # ⚙️ VARIABLES UTILISATEUR : STEvE_OS NAS EDITION
  # Modifiez ce fichier pour adapter le NAS à votre matériel et vos besoins.
  # Les valeurs non spécifiées ici hériteront de vars-defaults.nix.
  # =========================================================================

  hostName = "steveos-nas";

  # Choix du GPU pour le transcodage matériel :
  # - "intel"          : Intel QuickSync (iGPU UHD/Iris Xe, Core Ultra, N100, Arc A380/A770)
  # - "amd"            : AMD Radeon / APU (VA-API radeonsi, ROCm OpenCL)
  # - "nvidia"         : Nvidia Moderne (Turing GTX 1650 et supérieur, RTX 20/30/40/50, NVENC/NVDEC)
  # - "nvidia-legacy"  : Nvidia Legacy (pre-Turing / inférieur à GTX 1650 : Kepler, Maxwell, Pascal, Fermi)
  # - "headless"       : Aucun GPU / transcodage software CPU
  gpuDriver = "intel";
  nvidiaLegacyBranch = "470"; # "470" (recommandé Kepler/GTX 600-700-800) ou "390"
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
