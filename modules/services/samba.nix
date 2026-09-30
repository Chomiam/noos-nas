{ config, lib, pkgs, ... }:

let
  cfg = config.steveos.services.samba;
in
{
  config = lib.mkIf cfg.enable {
    services.samba = {
      enable = true;
      openFirewall = false; # Gestion modulaire par nos soins
      settings = {
        global = {
          workgroup = cfg.workgroup;
          "server string" = cfg.serverString;
          "netbios name" = config.steveos.hostName;
          security = "user";
          "hosts allow" = "192.168. 10. 172.16. 172.17. 172.18. 172.19. 172.20. 172.21. 172.22. 172.23. 172.24. 172.25. 172.26. 172.27. 172.28. 172.29. 172.30. 172.31. 127.0.0.1 localhost";
          "hosts deny" = "0.0.0.0/0";
          "guest account" = "nobody";
          "map to guest" = "bad user";
          "load printers" = "no";
          "printing" = "bsd";
          "printcap name" = "/dev/null";
          "disable spoolss" = "yes";
        };
        shares = {
          path = cfg.sharesPath;
          browseable = "yes";
          "read only" = "no";
          "guest ok" = if cfg.guestAccess then "yes" else "no";
          "create mask" = "0664";
          "directory mask" = "0775";
        };
      };
    };

    # Découverte automatique sur le réseau local (Windows Explorer / macOS Finder)
    services.samba-wsdd = lib.mkIf cfg.wsdd {
      enable = true;
      openFirewall = false; # On déclare les ports explicitement ci-dessous
    };

    # Pare-feu modulaire Samba + WSDD
    networking.firewall = {
      allowedTCPPorts = [ 139 445 5357 ];
      allowedUDPPorts = [ 137 138 3702 ];
    };
  };
}
