{ config, lib, pkgs, ... }:

let
  cfg = config.noos.storage;
in
{
  config = {
    # Maintenance périodique Btrfs (scrub et trim)
    services.btrfs.autoScrub = lib.mkIf cfg.btrfsScrub.enable {
      enable = true;
      interval = cfg.btrfsScrub.interval;
    };

    # Maintenance ZFS (trim et scrub)
    services.zfs = {
      trim.enable = cfg.zfsAutoTrim;
      autoScrub.enable = true;
    };
  };
}
