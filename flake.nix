{
  outputs = { self }: {
    nixosModule = ./nixos;
    homeModule = ./home-manager;

    nixosModules.declarative-flatpak = builtins.trace "declarative-flatpak: this output (nixosModules.declarative-flatpak) will be removed soon, please use output nixosModule" self.nixosModule;
    homeManagerModules.declarative-flatpak = builtins.trace "declarative-flatpak: this output (homeManagerModules.declarative-flatpak) will be removed soon, please use output homeModule" self.homeModule;
  };
}
