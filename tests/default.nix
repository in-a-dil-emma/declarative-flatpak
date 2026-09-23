let
  inputs = import ../npins;
  pkgs = import inputs.nixpkgs { };
  lib = pkgs.lib;
  inherit (pkgs.testers) runNixOSTest;
in
runNixOSTest {
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
    bare = { };
    graphical = {
      services.flatpak.runWithoutGui = lib.mkForce false;
      systemd.targets."graphical".enable = true;
    };
    dirs = {
      environment.variables.FLATPAK_SYSTEM_DIR = "/target";
      services.flatpak = {
        flatpakDir = "/target";
      };
    };
    installation = {
      environment.variables.FLATPAK_SYSTEM_DIR = "/target";
      services.flatpak = {
        flatpakDir = "/target";
        remotes = {
          "test" = ../vm/files/gol.launcher.moe.flatpakrepo;
        };
        packages = [
          ":${../vm/files/xwaylandvideobridge.flatpak}"
        ];
      };
    };
    persist = {
      environment.variables.FLATPAK_SYSTEM_DIR = "/target";
      services.flatpak = {
        flatpakDir = "/target";
        alwaysRunOnActivation = true;
        UNCHECKEDfinalizeCommand = ''
          # This check ensures that these files are created only once...
          # On first run, this condition will be true, on the second, it will be false.
          # If the service restarts before the reboot, that's a problem that needs to be fixed.
          if [ ! -e /target/repo/thisfileshouldpersist ]; then
            touch /target/thisfileshouldnotpersist
            touch /target/db/thisfileshouldpersist
          fi
          touch /target/repo/thisfileshouldpersist
        '';
      };
    };
    always = {
      # Check if the activation script runs only on the first boot.
      # It shouldn't run a second time, because of the config diff check.
      services.flatpak = {
        flatpakDir = "/target";
        UNCHECKEDfinalizeCommand = ''
          touch /target/thisfileshouldnotpersist
        '';
      };
    };
  };

  testScript = ''
    bare.wait_for_unit("multi-user.target")
    bare.wait_until_succeeds("systemctl is-active -q complete.target", timeout=120)
    bare.succeed("which flatpak")
    bare.succeed("[ $(flatpak list --system | wc -l) -eq 0 ]")

    graphical.wait_for_unit("multi-user.target")
    graphical.require_unit_state("graphical.target", "inactive")
    graphical.start_job("graphical.target")
    graphical.wait_until_succeeds("systemctl is-active -q complete.target", timeout=120)

    dirs.wait_for_unit("multi-user.target")
    dirs.wait_until_succeeds("systemctl is-active -q complete.target", timeout=120)
    dirs.succeed("stat /target")

    #installation.wait_for_unit("multi-user.target")
    #installation.wait_until_succeeds("systemctl is-active -q complete.target", timeout=120)
    #installation.succeed("stat /target/.module")
    #installation.succeed("stat /target/repo")
    #installation.succeed("stat /target/exports")
    #installation.succeed("stat /target/exports/bin/org.kde.xwaylandvideobridge")
    #installation.succeed("flatpak run --command=true org.kde.xwaylandvideobridge")

    persist.start(allow_reboot=True)
    persist.wait_for_unit("multi-user.target")
    persist.wait_until_succeeds("systemctl is-active -q complete.target", timeout=120)
    # Added by POST hook, both should succeed
    persist.succeed("stat /target/repo/thisfileshouldpersist")
    persist.succeed("stat /target/db/thisfileshouldpersist")
    persist.succeed("stat /target/thisfileshouldnotpersist")
    persist.reboot()
    persist.wait_for_unit("multi-user.target")
    persist.wait_until_succeeds("systemctl is-active -q complete.target", timeout=120)
    persist.succeed("stat /target/repo/thisfileshouldpersist")
    persist.succeed("stat /target/db/thisfileshouldpersist")
    persist.fail("stat /target/thisfileshouldnotpersist")

    always.start(allow_reboot=True)
    always.wait_for_unit("multi-user.target")
    always.wait_until_succeeds("systemctl is-active -q complete.target", timeout=120)
    always.succeed("stat /target/thisfileshouldnotpersist")
    always.reboot()
    always.wait_for_unit("multi-user.target")
    always.wait_until_succeeds("systemctl is-active -q complete.target", timeout=120)
    always.succeed("rm /target/thisfileshouldnotpersist")
    always.reboot()
    always.wait_for_unit("multi-user.target")
    always.wait_until_succeeds("systemctl is-active -q complete.target", timeout=120)
    always.fail("stat /target/thisfileshouldnotpersist")
  '';
}
