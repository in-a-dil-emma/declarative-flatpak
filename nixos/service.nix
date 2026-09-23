{ config, lib, ... }:

let
  xlib = import ../lib/modules.nix { inherit lib; };
  inherit (xlib)
    mkIfElseIf
    mkIfElse
    ;
  inherit (lib)
    recursiveUpdate
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
          Type = "oneshot";
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
      wantedBy = mkIfElse cfg.runWithoutGui [ "multi-user.target" ] [ "graphical.target" ];
      before =
        mkIfElseIf cfg.delayStartup cfg.runWithoutGui
          [ "systemd-user-sessions.service" ]
          [ "display-manager.service" ];
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
