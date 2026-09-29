{ config, pkgs, lib, vars, ... }:

{
  # =========================================================================
  # 🖥️ CONFIGURATION PRINCIPALE DU NAS (STEvE_OS NAS EDITION)
  # =========================================================================

  imports = [
    ./hardware-configuration.nix
    ./storage.nix
    ../../modules
    ../../docker
  ];

  # =========================================================================
  # 🚀 CHARGEUR DE DÉMARRAGE UEFI (SYSTEMD-BOOT)
  # =========================================================================
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # =========================================================================
  # ⚙️ MAPPING DES VARIABLES VARS.NIX VERS LES OPTIONS STEvEOS.*
  # =========================================================================
  steveos = {
    hostName = vars.hostName;
    timeZone = vars.timeZone;
    defaultLocale = vars.defaultLocale;
    stateVersion = vars.stateVersion;

    keyboard = {
      layout = vars.keyboard.layout or "fr";
      variant = vars.keyboard.variant or "";
      keyMap = vars.keyboard.keyMap or "fr";
    };

    user = {
      username = vars.user.username;
      fullName = vars.user.fullName;
      homeDirectory = vars.user.homeDirectory;
      shell = vars.user.shell;
      extraGroups = vars.user.extraGroups;
      sshAuthorizedKeys = vars.user.sshAuthorizedKeys or [];
      initialHashedPassword = vars.user.initialHashedPassword or null;
    };

    hardware = {
      gpu = vars.gpuDriver or "intel";
      nvidiaLegacyBranch = vars.nvidiaLegacyBranch or "470";
      enableCodecs = vars.enableHardwareCodecs or true;
      cpuGovernor = vars.cpuGovernor or "powersave";
    };

    firewall = {
      enable = vars.firewall.enable or true;
      strictLanOnly = vars.firewall.strictLanOnly or false;
    };

    storage = {
      smartd.enable = vars.storage.smartd.enable or true;
      spindown = {
        enable = vars.storage.spindown.enable or true;
        idleMinutes = vars.storage.spindown.idleMinutes or 20;
      };
      btrfsScrub = {
        enable = vars.storage.btrfsScrub.enable or true;
        interval = vars.storage.btrfsScrub.interval or "monthly";
      };
      zfsAutoTrim = vars.storage.zfsAutoTrim or true;
      disks = vars.storage.disks or [];
    };

    services = {
      fail2ban = {
        enable = vars.fail2ban.enable or true;
        maxretry = vars.fail2ban.maxretry or 5;
        bantime = vars.fail2ban.bantime or "1h";
      };
      openssh = {
        enable = vars.services.sftp.enable or true;
        port = vars.services.sftp.port or 22;
      };
      samba = {
        enable = vars.services.samba.enable or true;
        workgroup = vars.services.samba.workgroup or "WORKGROUP";
        serverString = vars.services.samba.serverString or "STEvE_OS NAS";
        guestAccess = vars.services.samba.guestAccess or false;
        sharesPath = vars.services.samba.sharesPath or "/mnt/storage/shares";
        wsdd = vars.services.samba.wsdd or true;
      };
      nfs = {
        enable = vars.services.nfs.enable or false;
        sharesPath = vars.services.nfs.sharesPath or "/mnt/storage/shares";
      };
      sftp = {
        enable = vars.services.sftp.enable or true;
        port = vars.services.sftp.port or 22;
        chrootPath = vars.services.sftp.chrootPath or "/mnt/storage/sftp";
      };
      jellyfin = {
        enable = vars.services.jellyfin.enable or true;
        openFirewall = vars.services.jellyfin.openFirewall or true;
      };
      docker = {
        enable = vars.services.docker.enable or true;
        enableNvidia = vars.services.docker.enableNvidia or false;
      };
      podman = {
        enable = vars.services.podman.enable or false;
      };
      cockpit = {
        enable = vars.services.cockpit.enable or false;
        port = vars.services.cockpit.port or 9090;
      };
      tailscale = {
        enable = vars.services.tailscale.enable or false;
      };
      wireguard = {
        enable = vars.services.wireguard.enable or false;
      };
      netdata = {
        enable = vars.services.netdata.enable or false;
        port = vars.services.netdata.port or 19999;
      };
    };
  };

  # =========================================================================
  # 🚀 TABLEAU DE BORD STEvE_OS NAS EDITION (PORT 9339)
  # =========================================================================
  services.steveos-nas-dashboard = {
    enable = vars.services.dashboard.enable or true;
    port = vars.services.dashboard.port or 9339;
    openFirewall = true;
  };

  # =========================================================================
  # 🖥️ CONSOLE TTY & ACCUEIL DU SYSTÈME INSTALLÉ
  # =========================================================================
  # Pas d'autologin sur le système final : l'administration se fait sur le Web
  services.getty.autologinUser = lib.mkForce null;
  services.getty.helpLine = lib.mkForce "";

  # Bannière Catppuccin affichant l'adresse IP et l'accès au Dashboard (:9339)
  # Bannière Catppuccin affichant l'adresse IP et l'accès au Dashboard (:9339)
  environment.etc."issue".text =
    let
      esc = "\x1b";
    in ''

  ${esc}[1;35m╔══════════════════════════════════════════════════════════════════════════════╗${esc}[0m
  ${esc}[1;35m║${esc}[0m                   ${esc}[1;37m🚀 STEvE_OS NAS Edition — Tableau de Bord${esc}[0m                  ${esc}[1;35m║${esc}[0m
  ${esc}[1;35m╚══════════════════════════════════════════════════════════════════════════════╝${esc}[0m

    ${esc}[1;32m●${esc}[0m Adresse IP locale      : ${esc}[1;37m\4${esc}[0m
    ${esc}[1;36m●${esc}[0m Interface Web STEvE_OS : ${esc}[1;33mhttp://\4:9339${esc}[0m

  Ouvrez ce lien dans un navigateur pour vous connecter et administrer votre NAS.
  Console locale : saisissez vos identifiants administrateur ci-dessous.

'';
}
