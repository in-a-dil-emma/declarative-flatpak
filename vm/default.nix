let
  inputs = import ../npins;
  pkgs = import inputs.nixpkgs {};
  lib = import (inputs.nixpkgs + "/lib");
  inherit (pkgs) mkShellNoCC nixos;
  inherit (lib) getExe;

  vm = nixos [
    ({ modulesPath, ... }: { imports = [ (modulesPath + "/virtualisation/qemu-vm.nix") ]; })
    (inputs.home-manager + "/nixos")
    ../nixos
    ./configuration.nix
    ./home-manager.nix
  ];
in mkShellNoCC {
  name = "vm";
  shellHook = "exec ${getExe vm.config.system.build.vm}";
}

