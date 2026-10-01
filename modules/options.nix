{ lib, ... }:

with lib;

{
  options.steveos = {
    hostName = mkOption {
      type = types.str;
      default = "steveos-nas";
      description = "Nom d'hôte du NAS";
    };

    timeZone = mkOption {
      type = types.str;
      default = "Europe/Paris";
      description = "Fuseau horaire";
    };

    defaultLocale = mkOption {
      type = types.str;
      default = "fr_FR.UTF-8";
      description = "Locale système";
    };

    stateVersion = mkOption {
      type = types.str;
      default = "26.05";
      description = "Version d'état NixOS";
    };

    boot = {
      kernel = mkOption {
        type = types.enum [ "lts" "6_12" "6_6" "latest" "default" ];
        default = "lts";
        description = "Branche du noyau Linux (lts = Linux 6.12 LTS recommandé pour la stabilité maximale d'un NAS, 6_6, latest, default)";
      };
    };

    keyboard = {
      layout = mkOption { type = types.str; default = "fr"; };
      variant = mkOption { type = types.str; default = ""; };
      keyMap = mkOption { type = types.str; default = "fr"; };
    };

    user = {
      username = mkOption { type = types.str; default = "chomiam"; description = "Identifiant de l'administrateur principal"; };
      fullName = mkOption { type = types.str; default = "Axel Valens"; description = "Nom complet de l'administrateur"; };
      homeDirectory = mkOption {
        type = types.str;
        default = "/home/${config.steveos.user.username}";
        defaultText = lib.literalExpression ''"/home/${config.steveos.user.username}"'';
        description = "Répertoire personnel de l'administrateur";
      };
      shell = mkOption { type = types.str; default = "fish"; };
      initialHashedPassword = mkOption { type = types.nullOr types.str; default = null; };
      extraGroups = mkOption { type = types.listOf types.str; default = [ "wheel" "video" "render" "storage" "docker" ]; };
      sshAuthorizedKeys = mkOption { type = types.listOf types.str; default = []; };
    };

    hardware = {
      gpu = mkOption {
        type = types.enum [ "intel" "amd" "nvidia" "nvidia-legacy" "headless" ];
        default = "intel";
        description = "Type de GPU pour le transcodage matériel sur le NAS (intel, amd, nvidia moderne [Turing/GTX 1650+], nvidia-legacy [Kepler/Maxwell/Pascal/pre-Turing], headless)";
      };
      nvidiaLegacyBranch = mkOption {
        type = types.enum [ "470" "390" ];
        default = "470";
        description = "Version de la branche Nvidia Legacy (470 pour Kepler/Maxwell/GTX 600-700-800, 390 pour très anciens GPU Fermi)";
      };
      enableCodecs = mkOption {
        type = types.bool;
        default = true;
        description = "Activer l'ensemble des codecs matériels VA-API / QuickSync / VDPAU / Compute OpenCL";
      };
      cpuGovernor = mkOption {
        type = types.enum [ "powersave" "schedutil" "performance" "ondemand" ];
        default = "powersave";
        description = "Gouverneur de fréquence CPU pour optimiser la consommation électrique";
      };
    };

    firewall = {
      enable = mkOption { type = types.bool; default = true; description = "Activer le pare-feu"; };
      strictLanOnly = mkOption { type = types.bool; default = false; description = "Restreindre strictement les partages au réseau local"; };
    };

    storage = {
      smartd = { enable = mkOption { type = types.bool; default = true; }; };
      spindown = {
        enable = mkOption { type = types.bool; default = true; };
        idleMinutes = mkOption { type = types.int; default = 20; };
      };
      btrfsScrub = {
        enable = mkOption { type = types.bool; default = true; };
        interval = mkOption { type = types.str; default = "monthly"; };
      };
      zfsAutoTrim = mkOption { type = types.bool; default = true; };
      disks = mkOption {
        type = types.listOf (types.submodule {
          options = {
            device = mkOption {
              type = types.str;
              description = "Chemin du périphérique ou volume (ex: /dev/disk/by-label/STORAGE, /dev/vg1/storage, /dev/disk/by-uuid/...)";
            };
            mountPoint = mkOption {
              type = types.str;
              description = "Point de montage (ex: /mnt/storage)";
            };
            fsType = mkOption {
              type = types.str;
              default = "auto";
              description = "Système de fichiers (btrfs, ext4, xfs, zfs, etc.)";
            };
            options = mkOption {
              type = types.listOf types.str;
              default = [ "defaults" "nofail" ];
              description = "Options de montage du système de fichiers";
            };
          };
        });
        default = [];
        description = "Liste déclarative des volumes de stockage utilisateur à monter de manière persistante";
      };
    };

    services = {
      fail2ban = {
        enable = mkOption { type = types.bool; default = true; };
        maxretry = mkOption { type = types.int; default = 5; };
        bantime = mkOption { type = types.str; default = "1h"; };
      };
      openssh = {
        enable = mkOption { type = types.bool; default = true; };
        port = mkOption { type = types.int; default = 22; };
        permitRootLogin = mkOption { type = types.str; default = "no"; };
      };
      samba = {
        enable = mkOption { type = types.bool; default = true; };
        workgroup = mkOption { type = types.str; default = "WORKGROUP"; };
        serverString = mkOption { type = types.str; default = "STEvE_OS NAS"; };
        guestAccess = mkOption { type = types.bool; default = false; };
        sharesPath = mkOption { type = types.str; default = "/mnt/storage/shares"; };
        wsdd = mkOption { type = types.bool; default = true; };
      };
      nfs = {
        enable = mkOption { type = types.bool; default = false; };
        sharesPath = mkOption { type = types.str; default = "/mnt/storage/shares"; };
      };
      sftp = {
        enable = mkOption { type = types.bool; default = true; };
        port = mkOption { type = types.int; default = 22; };
        chrootPath = mkOption { type = types.str; default = "/mnt/storage/sftp"; };
      };
      docker = {
        enable = mkOption { type = types.bool; default = true; };
        enableNvidia = mkOption { type = types.bool; default = false; };
      };
      podman = {
        enable = mkOption { type = types.bool; default = false; };
      };
      wireguard = {
        enable = mkOption { type = types.bool; default = true; description = "Serveur VPN WireGuard pour accès distant sécurisé"; };
        port = mkOption { type = types.int; default = 51820; description = "Port d'écoute UDP de WireGuard"; };
        interface = mkOption { type = types.str; default = "wg0"; description = "Nom de l'interface WireGuard"; };
        ip = mkOption { type = types.str; default = "10.100.0.1/24"; description = "Sous-réseau IP du tunnel WireGuard"; };
      };
      netdata = {
        enable = mkOption { type = types.bool; default = false; };
        port = mkOption { type = types.int; default = 19999; };
      };
    };
  };
}
