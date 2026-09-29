{ config, lib, pkgs, ... }:

{
  # =========================================================================
  # 💾 MODULE DE STOCKAGE DU NAS (SOCLE PARTAGÉ)
  # Ce fichier fait partie du socle STEvE_OS partagé et est synchronisé via Git.
  #
  # ⚠️ NE PAS DÉCLARER DE DISQUES EN DUR DANS CE FICHIER :
  # Afin que les mises à jour (git pull) n'écrasent pas vos points de montage
  # et pour supporter tous les systèmes de fichiers (Btrfs, Ext4, XFS, ZFS...),
  # configurez vos disques selon l'une des méthodes suivantes :
  #
  # Méthode 1 (Recommandée - Déclaratif dans vars.nix) :
  #   Renseignez `storage.disks = [ { device = "..."; mountPoint = "..."; fsType = "..."; } ];`
  #
  # Méthode 2 (Avancée - Fichier local dédié ignoré par Git) :
  #   Créez `hosts/nas/storage.local.nix` (voir le modèle `storage.local.nix.example`).
  #   Ce fichier est listé dans .gitignore et n'est JAMAIS écrasé par les mises à jour.
  # =========================================================================

  # Support étendu de tous les systèmes de fichiers dans le noyau et l'initrd
  boot.supportedFilesystems = lib.mkDefault [ "btrfs" "ext4" "xfs" "ntfs" "vfat" ];

  # Activation automatique du RAID logiciel (mdadm) et de la détection LVM2
  boot.swraid.enable = lib.mkDefault true;
  environment.etc."mdadm.conf".text = "MAILADDR root";

  # Structure des dossiers partagés du NAS avec permissions de groupe 'storage' (setgid 2775)
  systemd.tmpfiles.rules = [
    "d /mnt/storage 2775 root storage -"
    "d /mnt/storage/shares 2775 root storage -"
    "d /mnt/storage/media 2775 root storage -"
    "d /mnt/storage/sftp 2775 root storage -"
  ];

  # Import automatique du fichier local s'il existe (non suivi par Git)
  imports = lib.optional (builtins.pathExists ./storage.local.nix) ./storage.local.nix;

  # Montage dynamique des volumes déclarés dans vars.nix (steveos.storage.disks)
  fileSystems = lib.listToAttrs (map (disk: {
    name = disk.mountPoint;
    value = {
      device = disk.device;
      fsType = disk.fsType;
      options = disk.options;
    };
  }) (config.steveos.storage.disks or []));
}
