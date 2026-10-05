{
  config,
  pkgs,
  lib,
  ...
}:

let
  ini-types = callPackage ../lib/types/ini.nix { };

  inherit (lib) mkOption mapAttrs pipe;
  inherit (pkgs) callPackage;
  inherit (ini-types) ini;

  cfg = config.services.flatpak;
  fallback = x: y: if x == null then y else x;
in
{
  options.services.flatpak.internal = {
    overrideFiles = mkOption {
      default = pipe config.services.flatpak.overrides [
        (mapAttrs (name: ini.generate "flatpak-override-${name}"))
      ];
    };
    targetDir = mkOption {
      apply = fallback cfg.flatpakDir;
    };
    mainScript = {
      activation = mkOption { };
      auto = mkOption { };
    };
  };
}
