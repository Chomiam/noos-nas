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
    extraGroups = u.extraGroups ++ [ "storage" ];
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
    };
  };

  # 🐙 GitHub CLI (gh)
  programs.gh.enable = true;

  # 🔑 Droits d'accès et modification pour l'utilisateur sur /etc/nixos et son répertoire personnel
  system.activationScripts.etcNixosPermissions = lib.stringAfter [ "users" "groups" ] ''
    if [ -d /etc/nixos ]; then
      chown -R ${u.username}:users /etc/nixos
      chmod -R u+rwX,g+rwX /etc/nixos
    fi
    if [ -d "/home/${u.username}" ]; then
      chown ${u.username}:users "/home/${u.username}"
      chmod u+rwx "/home/${u.username}"
    fi
  '';

  # 📁 Règles systemd-tmpfiles pour persister les permissions utilisateur sur /etc/nixos
  systemd.tmpfiles.rules = [
    "d /etc/nixos 0775 ${u.username} users - -"
    "Z /etc/nixos 0775 ${u.username} users - -"
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
    curl
    wget
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
  ];
}
