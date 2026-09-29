{ config, lib, pkgs, ... }:

let
  f2b = config.steveos.services.fail2ban;
in
{
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
  };

  services.fail2ban = lib.mkIf f2b.enable {
    enable = true;
    maxretry = f2b.maxretry;
    bantime = f2b.bantime;
    jails = {
      sshd = {
        settings = {
          mode = "aggressive";
          port = "ssh,22";
        };
      };
    };
  };
}
