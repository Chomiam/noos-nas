{ ... }:

{
  imports = [
    ./openssh.nix
    ./samba.nix
    ./nfs.nix
    ./containers.nix
    ./vpn.nix
    ./virtualisation.nix
    ./nix-ld.nix
  ];
}

