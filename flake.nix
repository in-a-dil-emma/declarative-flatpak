{
  outputs =
    { self }:
    {
      nixosModule = ./nixos;
      homeModule = ./home-manager;
    };
}
