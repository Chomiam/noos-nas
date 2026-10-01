{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.steveos.boot;
in
{
  config = {
    boot.kernelPackages = mkDefault (
      if cfg.kernel == "lts" || cfg.kernel == "6_12" then
        pkgs.linuxPackages_6_12
      else if cfg.kernel == "6_6" then
        pkgs.linuxPackages_6_6
      else if cfg.kernel == "latest" then
        pkgs.linuxPackages_latest
      else
        pkgs.linuxPackages
    );
  };
}
