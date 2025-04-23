```nix
{
  inputs = {
    # ... other imports ...
    flatpaks.url = "github:in-a-dil-emma/declarative-flatpak/stable-v3";
    # ... other imports ...
  };

  outputs = { ..., flatpaks, ... }: {
    # <user> is a placeholder for your username
    homeConfigurations.<user> = home-manager.lib.homeManagerConfiguration {
      modules = [
        # ... other modules ...
        flatpaks.homeManagerModules.declarative-flatpak
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
    (inputs.declarative-flatpaks + "/src/modules/home-manager.nix")
  ];
}
```

> [!CAUTION]
> Do not import the module in your `home.nix` if you experience "infinite recursion" errors
>
> Relevant issue: nix-community/nixvim#83
