{ config, lib, ... }:

let
  inherit (lib) mkIf pipe recursiveUpdate;
  cfg = config.services.flatpak;
  applyUnitOrdering = prev: recursiveUpdate {
    Install.WantedBy = [
      "default.target"
    ];
  } prev;
  applyServiceRestart = prev: recursiveUpdate {
    Unit = {
      StartLimitIntervalSec = 60;
      RefuseManualStart = true;
      StartLimitBurst = 3;
    };
    Service = {
      Restart = "on-failure";
    };
  } prev;
in 

{
  config.systemd.user = {
    services."manage-flatpaks-activation" = pipe {
      Unit = rec {
        Conflicts = "manage-flatpaks-auto.service";
        Description = "Manage flatpaks";
        Before = Conflicts;
      };
      Service.ExecStart = config.services.flatpak.mainScript.activation;
    } [ applyUnitOrdering applyServiceRestart (mkIf cfg.enable) ];
    services."manage-flatpaks-auto" = pipe {
      Unit = rec {
        Conflicts = "manage-flatpaks-activation.service";
        Description = "Manage flatpaks";
        After = Conflicts;
      };
      Service.ExecStart = config.services.flatpak.mainScript.auto;
    } [ applyServiceRestart (mkIf cfg.enable) ];
    timers."manage-flatpaks-auto" = pipe {
      Timer = {
        OnCalendar = cfg.onCalendar;
        Persistent = true;
      };
    } [ applyUnitOrdering (mkIf cfg.enable) ];
  };
}
