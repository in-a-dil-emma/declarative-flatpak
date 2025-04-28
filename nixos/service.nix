{ config, lib, ... }:

let
  inherit (lib) mkIf optionals;
  
  cfg = config.services.flatpak;
in

{
  config.systemd = mkIf cfg.enable {
    services."manage-flatpaks" = {
      description = "Manage flatpaks";
      wants = mkIf cfg.runOnActivation [
        "network-online.target"
      ];
      after = mkIf cfg.runOnActivation [
        "network-online.target"
        (mkIf cfg.waitForInternet "nss-lookup.target")
      ];
      wantedBy = mkIf cfg.runOnActivation [
        "multi-user.target"
      ];
      serviceConfig.ExecStart = config.services.flatpak.mainScript;
    };
    timers."manage-flatpaks" = mkIf (cfg.onCalendar != null) {
      wants = [
        "network-online.target"
      ];
      after = [
        "network-online.target"
      ] ++ (optionals cfg.waitForInternet [ "nss-lookup.target" ]);
      wantedBy = [ "multi-user.target" ];
      timerConfig = {
        OnCalendar = cfg.onCalendar;
        Persistent = true;
      };
    };
  };
}
