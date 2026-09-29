{ config, lib, pkgs, ... }:

let
  cfg = config.steveos.services.jellyfin;
in
{
  config = lib.mkIf cfg.enable {
    services.jellyfin = {
      enable = true;
      openFirewall = false; # Géré via notre pare-feu modulaire
      user = "jellyfin";
      group = "jellyfin";
    };

    # Donne accès au transcodage GPU (/dev/dri) à l'utilisateur jellyfin
    users.users.jellyfin.extraGroups = [ "video" "render" "storage" ];

    # Pare-feu modulaire Jellyfin
    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [ 8096 8920 ];
      allowedUDPPorts = [ 1900 7359 ]; # Découverte automatique DLNA / clients
    };
  };
}
