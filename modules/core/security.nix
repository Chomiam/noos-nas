{ config, lib, pkgs, ... }:

let
  f2b = config.steveos.services.fail2ban;
  u = config.steveos.user;
in
{
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
    extraRules = [
      {
        users = [ u.username ];
        commands = [
          {
            command = "/run/current-system/sw/bin/nixos-rebuild";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/nh";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
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
