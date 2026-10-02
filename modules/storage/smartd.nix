{ config, lib, pkgs, ... }:

let
  cfg = config.noos.storage.smartd;
in
{
  config = lib.mkIf cfg.enable {
    services.smartd = {
      enable = true;
      autodetect = true;
      notifications.mail.enable = false;
    };
  };
}
