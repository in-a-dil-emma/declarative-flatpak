{ config, lib, ... }:

let
  inherit (lib) mkIf recursiveUpdate;
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
        wantedBy = [
          "multi-user.target"
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
      before = [ "manage-flatpaks-auto.service" ];
      serviceConfig.ExecStart = config.services.flatpak.internal.mainScript.activation;
    };
    services."manage-flatpaks-auto" = applyServiceConfig {
      after = [ "manage-flatpaks-activation.service" ];
      serviceConfig.ExecStart = config.services.flatpak.internal.mainScript.auto;
    };
    timers."manage-flatpaks-auto" = mkIf cfg.enable {
      timerConfig = {
        OnCalendar = cfg.onCalendar;
        Persistent = true;
      };
    };
  };
}
