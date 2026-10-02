{
  # =========================================================================
  # ⚙️ VARIABLES UTILISATEUR : NOOS NAS EDITION
  # Modifiez ce fichier pour adapter le NAS à votre matériel et vos besoins.
  # Les valeurs non spécifiées ici hériteront de vars-defaults.nix.
  # =========================================================================

  hostName = "noos-nas";

  # =========================================================================
  # 👤 COMPTE ADMINISTRATEUR PRINCIPAL
  # Définissez ici votre compte utilisateur personnel pour administrer le NAS.
  # Si non renseigné, le compte par défaut de vars-defaults.nix est utilisé.
  # =========================================================================
  # user = {
  #   username = "admin";               # Votre identifiant de connexion (ex: "mow", "admin")
  #   fullName = "Administrateur NAS";    # Votre nom ou pseudonyme
  #   homeDirectory = "/home/admin";    # /home/<username>
  #   shell = "fish";                     # "bash" ou "fish"
  # };

  # Choix du GPU pour le transcodage matériel :
  # - "intel"          : Intel QuickSync (iGPU UHD/Iris Xe, Core Ultra, N100, Arc A380/A770)
  # - "amd"            : AMD Radeon / APU (VA-API radeonsi, ROCm OpenCL)
  # - "nvidia"         : Nvidia Moderne (Turing GTX 1650 et supérieur, RTX 20/30/40/50, NVENC/NVDEC)
  # - "nvidia-legacy"  : Nvidia Legacy (pre-Turing / inférieur à GTX 1650 : Kepler, Maxwell, Pascal, Fermi)
  # - "headless"       : Aucun GPU / transcodage software CPU
  gpuDriver = "intel";
  nvidiaLegacyBranch = "470"; # "470" (recommandé Kepler/GTX 600-700-800) ou "390"
  enableHardwareCodecs = true;

  # Noyau Linux pour le NAS :
  # - "lts"     : Dernier noyau stable LTS NixOS (actuellement 6.18 - Recommandé NAS : stabilité maximale en continu, ZFS, Docker, réseau)
  # - "6_12"    : Linux 6.12 LTS (épinglé)
  # - "6_6"     : Linux 6.6 LTS (épinglé)
  # - "latest"  : Dernier noyau amont de pointe (Linux 7.x)
  # - "default" : Noyau par défaut Nixpkgs
  kernel = "lts";

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
    docker = {
      enable = true;
    };
    wireguard = {
      enable = true;
      port = 51820;
    };
    virtualisation = {
      enable = true;
      storagePool = "/mnt/storage/vms";
      isoPool = "/mnt/storage/isos";
    };
    nixLd = {
      enable = true;
    };
  };
}
