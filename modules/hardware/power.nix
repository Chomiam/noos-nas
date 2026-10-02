{ config, lib, pkgs, ... }:

{
  # Optimisation de la consommation énergétique pour serveur 24/7
  powerManagement.cpuFreqGovernor = config.noos.hardware.cpuGovernor;

  # Outils d'analyse de consommation
  environment.systemPackages = with pkgs; [
    powertop
  ];
}
