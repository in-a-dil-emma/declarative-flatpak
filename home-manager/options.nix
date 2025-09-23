{ config, lib, ... }@args:
let
  inherit (lib) mkOption;
  inherit (lib.types) bool;
in
{
  options.services.flatpak.enable = mkOption {
    type = bool;
    default = args.nixosConfig.services.flatpak.enable or false;
  };
  config.services.flatpak.internal.targetDir = "${config.xdg.dataHome}/flatpak";
}
