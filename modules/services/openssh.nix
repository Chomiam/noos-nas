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
      extraConfig = ''
        # Inclusion des partages et règles sFTP dynamiques gérés par STEvE_OS
        Include /var/lib/steveos/sftp_shares.conf
      '';
    };

    # Règles tmpfiles pour initialiser les fichiers de configuration sFTP persistants
    systemd.tmpfiles.rules = [
      "d /var/lib/steveos 0755 root root -"
      "f /var/lib/steveos/sftp_shares.conf 0644 root root -"
      "f /var/lib/steveos/sftp_shares.json 0644 root root -"
      "d /mnt/storage/sftp 0755 root root -"
    ];

    # Pare-feu modulaire : ouverture automatique du port SSH / sFTP
    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
