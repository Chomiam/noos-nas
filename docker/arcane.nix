{ config, lib, pkgs, ... }:

let
  user = config.noos.user.username;
  dataDir = "/home/${user}/docker/arcane";
in
{
  # 1. Création déclarative du répertoire persistant dans /home/<user>/docker/arcane
  systemd.tmpfiles.rules = [
    "d /home/${user}/docker 0775 ${user} users -"
    "d ${dataDir} 0775 ${user} users -"
    "d ${dataDir}/data 0775 ${user} users -"
  ];

  # 2. Déclaration du conteneur OCI Arcane (géré par le démon Docker)
  virtualisation.oci-containers.backend = "docker";
  virtualisation.oci-containers.containers.arcane = {
    image = "ghcr.io/getarcaneapp/arcane:latest";
    autoStart = true;
    ports = [ "3552:3552" ];
    volumes = [
      "/var/run/docker.sock:/var/run/docker.sock"
      "${dataDir}/data:/app/data"
    ];
    environment = {
      PORT = "3552";
      PUID = "1000";
      PGID = "100";
      ENCRYPTION_KEY = "0c8f24b63e073f21f04431b2bd81f6f65bbf5b2571ccaf9eda3dc5eab3486f85";
    };
  };

  # 3. Maintien strict des permissions sur le dossier de données persistant
  systemd.services.docker-arcane.preStart = lib.mkAfter ''
    chown -R ${user}:users ${dataDir}
    chmod -R u+rwX,g+rwX ${dataDir}
  '';

  # 4. Ouverture du port 3552 dans le pare-feu NixOS
  networking.firewall.allowedTCPPorts = [ 3552 ];
}
