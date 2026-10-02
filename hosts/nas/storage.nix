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

  # Structure déclarative des dossiers partagés du NAS : appartiennent à l'utilisateur et au groupe 'storage' (setgid 2775)
  systemd.tmpfiles.rules = let
    u = config.noos.user.username;
  in [
    "d /mnt 2775 ${u} storage -"
    "z /mnt 2775 ${u} storage -"
    "d /mnt/storage 2775 ${u} storage -"
    "z /mnt/storage 2775 ${u} storage -"
  ];

  # Service de garantie déclarative des permissions sur tous les montages sous /mnt
  systemd.services.ensure-mnt-permissions = {
    description = "Garantie déclarative de la propriété utilisateur sur les volumes et montages /mnt";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" "remote-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "ensure-mnt-permissions" ''
        USER="${config.noos.user.username}"
        if ! id "$USER" >/dev/null 2>&1; then
          USER=$(awk -F: '$3 >= 1000 && $3 < 60000 && $1 != "nobody" {print $1; exit}' /etc/passwd 2>/dev/null || echo "root")
        fi
        GRP="storage"
        if ! getent group "$GRP" >/dev/null 2>&1; then
          GRP="users"
        fi
        if [ -d /mnt ]; then
          chown "$USER:$GRP" /mnt 2>/dev/null || true
          chmod 2775 /mnt 2>/dev/null || true
          for mount_dir in /mnt/*; do
            if [ -d "$mount_dir" ]; then
              chown "$USER:$GRP" "$mount_dir" 2>/dev/null || true
              chmod 2775 "$mount_dir" 2>/dev/null || true
            fi
          done
        fi
      '';
    };
  };

  # Import automatique du fichier local s'il existe (non suivi par Git)
  imports = lib.optional (builtins.pathExists ./storage.local.nix) ./storage.local.nix;

  # Montage dynamique des volumes déclarés dans vars.nix (noos.storage.disks)
  fileSystems = lib.listToAttrs (map (disk: {
    name = disk.mountPoint;
    value = {
      device = disk.device;
      fsType = disk.fsType;
      options = disk.options;
    };
  }) (config.noos.storage.disks or []));
}
