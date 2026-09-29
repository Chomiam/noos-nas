{ config, lib, pkgs, ... }:

let
  cfg = config.steveos.services.cockpit;
in
{
  config = lib.mkIf cfg.enable {
    services.cockpit = {
      enable = true;
      port = cfg.port;
      settings = {
        WebService = {
          AllowUnencrypted = true;
        };
      };
    };

    # Pare-feu modulaire Cockpit WebUI
    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
