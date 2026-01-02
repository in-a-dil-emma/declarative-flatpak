{
  config,
  lib,
  nixosConfig ? { },
  ...
}:
let
  inherit (lib) mkOption mkIf;
  inherit (lib.types) bool;
in
{
  options.services.flatpak.enable = mkOption {
    type = bool;
    default = nixosConfig.services.flatpak.enable or false;
  };
  config = {
    services.flatpak.internal.targetDir = "${config.xdg.dataHome}/flatpak";
    assertions = mkIf (nixosConfig ? services.flatpak.enable) [
      {
        assertion = config.services.flatpak.enable && nixosConfig.services.flatpak.enable;
        message = ''
          You're using home-manager with NixOS.
          Flatpak is not enabled in your NixOS config.
          This setup is unsupported.

          https://github.com/in-a-dil-emma/declarative-flatpak/issues/57#issuecomment-3705068763
        '';
      }
    ];
  };
}
