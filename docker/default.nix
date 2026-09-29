{ config, lib, pkgs, ... }:

let
  # Scan automatique de tous les modules .nix présents dans le dossier docker/ (sauf default.nix)
  files = builtins.attrNames (builtins.readDir ./.);
  nixFiles = builtins.filter (f: f != "default.nix" && lib.hasSuffix ".nix" f) files;
in
{
  imports = map (f: ./. + "/${f}") nixFiles;
}
