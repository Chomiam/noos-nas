{ config, lib, pkgs, ... }:

let
  cfg = config.steveos.services.openssh;
  sftpCfg = config.steveos.services.sftp;
in
{
  config = lib.mkIf (cfg.enable || sftpCfg.enable) {
    services.openssh = {
      enable = true;
      ports = [ cfg.port ];
      settings = {
        PermitRootLogin = cfg.permitRootLogin;
        PasswordAuthentication = true; # Permet mot de passe ou clés
        KbdInteractiveAuthentication = true;
        Subsystem = "sftp internal-sftp";
      };
    };

    # Pare-feu modulaire : ouverture automatique du port SSH / sFTP
    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
