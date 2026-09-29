{ config, pkgs, ... }:

{
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      trusted-users = [ "root" "@wheel" ];
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  nixpkgs.config.allowUnfree = true;

  time.timeZone = config.steveos.timeZone;
  i18n.defaultLocale = config.steveos.defaultLocale;
  console.keyMap = config.steveos.keyboard.keyMap;
  networking.hostName = config.steveos.hostName;
  system.stateVersion = config.steveos.stateVersion;
}
