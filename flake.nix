{
  outputs =
    { self }:
    {
      nixosModule = builtins.warn "declarative-flatpak: flake output `nixosModule` has been renamed to `nixosModules`" ./nixos;
      homeModule = builtins.warn "declarative-flatpak: flake output `homeModule` has been renamed to `homeModules`" ./home-manager;
      nixosModules = {
        default = self.outputs.nixosModules.declarative-flatpak;
        declarative-flatpak = ./nixos;
      };
      homeModules = {
        default = self.outputs.homeModules.declarative-flatpak;
        declarative-flatpak = ./home-manager;
      };
    };
}
