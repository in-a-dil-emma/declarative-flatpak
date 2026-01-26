{
  outputs =
    { self }:
    {
      nixosModules = {
        default = self.nixosModules.declarative-flatpak;
        declarative-flatpak = ./nixos;
      };
      homeModules = {
        default = self.homeModules.declarative-flatpak;
        declarative-flatpak = ./home-manager;
      };
    };
}
