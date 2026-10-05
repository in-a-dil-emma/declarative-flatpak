{ config, pkgs, lib, ... }: {
  imports = [
    ../nixos
  ];

  environment.variables.FLATPAK_SYSTEM_DIR = config.services.flatpak.internal.flatpakDir;

  systemd = {
    services."manage-flatpaks-activation".onSuccess = [ "complete.target" ];
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