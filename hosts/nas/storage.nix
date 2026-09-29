{ config, lib, pkgs, ... }:

{
  # =========================================================================
  # 💾 POINTS DE MONTAGE & VOLUMES DE STOCKAGE DU NAS
  # Adaptez les UUIDs selon les disques installés sur votre NAS.
  # =========================================================================

  # Exemple de création du répertoire de partages principal
  systemd.tmpfiles.rules = [
    "d /mnt/storage 0775 root storage -"
    "d /mnt/storage/shares 0775 root storage -"
    "d /mnt/storage/media 0775 root storage -"
    "d /mnt/storage/sftp 0775 root storage -"
  ];

  # Activation automatique du RAID logiciel (mdadm) et de la détection LVM2
  boot.swraid.enable = lib.mkDefault true;
  environment.etc."mdadm.conf".text = "MAILADDR root";

  # Montage persistant automatique de la grappe de stockage
  fileSystems."/mnt/storage" = {
    device = "/dev/disk/by-label/STORAGE";
    fsType = "btrfs";
    options = [ "defaults" "compress=zstd" "noatime" "nofail" ];
  };
}
