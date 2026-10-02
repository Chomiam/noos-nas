{
  description = "Noos NAS Edition - Configuration NixOS modulaire pour serveur de stockage & transcodage multimédia";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    steveos-nas-dashboard = {
      url = "github:Chomiam/noos-nas-dashboard";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      # Fusion récursive des variables (defaults + repo vars + local vars prioritaires)
      defaults = import ./vars-defaults.nix;
      repoVars = if builtins.pathExists ./vars.nix then import ./vars.nix else {};
      localVars = if builtins.pathExists ./vars.local.nix then import ./vars.local.nix else {};

      recursiveMerge = base: override:
        builtins.mapAttrs (name: baseValue:
          if override ? ${name} then
            if builtins.isAttrs baseValue && builtins.isAttrs override.${name}
            then recursiveMerge baseValue override.${name}
            else override.${name}
          else baseValue
        ) base // (builtins.removeAttrs override (builtins.attrNames base));

      userVars = recursiveMerge repoVars localVars;
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
            inputs.steveos-nas-dashboard.nixosModules.default
            ./hosts/nas/configuration.nix
          ];
        };

      nasSystem = mkNasSystem {};
    in
    {
      nixosConfigurations = {
        ${baseVars.hostName} = nasSystem;
        nas = nasSystem;
        nixnas = nasSystem;
        default = nasSystem;
      } // (if baseVars.hostName != "noos-nas" then { noos-nas = nasSystem; } else {})
        // (if baseVars.hostName != "steveos-nas" then { steveos-nas = nasSystem; } else {});

      # Module exportable pour réutilisation
      nixosModules.default = ./modules;

      # Outil CLI d'administration en Rust
      packages.x86_64-linux = let
        pkgs = import nixpkgs { system = "x86_64-linux"; };
        noosCli = pkgs.rustPlatform.buildRustPackage {
          pname = "noos-cli";
          version = "0.1.0";
          src = ./tools/steveos-cli;
          cargoLock = {
            lockFile = ./tools/steveos-cli/Cargo.lock;
          };
          postInstall = ''
            ln -s $out/bin/noos-cli $out/bin/steveos-cli
          '';
        };
      in {
        noos-cli = noosCli;
        steveos-cli = noosCli;
        default = noosCli;
      };

      apps.x86_64-linux = {
        noos-cli = {
          type = "app";
          program = "${self.packages.x86_64-linux.noos-cli}/bin/noos-cli";
        };
        steveos-cli = {
          type = "app";
          program = "${self.packages.x86_64-linux.steveos-cli}/bin/steveos-cli";
        };
        default = self.apps.x86_64-linux.noos-cli;
      };
    };
}
