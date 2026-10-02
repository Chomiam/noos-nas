{ config, lib, pkgs, ... }:

let
  mountsJsonPath = ../../mounts.json;
  customMounts = if builtins.pathExists mountsJsonPath
    then (builtins.fromJSON (builtins.readFile mountsJsonPath))
    else [];
  activeMounts = builtins.filter (m: m.enabled or true) customMounts;
  user = config.noos.user.username;
  # Points de montage déjà déclarés dans vars.nix pour éviter les doublons
  varsMountPoints = map (d: d.mountPoint) (config.noos.storage.disks or []);
  filteredJsonMounts = builtins.filter (m: !(builtins.elem m.mountPoint varsMountPoints)) activeMounts;
in
{
  # 1. Déclaration automatique des systèmes de fichiers durables (priorité absolue au chemin UUID persistant)
  fileSystems = lib.listToAttrs (map (m: {
    name = m.mountPoint;
    value = {
      device = if (m ? deviceUuid && m.deviceUuid != null && m.deviceUuid != "")
               then "/dev/disk/by-uuid/${m.deviceUuid}"
               else m.device;
      fsType = m.fsType or "auto";
      options = if (m ? options && m.options != [] && m.options != null)
                then m.options
                else [ "defaults" "noatime" "nofail" ];
    };
  }) filteredJsonMounts);

  # 2. Garantie déclarative de création du dossier et attribution setgid 2775
  systemd.tmpfiles.rules = map (m: 
    "d ${m.mountPoint} 2775 ${user} storage -"
  ) filteredJsonMounts;
}
