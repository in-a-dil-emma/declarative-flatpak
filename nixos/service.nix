{ config, lib, ... }:

let
  inherit (lib) mkIf pipe recursiveUpdate;
  cfg = config.services.flatpak;
  applyUnitOrdering =
    prev:
    recursiveUpdate {
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
  applySharedServiceConfig =
    prev:
    recursiveUpdate {
      unitConfig = {
        ConditionPathIsReadWrite = [ cfg.internal.targetDir ];
        RequiresMountsFor = [ cfg.internal.targetDir ];
        Description = "Manage flatpaks";
        StartLimitIntervalSec = 60;
        StartLimitBurst = 3;
      };
      serviceConfig = {
        SyslogIdentifier = "manage-flatpaks";
        ExecPaths = [
          "/nix/store"
          cfg.internal.targetDir
        ];
        ReadWritePaths = [ cfg.internal.targetDir ];
        ProtectSystem = "strict";
        Restart = "on-failure";
        NoExecPaths = [ "/" ];
        ProtectHome = true;
        PrivateTmp = true;
      };
    } prev;
in

{
  config.systemd = {
    tmpfiles.rules = [
      "d ${cfg.internal.targetDir}"
    ];
    services."manage-flatpaks-activation" =
      pipe
        {
          unitConfig = {
            Before = "manage-flatpaks-auto.service";
          };
          serviceConfig.ExecStart = config.services.flatpak.internal.mainScript.activation;
        }
        [
          applyUnitOrdering
          applySharedServiceConfig
          (mkIf cfg.enable)
        ];
    services."manage-flatpaks-auto" =
      pipe
        {
          unitConfig = {
            After = "manage-flatpaks-activation.service";
          };
          serviceConfig.ExecStart = config.services.flatpak.internal.mainScript.auto;
        }
        [
          applySharedServiceConfig
          (mkIf cfg.enable)
        ];
    timers."manage-flatpaks-auto" =
      pipe
        {
          timerConfig = {
            OnCalendar = cfg.onCalendar;
            Persistent = true;
          };
        }
        [
          applyUnitOrdering
          (mkIf cfg.enable)
        ];
  };
}
