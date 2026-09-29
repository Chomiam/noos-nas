{ ... }:

{
  imports = [
    ./openssh.nix
    ./samba.nix
    ./nfs.nix
    ./jellyfin.nix
    ./containers.nix
    ./cockpit.nix
    ./vpn.nix
  ];
}
