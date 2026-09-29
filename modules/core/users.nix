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

  # Paquets de base pour l'administration en ligne de commande
  environment.systemPackages = with pkgs; [
    git
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
