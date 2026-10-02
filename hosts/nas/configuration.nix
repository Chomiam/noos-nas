{ config, pkgs, lib, vars, ... }:

{
  # =========================================================================
  # 🖥️ CONFIGURATION PRINCIPALE DU NAS (NOOS NAS EDITION)
  # =========================================================================

  imports = [
    (if builtins.pathExists ../../hardware-configuration.nix
     then ../../hardware-configuration.nix
     else ./hardware-configuration.nix)
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
  # ⚙️ MAPPING DES VARIABLES VARS.NIX VERS LES OPTIONS NOOS.*
  # =========================================================================
  noos = {
    hostName = vars.hostName;
    timeZone = vars.timeZone;
    defaultLocale = vars.defaultLocale;
    stateVersion = vars.stateVersion;

    boot = {
      kernel = vars.kernel or "lts";
    };

    keyboard = {
      layout = vars.keyboard.layout or "fr";
      variant = vars.keyboard.variant or "";
      keyMap = vars.keyboard.keyMap or "fr";
    };

    user = {
      username = vars.user.username;
      fullName = if (vars.user ? fullName && vars.user.fullName != null && vars.user.fullName != "")
                 then vars.user.fullName
                 else "Administrateur Noos";
      homeDirectory = if (vars.user ? homeDirectory && vars.user.homeDirectory != null && vars.user.homeDirectory != "")
                      then vars.user.homeDirectory
                      else "/home/${vars.user.username}";
      shell = vars.user.shell;
      extraGroups = vars.user.extraGroups;
      sshAuthorizedKeys = vars.user.sshAuthorizedKeys or [];
      initialHashedPassword = vars.user.initialHashedPassword or vars.user.hashedPassword or null;
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
        serverString = vars.services.samba.serverString or "Noos NAS";
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
      docker = {
        enable = vars.services.docker.enable or true;
        enableNvidia = vars.services.docker.enableNvidia or false;
      };
      podman = {
        enable = vars.services.podman.enable or false;
      };
      wireguard = {
        enable = vars.services.wireguard.enable or true;
      };
      virtualisation = {
        enable = vars.services.virtualisation.enable or true;
        storagePool = vars.services.virtualisation.storagePool or "/mnt/storage/vms";
        isoPool = vars.services.virtualisation.isoPool or "/mnt/storage/isos";
        enableIommu = vars.services.virtualisation.enableIommu or true;
      };
      nixLd = {
        enable = vars.services.nixLd.enable or true;
      };
      netdata = {
        enable = vars.services.netdata.enable or false;
        port = vars.services.netdata.port or 19999;
      };
    };
  };

  # =========================================================================
  # 🚀 TABLEAU DE BORD NOOS NAS EDITION (PORT 9339)
  # =========================================================================
  services.noos-nas-dashboard = {
    enable = vars.services.dashboard.enable or true;
    port = vars.services.dashboard.port or 9339;
    openFirewall = true;
    user = vars.user.username;
  };

  # Dépendance explicite : s'assurer que libvirtd est prêt quand le dashboard démarre
  systemd.services.noos-nas-dashboard = {
    wants = [ "libvirtd.service" ];
    after = [ "libvirtd.service" ];
  };

  # =========================================================================
  # 🖥️ CONSOLE TTY & ACCUEIL DU SYSTÈME INSTALLÉ
  # =========================================================================
  # Pas d'autologin sur le système final : l'administration se fait sur le Web
  # On force agetty à lire EXCLUSIVEMENT /run/issue pour éviter les doublons et les fausses IP
  services.getty = {
    autologinUser = lib.mkForce null;
    helpLine = lib.mkForce "";
    extraArgs = [ "--issue-file" "/run/issue" ];
  };

  # Supprimer le contenu par défaut de /etc/issue pour éviter tout conflit
  environment.etc."issue".text = "";

  # Démon de mise à jour dynamique de la bannière console avec la VRAIE IP LAN (ignore docker0 & loopback)
  systemd.services.noos-issue-update = {
    description = "Surveillance et mise à jour de la bannière console Noos avec l'adresse IP réseau";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    before = [ "getty@tty1.service" ];
    path = with pkgs; [ iproute2 gawk gnugrep hostname util-linux systemd coreutils ];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = "5s";
    };
    script = ''
      get_lan_ip() {
        # 1. IP depuis la route vers la passerelle / Internet
        local ip=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}')
        if [ -n "$ip" ] && [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && [[ "$ip" != 127.* ]] && [[ "$ip" != 172.17.* ]] && [[ "$ip" != 169.254.* ]] && [[ "$ip" != 192.168.122.* ]] && [[ "$ip" != 10.100.0.* ]]; then
          echo "$ip"
          return
        fi

        # 2. Chercher sur les interfaces physiques uniquement (eth*, en*, wl*)
        for iface in $(ip -o link show up 2>/dev/null | awk -F': ' '{print $2}' | grep -E '^(en|eth|wl)'); do
          local ip=$(ip -4 -o addr show dev "$iface" scope global 2>/dev/null | awk '{split($4, a, "/"); print a[1]}' | head -n1)
          if [ -n "$ip" ] && [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && [[ "$ip" != 127.* ]] && [[ "$ip" != 172.17.* ]] && [[ "$ip" != 169.254.* ]] && [[ "$ip" != 192.168.122.* ]] && [[ "$ip" != 10.100.0.* ]]; then
            echo "$ip"
            return
          fi
        done

        echo ""
      }

      LAST_IP=""

      while true; do
        IP=$(get_lan_ip)
        if [ -n "$IP" ] && [ "$IP" != "$LAST_IP" ]; then
          LAST_IP="$IP"
          cat << EOF > /run/issue
\e{bold}\e{lightmagenta}╔══════════════════════════════════════════════════════════════════════════════╗\e{reset}
\e{bold}\e{lightmagenta}║\e{reset}                   \e{bold}\e{white}🚀 Noos NAS Edition — Tableau de Bord\e{reset}                  \e{bold}\e{lightmagenta}║\e{reset}
\e{bold}\e{lightmagenta}╚══════════════════════════════════════════════════════════════════════════════╝\e{reset}

  \e{bold}\e{green}●\e{reset} Adresse IP locale      : \e{bold}\e{white}''${IP}\e{reset}
  \e{bold}\e{cyan}●\e{reset} Interface Web Noos     : \e{bold}\e{yellow}http://''${IP}:9339\e{reset}

  Connectez-vous via l'interface Web pour administrer votre NAS.
  Console locale : saisissez vos identifiants administrateur ci-dessous.

EOF
          # Recharger getty@tty1 pour afficher immédiatement la nouvelle IP
          systemctl restart getty@tty1.service 2>/dev/null || true
        elif [ -z "$IP" ] && [ -z "$LAST_IP" ]; then
          cat << 'EOF' > /run/issue
\e{bold}\e{lightmagenta}╔══════════════════════════════════════════════════════════════════════════════╗\e{reset}
\e{bold}\e{lightmagenta}║\e{reset}                   \e{bold}\e{white}🚀 Noos NAS Edition — Tableau de Bord\e{reset}                  \e{bold}\e{lightmagenta}║\e{reset}
\e{bold}\e{lightmagenta}╚══════════════════════════════════════════════════════════════════════════════╝\e{reset}

  \e{bold}\e{yellow}●\e{reset} Adresse IP locale      : \e{bold}\e{yellow}Attente d'adresse IP (DHCP en cours...)\e{reset}
  \e{bold}\e{cyan}●\e{reset} Interface Web Noos     : \e{bold}\e{yellow}http://<adresse-ip>:9339\e{reset}

  Connectez-vous via l'interface Web pour administrer votre NAS.
  Console locale : saisissez vos identifiants administrateur ci-dessous.

EOF
        fi

        sleep 4
      done
    '';
  };

  # =========================================================================
  # ⚙️ ENVIRONNEMENT SYSTEMD PAR DÉFAUT (CHEMINS NIXOS COMPLETS)
  # =========================================================================
  systemd.settings.Manager = {
    DefaultEnvironment = "PATH=/run/wrappers/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin";
  };
}



