{ ... }:

{
  imports = [
    ./kernel.nix
    ./nix.nix
    ./users.nix
    ./security.nix
    ./firewall.nix
  ];
}
