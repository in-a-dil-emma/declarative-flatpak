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
      recursiveUpdate rec {
        unitConfig = {
          ConditionPathIsReadWrite = [ cfg.internal.targetDir ];
          RequiresMountsFor = [ cfg.internal.targetDir ];
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
        description = "Manage flatpaks";
        wants = after;
        after = [
          "network-online.target"
        ];
      } prev
    );
in

{
  config.systemd = {
    tmpfiles.rules = mkIf cfg.enable [
      "d ${cfg.internal.targetDir}"
    ];
    services."manage-flatpaks-activation" = applyServiceConfig {
      serviceConfig.ExecStart = config.services.flatpak.internal.mainScript.activation;
      # mkIfElse when?
      wantedBy = mkMerge [
        (mkIf (!cfg.runWithoutGui) [ "graphical.target" ])
        (mkIf cfg.runWithoutGui [ "multi-user.target" ])
      ];
    };
    services."manage-flatpaks-auto" = applyServiceConfig {
      serviceConfig.ExecStart = config.services.flatpak.internal.mainScript.auto;
      after = [ "manage-flatpaks-activation.service" ];
      requisite = mkIf (!cfg.runWithoutGui) [
        "graphical.target"
      ];
    };
    timers."manage-flatpaks-auto" = mkIf cfg.enable {
      timerConfig = {
        OnCalendar = cfg.onCalendar;
        Persistent = true;
      };
    };
  };
}
