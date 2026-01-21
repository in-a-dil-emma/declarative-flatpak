{ config, lib, ... }:

let
  inherit (lib) mkIf pipe recursiveUpdate;
  cfg = config.services.flatpak;
  applyUnitOrdering =
    prev:
    recursiveUpdate {
      Install.WantedBy = [
        "default.target"
      ];
    } prev;
  applySharedServiceConfig =
    prev:
    recursiveUpdate {
      Unit = {
        ConditionPathIsReadWrite = [ cfg.internal.targetDir ];
        RequiresMountsFor = [ cfg.internal.targetDir ];
        Description = "Manage flatpaks";
        StartLimitIntervalSec = 60;
        StartLimitBurst = 3;
      };
      Service = {
        ExecPaths = [
          "%t"
          "/nix/store"
          cfg.internal.targetDir
        ];
        ReadWritePaths = [
          cfg.internal.targetDir
          "%t"
        ];
        ProtectHome = "read-only";
        ProtectSystem = "strict";
        Restart = "on-failure";
        NoExecPaths = [ "/" ];
        PrivateTmp = true;
      };
    } prev;
in

{
  config.systemd.user = {
    tmpfiles.rules = [
      "d ${cfg.internal.targetDir} 750 - - - -"
    ];
    services."manage-flatpaks-activation" =
      pipe
        {
          Unit = {
            Before = "manage-flatpaks-auto.service";
          };
          Service.ExecStart = config.services.flatpak.internal.mainScript.activation;
        }
        [
          applyUnitOrdering
          applySharedServiceConfig
          (mkIf cfg.enable)
        ];
    services."manage-flatpaks-auto" =
      pipe
        {
          Unit = {
            After = "manage-flatpaks-activation.service";
          };
          Service.ExecStart = config.services.flatpak.internal.mainScript.auto;
        }
        [
          applySharedServiceConfig
          (mkIf cfg.enable)
        ];
    timers."manage-flatpaks-auto" =
      pipe
        {
          Timer = {
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
