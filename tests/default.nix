let
  inputs = import ../npins;
  pkgs = import inputs.nixpkgs {};
  inherit (pkgs.testers) runNixOSTest;
in runNixOSTest {
  name = "NixOS test";

  defaults = {
    imports = [
      ../src/modules/nixos.nix
    ];

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal
      ];
      config.common.default = "*";
    };
  };

  nodes = {
    bare = { config, pkgs, ... }: {
      services.flatpak.enable = true;
    };
    disabled = { config, pkgs, ... }: {
      services.flatpak = {
        enable = true;
        enableModule = false;
        waitForInternet = false;
      };
    };
    custom_dirs = { config, pkgs, ... }: {
      services.flatpak = {
        enable = true;
        flatpakDir = "/target";
        waitForInternet = false;
      };
    };
    installation = { config, lib, pkgs, ... }: {
      services.flatpak = {
        enable = true;
        flatpakDir = "/target";
        remotes = {
          "test" = ../vm/files/gol.launcher.moe.flatpakrepo;
        };
        packages = [
          ":${../vm/files/xwaylandvideobridge.flatpak}"
        ];
        debug = true;
        waitForInternet = false;
      };
    };
    persist = { config, pkgs, ... }: {
      services.flatpak = {
        enable = true;
        flatpakDir = "/target";
        UNCHECKEDpostEverythingCommand = ''
          touch /target/repo/thisfileshouldpersist
          touch /target/thisfileshouldnotpersist
        '';
        packages = [
          ":${../vm/files/xwaylandvideobridge.flatpak}"
        ];
        debug = true;
        waitForInternet = false;
      };
    };
  };

  testScript = ''
    start_all()

    disabled.wait_for_unit("multi-user.target")
    disabled.succeed("which flatpak")
    disabled.fail("systemctl status --no-pager manage-system-flatpaks.service")
    disabled.shutdown()
  
    bare.wait_for_unit("multi-user.target")
    bare.succeed("which flatpak")
    bare.succeed("systemctl list-unit-files -l | grep 'manage-system-flatpaks'")
    bare.shutdown()

    custom_dirs.wait_for_unit("multi-user.target")
    custom_dirs.wait_for_unit("manage-system-flatpaks.service")
    custom_dirs.wait_until_succeeds("stat /target", timeout=60)
    custom_dirs.shutdown()

    installation.wait_for_unit("multi-user.target")
    installation.wait_for_unit("manage-system-flatpaks.service")
    installation.wait_until_succeeds("stat /target/.module", timeout=120)
    installation.wait_until_succeeds("stat /target/repo", timeout=120)
    installation.wait_until_succeeds("stat /target/exports", timeout=120)
    installation.succeed("stat /target/exports/bin/org.kde.xwaylandvideobridge")
    installation.succeed("flatpak run --command=true org.kde.xwaylandvideobridge")
    installation.fail("flatpak run --command=false org.kde.xwaylandvideobridge")
  
    persist.start(allow_reboot=True)
    persist.wait_for_unit("multi-user.target")
    persist.wait_for_unit("manage-system-flatpaks.service")
    persist.wait_for_file("/target/repo", timeout=120)
    # Added by POST hook, both should succeed
    persist.succeed("stat /target/repo/thisfileshouldpersist")
    persist.succeed("stat /target/thisfileshouldnotpersist")
    persist.reboot()
    # errors begin here...
    persist.wait_for_unit("multi-user.target")
    persist.wait_for_unit("manage-system-flatpaks.service")
    persist.wait_until_succeeds("stat /target/.module/new", timeout=60)
    persist.wait_until_fails("stat /target/.module/new", timeout=60)
    persist.succeed("stat /target/repo/thisfileshouldpersist")
    persist.fail("stat /target/thisfileshouldnotpersist")
    persist.shutdown()
  '';
}
