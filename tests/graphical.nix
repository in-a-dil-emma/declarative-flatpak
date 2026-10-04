{ pkgs, ... }: {
  name = "NixOS test";

  defaults = {
    imports = [
      ../nixos
    ];

    systemd = {
      services."manage-flatpaks-activation".onSuccess = [ "complete.target" ];
      targets = {
        "complete".enable = true;
        "graphical".enable = true;
      };
    };

    services.flatpak = {
      runWithoutGui = false;
      veryVerbose = true;
      enable = true;
    };

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal
      ];
      config.common.default = "*";
    };
  };

  nodes = {
    graphical = {};
  };

  testScript = ''
    graphical.wait_for_unit("multi-user.target")
    graphical.require_unit_state("graphical.target", "inactive")
    graphical.start_job("graphical.target")
    graphical.wait_until_succeeds("systemctl is-active -q complete.target", timeout=120)
  '';
}
