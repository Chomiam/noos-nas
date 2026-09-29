{ config, pkgs, ... }:

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
  ];
}
