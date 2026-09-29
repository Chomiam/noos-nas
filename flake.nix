{
  description = "STEvE_OS NAS Edition - Configuration NixOS modulaire pour serveur de stockage & transcodage multimédia";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      # Fusion récursive des variables (defaults + user overrides)
      defaults = import ./vars-defaults.nix;
      userVars = import ./vars.nix;

      recursiveMerge = base: override:
        builtins.mapAttrs (name: baseValue:
          if override ? ${name} then
            if builtins.isAttrs baseValue && builtins.isAttrs override.${name}
            then recursiveMerge baseValue override.${name}
            else override.${name}
          else baseValue
        ) base // (builtins.removeAttrs override (builtins.attrNames base));

      baseVars = recursiveMerge defaults userVars;

      # Constructeur de système modulaire
      mkNasSystem = customVars:
        let
          vars = recursiveMerge baseVars customVars;
        in
        nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs vars; };
          modules = [
            { nixpkgs.hostPlatform = "x86_64-linux"; }
            ./hosts/nas/configuration.nix
          ];
        };

      nasSystem = mkNasSystem {};
    in
    {
      nixosConfigurations = {
        ${baseVars.hostName} = nasSystem;
        nas = nasSystem;
        default = nasSystem;
      };

      # Module exportable pour réutilisation
      nixosModules.default = ./modules;

      # Outil CLI d'administration en Rust
      packages.x86_64-linux = let
        pkgs = import nixpkgs { system = "x86_64-linux"; };
      in {
        steveos-cli = pkgs.rustPlatform.buildRustPackage {
          pname = "steveos-cli";
          version = "0.1.0";
          src = ./tools/steveos-cli;
          cargoLock = {
            lockFile = ./tools/steveos-cli/Cargo.lock;
          };
        };
        default = self.packages.x86_64-linux.steveos-cli;
      };

      apps.x86_64-linux.default = {
        type = "app";
        program = "${self.packages.x86_64-linux.steveos-cli}/bin/steveos-cli";
      };
    };
}
