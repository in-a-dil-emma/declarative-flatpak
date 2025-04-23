# Flakes

```nix
{
  inputs = {
    # ... other imports ...
    flatpaks.url = "github:in-a-dil-emma/declarative-flatpak/stable-v3";
    # ... other imports ...
  };

  outputs = { ..., flatpaks, ... }: {
    # <host> is a placeholder for your hostname
    nixosConfigurations.<host> = nixpkgs.lib.nixosSystem {
      modules = [
        # ... other modules ...
        flatpaks.nixosModules.declarative-flatpak
        # ... other modules ...
      ];
    };
  };
}
```

# npins

`npins add github in-a-dil-emma declarative-flatpaks -b stable-v3`

```
let
  inputs = import ./npins;
in {
  imports = [
    (inputs.declarative-flatpaks + "/src/modules/nixos.nix")
  ];
}
```
