{ config, lib, ... }:

let
  inherit (lib) mkIf pipe recursiveUpdate;
  cfg = config.services.flatpak;
  applyUnitOrdering = prev: recursiveUpdate {
    unitConfig = rec {
      Wants = After;
      After = [
        "network-online.target"
        "nss-lookup.target"
      ];
    };
    wantedBy = [
      "multi-user.target"
    ];
  } prev;
  applyServiceRestart = prev: recursiveUpdate {
    unitConfig = {
      StartLimitIntervalSec = 60;
      RefuseManualStart = true;
      StartLimitBurst = 3;
    };
    serviceConfig = {
      Restart = "on-failure";
    };
  } prev;
  # unsure if this causes issues
  # applyServiceSandboxing = prev: recursiveUpdate {
  #   serviceConfig = {
  #     RequiresMountsFor = [ cfg.flatpakDir ];
  #     ReadWritePaths = [ cfg.flatpakDir ];
  #     ProtectSystem = "strict";
  #     PrivateDevices = true;
  #     ProtectHome = true;
  #     PrivateTmp = true;
  #   };
  # } prev;
in

{
  config.systemd = {
    services."manage-flatpaks-activation" = pipe {
      unitConfig = rec {
        Conflicts = "manage-flatpaks-auto.service";
        Description = "Manage flatpaks";
        Before = Conflicts;
      };
      serviceConfig.ExecStart = config.services.flatpak.mainScript.activation;
    } [ applyUnitOrdering applyServiceRestart (mkIf cfg.enable) ];
    services."manage-flatpaks-auto" = pipe {
      unitConfig = rec {
        Conflicts = "manage-flatpaks-activation.service";
        Description = "Manage flatpaks";
        After = Conflicts;
      };
      serviceConfig.ExecStart = config.services.flatpak.mainScript.auto;
    } [ applyServiceRestart (mkIf cfg.enable) ];
    timers."manage-flatpaks-auto" = pipe {
      timerConfig = {
        OnCalendar = cfg.onCalendar;
        Persistent = true;
      };
    } [ applyUnitOrdering (mkIf cfg.enable) ];
  };
}
