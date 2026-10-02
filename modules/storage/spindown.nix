{ config, lib, pkgs, ... }:

let
  cfg = config.noos.storage.spindown;
  # Calcul du paramètre hdparm -S (multiples de 5 secondes pour 1-240)
  # ex: 20 minutes = 1200s -> 1200 / 5 = 240
  spindownVal = toString (cfg.idleMinutes * 12);
in
{
  config = lib.mkIf cfg.enable {
    # Script systemd au boot pour appliquer le spindown sur les disques mécaniques rotatifs
    systemd.services.disk-spindown = {
      description = "Mise en veille automatique des disques HDD";
      wantedBy = [ "multi-user.target" ];
      after = [ "local-fs.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "apply-spindown" ''
          for disk in /dev/sd[a-z]; do
            if [ -b "$disk" ]; then
              rotational=$(cat /sys/block/$(basename "$disk")/queue/rotational 2>/dev/null || echo 0)
              if [ "$rotational" = "1" ]; then
                echo "Application spindown (${toString cfg.idleMinutes}m) sur $disk"
                ${pkgs.hdparm}/bin/hdparm -S ${spindownVal} -B 127 "$disk" || true
              fi
            fi
          done
        '';
      };
    };
  };
}
