{
  outputs =
    { self }:
    {
      nixosModule = builtins.warn "declarative-flatpak: flake output `nixosModule` has been renamed to `nixosModules.default`" ./nixos;
      homeModule = builtins.warn "declarative-flatpak: flake output `homeModule` has been renamed to `homeModules.default`" ./home-manager;
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
