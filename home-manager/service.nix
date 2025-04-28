{ config, lib, ... }:

let
  inherit (lib) mkIf;
  
  cfg = config.services.flatpak;
in 

{
  config.systemd.user = mkIf cfg.enable {
    services."manage-flatpaks" = {
      Unit = {
        Wants = mkIf cfg.runOnActivation [
          "network.target"
        ];
        After = mkIf cfg.runOnActivation [
          "network.target"
        ];
      };
      Install.WantedBy = mkIf cfg.runOnActivation [
        "default.target"
      ];
      Service.ExecStart = config.services.flatpak.mainScript;
    };
    timers = mkIf (cfg.onCalendar != null) {
      "manage-flatpaks" = {
        Unit = {
          Wants = [
            "network.target"
          ];
          After = [
            "network.target"
          ];
        };
        Install.WantedBy = [
          "default.target"
        ];
        Timer = {
          OnCalendar = cfg.onCalendar;
          Persistent = true;
        };
      };
    };
  };
}
