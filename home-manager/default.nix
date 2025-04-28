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

  # is this really necessary?
  config.home.activation = mkIf cfg.enable {
    start-service = lib.hm.dag.entryAfter ["writeBoundary"] ''
      export PATH=${makeBinPath ([ systemd ])}:$PATH

      $DRY_RUN_CMD systemctl is-system-running -q && \
        systemctl --user daemon-reload || true
      $DRY_RUN_CMD systemctl is-system-running -q && \
        systemctl --user enable --now manage-user-flatpaks || true
    '';
  };

  # is this necessary too?
  config.xdg.enable = true;
}
