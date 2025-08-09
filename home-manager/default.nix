{ config, lib, pkgs, ... }:

let
  inherit (pkgs) systemd;
  inherit (lib) mkIf makeBinPath;
  
  cfg = config.services.flatpak;
in 

{
  imports = [
    ../module
    ./options.nix
    ./service.nix
  ];

  # is this necessary too?
  config.xdg.enable = true;
}
