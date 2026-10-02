{ config, lib, pkgs, ... }:

let
  cfg = config.noos.services.nfs;
in
{
  config = lib.mkIf cfg.enable {
    services.nfs.server = {
      enable = true;
      exports = ''
        ${cfg.sharesPath} 192.168.0.0/16(rw,sync,no_subtree_check,no_root_squash)
      '';
    };

    # Pare-feu modulaire NFS
    networking.firewall = {
      allowedTCPPorts = [ 2049 111 ];
      allowedUDPPorts = [ 2049 111 ];
    };
  };
}
