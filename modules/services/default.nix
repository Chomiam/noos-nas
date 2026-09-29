{ ... }:

{
  imports = [
    ./openssh.nix
    ./samba.nix
    ./nfs.nix
    ./jellyfin.nix
    ./containers.nix
    ./vpn.nix
    ./virtualisation.nix
  ];
}

