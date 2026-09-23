{
  lib,
  ...
}:
let
  inherit (lib) mkOption;
  inherit (lib.types) bool;
in
{
  options.services.flatpak.delayStartup = mkOption {
    type = bool;
    default = false;
    description = ''
      Delay startup of the system until the first activation completes.
      This feature could be useful if you want your flatpak packages to be available before login.
    '';
  };
  config.services.flatpak.internal.targetDir = "/var/lib/flatpak";
}
