{
  # =========================================================================
  # ⚙️ VARIABLES UTILISATEUR : STEvE_OS NAS EDITION
  # Modifiez ce fichier pour adapter le NAS à votre matériel et vos besoins.
  # Les valeurs non spécifiées ici hériteront de vars-defaults.nix.
  # =========================================================================

  hostName = "steveos-nas";

  # Choix du GPU pour le transcodage matériel ("intel", "amd", "nvidia", "headless")
  gpuDriver = "intel";
  enableHardwareCodecs = true;

  # Sécurité et pare-feu
  firewall = {
    enable = true;
    strictLanOnly = false;
  };

  # Services activés
  services = {
    samba = {
      enable = true;
      sharesPath = "/mnt/storage/shares";
    };
    sftp = {
      enable = true;
      port = 22;
    };
    jellyfin = {
      enable = true;
    };
    docker = {
      enable = true;
    };
    cockpit = {
      enable = true;
    };
  };
}
