{ config, pkgs, lib, ... }:

let
  u = config.steveos.user;
in
{
  programs.fish.enable = true;

  users.groups.storage = {};

  users.users.${u.username} = {
    isNormalUser = true;
    description = u.fullName;
    home = u.homeDirectory;
    shell = if u.shell == "fish" then pkgs.fish else pkgs.bashInteractive;
    extraGroups = u.extraGroups ++ [ "storage" "disk" ];
    openssh.authorizedKeys.keys = u.sshAuthorizedKeys;
    initialHashedPassword = u.initialHashedPassword;
  };

  # 🐚 Configuration avancée de Bash avec autocomplétion intelligente
  programs.bash = {
    completion.enable = true;
    enable = true;
    shellInit = ''
      # Options avancées d'historique et autocomplétion
      shopt -s histappend
      shopt -s checkwinsize
      shopt -s globstar 2>/dev/null || true
      shopt -s nocaseglob 2>/dev/null || true

      # Chargement de zoxide (navigation rapide avec autocomplétion)
      if command -v zoxide >/dev/null 2>&1; then
        eval "$(zoxide init bash)"
      fi
    '';
  };

  # 🔍 Recherche floue et autocomplétion interactive fzf (Ctrl-R, Alt-C)
  programs.fzf = {
    keybindings = true;
    fuzzyCompletion = true;
  };

  # 🛠️ Outil CLI 'nh' (Nix Helper) avec chemin flake par défaut vers /etc/nixos
  programs.nh = {
    enable = true;
    flake = "/etc/nixos";
  };

  # 🔒 Configuration globale Git pour autoriser /etc/nixos et éviter les erreurs dubious ownership
  programs.git = {
    enable = true;
    config = {
      safe.directory = [
        "/etc/nixos"
        "/etc/nixos/*"
        "/etc/nixos/.git"
      ];
      merge = {
        ours = {
          driver = "true";
        };
      };
    };
  };


  # 🔑 Droits d'accès et création déclarative des dossiers personnels et de stockage (/home et /mnt)
  system.activationScripts.etcNixosPermissions = lib.stringAfter [ "users" "groups" ] ''
    if [ -d /etc/nixos ]; then
      chown -R ${u.username}:users /etc/nixos
      chmod -R u+rwX,g+rwX /etc/nixos
      # Garantir que git utilise le merge driver 'ours' localement
      if [ -d /etc/nixos/.git ]; then
        ${pkgs.git}/bin/git -C /etc/nixos config merge.ours.driver true || true
      fi
    fi

    # Propriété déclarative complète de /home pour l'utilisateur
    if [ -d /home ]; then
      chown ${u.username}:users /home
      chmod 0755 /home
    fi

    # Création des répertoires standards en minuscules sans accents (optimal pour Docker et scripts)
    mkdir -p "${u.homeDirectory}/documents" \
             "${u.homeDirectory}/images" \
             "${u.homeDirectory}/videos" \
             "${u.homeDirectory}/musique" \
             "${u.homeDirectory}/telechargements"

    # Nettoyage sécurisé des anciens dossiers accentués / majuscules et des liens symboliques obsolètes
    for old in Documents Images Vidéos Musique Téléchargements Pictures Videos Music Downloads downloads download pictures music; do
      if [ -L "${u.homeDirectory}/$old" ]; then
        rm -f "${u.homeDirectory}/$old" 2>/dev/null || true
      elif [ -d "${u.homeDirectory}/$old" ]; then
        rmdir "${u.homeDirectory}/$old" 2>/dev/null || true
      fi
    done

    chown -R ${u.username}:users "${u.homeDirectory}"
    chmod 0755 "${u.homeDirectory}" \
               "${u.homeDirectory}/documents" \
               "${u.homeDirectory}/images" \
               "${u.homeDirectory}/videos" \
               "${u.homeDirectory}/musique" \
               "${u.homeDirectory}/telechargements"

    # Propriété déclarative de /mnt et de ses montages pour l'utilisateur et le groupe storage (setgid 2775)
    mkdir -p /mnt /mnt/storage /mnt/storage/shares /mnt/storage/media /mnt/storage/sftp /mnt/storage/games
    chown ${u.username}:storage /mnt
    chmod 2775 /mnt
    for d in /mnt/*; do
      if [ -d "$d" ]; then
        chown ${u.username}:storage "$d"
        chmod 2775 "$d"
      fi
    done
  '';

  # 👥 Script d'activation pour la résilience et persistance des utilisateurs créés via le Dashboard
  system.activationScripts.steveosUsersSync = lib.stringAfter [ "users" "groups" ] ''
    mkdir -p /var/lib/steveos
    chmod 0750 /var/lib/steveos

    REGISTRY_FILE="/var/lib/steveos/users-registry.json"
    if [ -f "$REGISTRY_FILE" ]; then
      # Restauration et synchronisation des groupes personnalisés enregistrés
      for grp in $(${pkgs.jq}/bin/jq -r '(.custom_group_descriptions // {}) | keys[]' "$REGISTRY_FILE" 2>/dev/null); do
        if [ -n "$grp" ] && ! getent group "$grp" >/dev/null 2>&1; then
          ${pkgs.shadow}/bin/groupadd "$grp" 2>/dev/null || true
        fi
      done

      # Restauration et vérification des comptes utilisateurs enregistrés
      for usr in $(${pkgs.jq}/bin/jq -r '(.users // {}) | keys[]' "$REGISTRY_FILE" 2>/dev/null); do
        if [ -n "$usr" ] && [ "$usr" != "root" ] && [ "$usr" != "${u.username}" ]; then
          if ! id "$usr" >/dev/null 2>&1; then
            allow_shell=$(${pkgs.jq}/bin/jq -r "(.users[\"$usr\"].allow_shell // false)" "$REGISTRY_FILE" 2>/dev/null)
            if [ "$allow_shell" = "true" ]; then
              sh="/run/current-system/sw/bin/bash"
            else
              sh="/run/current-system/sw/bin/nologin"
            fi
            ${pkgs.shadow}/bin/useradd -m -s "$sh" -g users "$usr" 2>/dev/null || true
            chmod 0750 "/home/$usr" 2>/dev/null || true
          fi
        fi
      done
    fi

    # 🛡️ Protection anti-suppression : Restauration automatique de tout compte utilisateur préexistant dans /home
    # Empêche NixOS de verrouiller ou purger un compte administrateur non encore déclaré dans vars.nix (ex: mow)
    for h in /home/*; do
      if [ -d "$h" ]; then
        usr=$(basename "$h")
        if [ -n "$usr" ] && [ "$usr" != "root" ] && [ "$usr" != "${u.username}" ] && [ "$h" != "${u.homeDirectory}" ] && [ "$usr" != "lost+found" ] && ! id "$usr" >/dev/null 2>&1; then
          # Compte orphelin avec home valide : recréation automatique dans /etc/passwd avec droits de gestion
          ${pkgs.shadow}/bin/useradd -M -d "$h" -s "/run/current-system/sw/bin/bash" -g users -G wheel,storage,video,render "$usr" 2>/dev/null || true
        fi
      fi
    done
  '';

  # 🛡️ Sauvegarde permanente et résilience des fichiers spécifiques (vars.nix, hardware-configuration.nix)
  system.activationScripts.etcNixosBackup = lib.stringAfter [ "users" "groups" ] ''
    # 1. Sauvegarde et sécurisation de vars.nix
    if [ -f /etc/nixos/vars.nix ]; then
      # Si vars.nix est corrompu par des marqueurs de conflit Git, restauration d'urgence
      if grep -qE '^(<{7}|={7}|>{7})' /etc/nixos/vars.nix 2>/dev/null; then
        if [ -f /etc/nixos/.vars.nix.backup ]; then
          echo "⚠️ Conflit Git détecté dans vars.nix ! Restauration automatique depuis la sauvegarde locale..."
          cp -f /etc/nixos/.vars.nix.backup /etc/nixos/vars.nix
        fi
      fi

      # Sauvegarde locale saine
      if [ ! -f /etc/nixos/.vars.nix.backup ]; then
        cp -f /etc/nixos/vars.nix /etc/nixos/.vars.nix.backup
        chmod 0600 /etc/nixos/.vars.nix.backup
      else
        BACKUP_USER=$(grep -oP 'username\s*=\s*"\K[^"]+' /etc/nixos/.vars.nix.backup 2>/dev/null || true)
        CURRENT_USER=$(grep -oP 'username\s*=\s*"\K[^"]+' /etc/nixos/vars.nix 2>/dev/null || true)
        if [ -n "$CURRENT_USER" ] && { [ "$BACKUP_USER" = "$CURRENT_USER" ] || [ -z "$BACKUP_USER" ]; }; then
          cp -f /etc/nixos/vars.nix /etc/nixos/.vars.nix.backup
          chmod 0600 /etc/nixos/.vars.nix.backup
        fi
      fi
    fi

    # 2. Sauvegarde de hardware-configuration.nix
    for hw in /etc/nixos/hardware-configuration.nix /etc/nixos/hosts/nas/hardware-configuration.nix; do
      if [ -f "$hw" ] && [ ! -f /etc/nixos/.hardware-configuration.nix.backup ]; then
        cp -f "$hw" /etc/nixos/.hardware-configuration.nix.backup
        chmod 0600 /etc/nixos/.hardware-configuration.nix.backup
        break
      fi
    done
  '';

  # 📁 Règles systemd-tmpfiles déclaratives pour /home, dossiers personnels, /mnt et /var/lib/steveos
  systemd.tmpfiles.rules = [
    "d /var/lib/steveos 0750 root wheel - -"
    "d /etc/nixos 0775 ${u.username} users - -"
    "d /mnt/storage/games 2775 ${u.username} storage - -"
    "d /mnt/storage/shares 2775 ${u.username} storage - -"
    "d /home 0755 ${u.username} users - -"
    "z /home 0755 ${u.username} users - -"
    "d ${u.homeDirectory} 0755 ${u.username} users - -"
    "z ${u.homeDirectory} 0755 ${u.username} users - -"
    "d ${u.homeDirectory}/documents 0755 ${u.username} users - -"
    "d ${u.homeDirectory}/images 0755 ${u.username} users - -"
    "d ${u.homeDirectory}/videos 0755 ${u.username} users - -"
    "d ${u.homeDirectory}/musique 0755 ${u.username} users - -"
    "d ${u.homeDirectory}/telechargements 0755 ${u.username} users - -"
  ];

  # Paquets de base pour l'administration en ligne de commande & autocomplétion
  environment.systemPackages = with pkgs; [
    # Complétion & Productivité Bash
    bash-completion
    nix-bash-completions
    fzf
    zoxide
    blesh
    starship

    # Outils CLI d'administration
    git
    gh
    nvd
    cfspeedtest
    curl
    wget
    openssl
    whois
    htop
    btop
    tmux
    neovim
    rsync
    pciutils
    usbutils
    lm_sensors
    smartmontools
    hdparm
    ncdu
    tree
    nh

    # Outils Réseau & Diagnostic de Bande Passante
    vnstat
    iftop
    bmon
    ethtool

    # Outils Stockage, RAID & Systèmes de fichiers
    mdadm
    lvm2
    btrfs-progs
    xfsprogs
    e2fsprogs

    # Outils d'archivage & compression
    zip
    unzip
    p7zip
    gnutar
    gzip
    bzip2
    xz
    zstd
    parted

    # Traitement d'images et formats RAW/HEIC (Visualiseur STEvE_OS)
    imagemagick
    exiftool
    libheif
    libraw
    ffmpeg
    yt-dlp

    # Visualiseur universel de documents bureautiques
    libreoffice-still
  ];
}
