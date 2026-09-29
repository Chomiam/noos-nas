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

    keyboard = {
      layout = mkOption { type = types.str; default = "fr"; };
      variant = mkOption { type = types.str; default = ""; };
      keyMap = mkOption { type = types.str; default = "fr"; };
    };

    user = {
      username = mkOption { type = types.str; default = "chomiam"; };
      fullName = mkOption { type = types.str; default = "Axel Valens"; };
      homeDirectory = mkOption { type = types.str; default = "/home/chomiam"; };
      shell = mkOption { type = types.str; default = "fish"; };
      initialHashedPassword = mkOption { type = types.nullOr types.str; default = null; };
      extraGroups = mkOption { type = types.listOf types.str; default = [ "wheel" "video" "render" "storage" "docker" ]; };
      sshAuthorizedKeys = mkOption { type = types.listOf types.str; default = []; };
    };

    hardware = {
      gpu = mkOption {
        type = types.enum [ "intel" "amd" "nvidia" "headless" ];
        default = "intel";
        description = "Type de GPU pour le transcodage matériel sur le NAS";
      };
      enableCodecs = mkOption {
        type = types.bool;
        default = true;
        description = "Activer les codecs matériels VA-API / QuickSync / Compute";
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
      jellyfin = {
        enable = mkOption { type = types.bool; default = true; };
        openFirewall = mkOption { type = types.bool; default = true; };
      };
      docker = {
        enable = mkOption { type = types.bool; default = true; };
        enableNvidia = mkOption { type = types.bool; default = false; };
      };
      podman = {
        enable = mkOption { type = types.bool; default = false; };
      };
      cockpit = {
        enable = mkOption { type = types.bool; default = true; };
        port = mkOption { type = types.int; default = 9090; };
      };
      tailscale = {
        enable = mkOption { type = types.bool; default = false; };
      };
      wireguard = {
        enable = mkOption { type = types.bool; default = false; };
      };
      netdata = {
        enable = mkOption { type = types.bool; default = false; };
        port = mkOption { type = types.int; default = 19999; };
      };
    };
  };
}
