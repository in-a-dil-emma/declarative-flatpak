{ config, pkgs, lib, ... }: {
  imports = [
    ../nixos
  ];

  environment.variables.FLATPAK_SYSTEM_DIR = config.services.flatpak.internal.targetDir;

  systemd = {
    services."manage-flatpaks-activation" = {
      # Do not allow the activation script to recover from errors by default
      serviceConfig.Restart = lib.mkImageMediaOverride "no";
      # Make service failure stop the test immediately
      unitConfig.FailureAction = "poweroff-force";
      onSuccess = [ "complete.target" ];
    };
    targets."complete".enable = true;
  };

  services.flatpak = {
    flatpakDir = lib.mkDefault "/target";
    runWithoutGui = lib.mkDefault true;
    delayStartup = lib.mkDefault false;
    veryVerbose = true;
    enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal
    ];
    config.common.default = "*";
  };
}