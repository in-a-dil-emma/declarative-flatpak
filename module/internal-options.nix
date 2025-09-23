{ config, lib, ... }:

let
  inherit (lib) mkOption;

  cfg = config.services.flatpak;
  fallback = x: y: if x == null then y else x;
in
{
  options.services.flatpak.internal = {
    targetDir = mkOption {
      internal = true;
      apply = fallback cfg.flatpakDir;
    };
    mainScript = {
      activation = mkOption {
        internal = true;
      };
      auto = mkOption {
        internal = true;
      };
    };
  };
}
