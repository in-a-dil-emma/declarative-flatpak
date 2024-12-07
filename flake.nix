{
  description = "Declarative flatpaks.";

  inputs = {
    systems.url = "github:nix-systems/default-linux";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
  };

  outputs = { self, nixpkgs, systems, home-manager }@inputs: let
    inherit (nixpkgs.lib) genAttrs warn;
    genSystems = f: genAttrs (import systems) (system: f nixpkgs.legacyPackages.${system});
  in {
    devShells = genSystems (pkgs: {
      default = pkgs.callPackage ./shell.nix { inherit inputs; };
    });
    nixosModules = rec {
      declarative-flatpak.imports = [ ./src/modules/nixos.nix ];
      default = warn "\"default\" flake output should no longer be used, please use the \"declarative-flatpak\" output" declarative-flatpak;
    };
    homeManagerModules = rec {
      declarative-flatpak.imports = [ ./src/modules/home-manager.nix ];
      default = warn "\"default\" flake output should no longer be used, please use the \"declarative-flatpak\" output" declarative-flatpak;
    };

    checks = genSystems ({ callPackage, ... }: {
      nixos = callPackage ./tests/nixos.nix { modules.flatpak = self.nixosModules.declarative-flatpak; };
      # home-manager = callPackage ./tests/home-manager.nix { modules = { flatpak = self.homeManagerModules.declarative-flatpak; home-manager = home-manager.nixosModules.home-manager; }; };
    });
    nixosConfigurations.shell = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        { nixpkgs.config.allowUnfree = true; }

        self.nixosModules.declarative-flatpak
        home-manager.nixosModules.home-manager
        (nixpkgs + "/nixos/modules/virtualisation/qemu-vm.nix")

        ./vm/configuration.nix
        ./vm/home-manager.nix
      ];
      specialArgs = {
        flatpak = self;
      };
    };
  };
}