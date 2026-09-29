{
  # =========================================================================
  # ⚙️ VARIABLES PAR DÉFAUT : STEvE_OS NAS EDITION
  # Référence du schéma système pour NAS / Serveur de stockage
  # =========================================================================

  # Nom d'hôte de la machine (Hostname)
  hostName = "steveos-nas";

  # Localisation & Fuseau horaire
  timeZone = "Europe/Paris";
  defaultLocale = "fr_FR.UTF-8";

  # Disposition du clavier console
  keyboard = {
    layout = "fr";
    variant = "";
    keyMap = "fr";
  };

  # Version de l'état système NixOS
  stateVersion = "26.05";

  # Utilisateur principal
  user = {
    username = "chomiam";
    fullName = "Axel Valens";
    homeDirectory = "/home/chomiam";
    shell = "fish";
    initialHashedPassword = null;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "render"
      "storage"
      "docker"
      "podman"
    ];
    sshAuthorizedKeys = [];
  };

  # 🎮 Matériel & Transcodage GPU
  # Valeurs possibles : "intel" (QuickSync), "amd" (VA-API), "nvidia" (NVENC), "headless" (aucun GPU / software)
  gpuDriver = "intel";
  enableHardwareCodecs = true;

  # Profil énergétique processeur serveur ("powersave", "schedutil", "performance")
  cpuGovernor = "powersave";

  # 🛡️ Pare-feu & Sécurité
  firewall = {
    enable = true;
    strictLanOnly = false;
  };
  fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "1h";
  };

  # 💾 Stockage & Maintenance des Disques
  storage = {
    # Déclaration optionnelle des disques/volumes à monter de manière persistante.
    # Supporte TOUS les systèmes de fichiers (btrfs, ext4, xfs, zfs, etc.).
    # Laissé vide par défaut afin de ne pas écraser les montages locaux lors des mises à jour.
    disks = [
      # Exemple de montage persistant :
      # {
      #   device = "/dev/disk/by-label/STORAGE"; # ou "/dev/vg1/storage", "/dev/disk/by-uuid/..."
      #   mountPoint = "/mnt/storage";
      #   fsType = "btrfs"; # ou "ext4", "xfs", "zfs", etc.
      #   options = [ "defaults" "compress=zstd" "noatime" "nofail" ];
      # }
    ];
    smartd = {
      enable = true;
      notifications = true;
    };
    spindown = {
      enable = true;
      idleMinutes = 20;
    };
    btrfsScrub = {
      enable = true;
      interval = "monthly";
    };
    zfsAutoTrim = true;
  };

  # 🌐 Services Réseau & Partages NAS
  services = {
    # Tableau de bord web STEvE_OS
    dashboard = {
      enable = true;
      port = 9339;
    };
    # Partage de fichiers Windows / macOS / Linux
    samba = {
      enable = true;
      workgroup = "WORKGROUP";
      serverString = "STEvE_OS NAS Edition";
      guestAccess = false;
      sharesPath = "/mnt/storage/shares";
      wsdd = true;
    };

    # Partage de fichiers UNIX haute performance
    nfs = {
      enable = false;
      sharesPath = "/mnt/storage/shares";
    };

    # Transferts de fichiers chiffrés SSH / sFTP
    sftp = {
      enable = true;
      port = 22;
      chrootPath = "/mnt/storage/sftp";
    };

    # Serveur Multimédia & Transcodage matériel GPU
    jellyfin = {
      enable = true;
      openFirewall = true;
    };

    # Moteur de conteneurs pour applications NAS
    docker = {
      enable = true;
      enableNvidia = false;
    };
    podman = {
      enable = false;
    };

    # Interfaces Web d'administration
    cockpit = {
      enable = true;
      port = 9090;
    };

    # Accès distant sécurisé
    tailscale = {
      enable = false;
    };
    wireguard = {
      enable = false;
    };

    # Supervision & Monitoring
    netdata = {
      enable = false;
      port = 19999;
    };
  };
}
