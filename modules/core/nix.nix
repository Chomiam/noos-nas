{ config, pkgs, lib, ... }:

{
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      trusted-users = [ "root" "@wheel" ];
      substituters = [
        "https://cache.nixos.org"
        "https://steveos.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "steveos.cachix.org-1:l9qrMv98fMgo8oXRMrzcktVXMjM7cuK3lFz7fipvqgc="
      ];
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
  networking.useDHCP = lib.mkDefault true;
  system.stateVersion = config.steveos.stateVersion;
}
