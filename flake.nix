{
  outputs = { self }: {
    nixosModules = {
      declarative-flatpak = ./src/modules/nixos.nix;
    };
    homeManagerModules = {
      declarative-flatpak = ./src/modules/home-manager.nix;
    };
  };
}
