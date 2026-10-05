{ pkgs, ... }: {
  name = "NixOS test";

  defaults = {
    imports = [
      ../nixos
    ];

    systemd = {
      services."manage-flatpaks-activation".onSuccess = [ "complete.target" ];
      targets."complete".enable = true;
    };

    services.flatpak = {
      flatpakDir = "/target";
      runWithoutGui = true;
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
    double = {
      systemd.tmpfiles.rules = [
        "d /target/db/db"
      ];
    };
    clone = {
      systemd.tmpfiles.rules = [
        "d /target/db"
        "d /target/db/checkforme"
      ];
    };
  };

  testScript = ''
    double.succeed("stat /target/db/db")
    double.wait_for_unit("multi-user.target")
    double.wait_until_succeeds("systemctl is-active -q complete.target", timeout=120)
    double.succeed("stat /target/db/db")
    double.fail("stat /target/db/db/db")

    clone.succeed("stat /target/db")
    clone.wait_for_unit("multi-user.target")
    clone.wait_until_succeeds("systemctl is-active -q complete.target", timeout=120)
    clone.fail("stat /target/db/db")
    clone.succeed("stat /target/db/checkforme")
  '';
}
