{ config, lib, ... }:

let
  inherit (lib)
    recursiveUpdate
    mkMerge
    mkIf
    ;
  cfg = config.services.flatpak;
  applyServiceConfig =
    prev:
    mkIf cfg.enable (
      recursiveUpdate {
        Unit = rec {
          Wants = [
            # if you have such target in your config
            "network-online.target"
          ];
          After = Wants;
          ConditionPathIsReadWrite = [ cfg.internal.targetDir ];
          RequiresMountsFor = [ cfg.internal.targetDir ];
          Description = "Manage flatpaks";
          StartLimitIntervalSec = 60;
          StartLimitBurst = 3;
        };
        Service = {
          Type = "oneshot";
          SyslogIdentifier = "manage-flatpaks";
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
      } prev
    );
in

{
  config.systemd.user = {
    tmpfiles.rules = mkIf cfg.enable [
      "d ${cfg.internal.targetDir}"
    ];
    services."manage-flatpaks-activation" = applyServiceConfig {
      Service.ExecStart = config.services.flatpak.internal.mainScript.activation;
      Install.WantedBy = mkMerge [
        (mkIf (!cfg.runWithoutGui) [ "graphical-session.target" ])
        (mkIf cfg.runWithoutGui [ "default.target" ])
      ];
    };
    services."manage-flatpaks-auto" = applyServiceConfig {
      Service.ExecStart = config.services.flatpak.internal.mainScript.auto;
      Unit.After = [ "manage-flatpaks-activation.service" ];
      Unit.Requisite = mkIf (!cfg.runWithoutGui) [
        "graphical-session.target"
      ];
    };
    timers."manage-flatpaks-auto" = mkIf cfg.enable {
      Timer = {
        OnCalendar = cfg.onCalendar;
        Persistent = true;
      };
    };
  };
}
