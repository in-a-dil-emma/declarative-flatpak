{
  description = "Declarative flatpaks.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    systems.url = "github:nix-systems/default-linux";
  };

  outputs = { self, nixpkgs, systems }@inputs: let
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
  };
}