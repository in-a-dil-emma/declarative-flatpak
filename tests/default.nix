let
  inputs = import ../npins;
  pkgs = import inputs.nixpkgs { };
  inherit (pkgs.testers) runNixOSTest;
in
runNixOSTest {
  name = "NixOS test";

  defaults = {
    imports = [
      ../nixos
    ];

    services.flatpak = {
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
    custom_dirs = {
      environment.variables.FLATPAK_SYSTEM_DIR = "/target";
      services.flatpak = {
        flatpakDir = "/target";
      };
    };
    nothing = {
      services.flatpak = {
        remotes = { };
        packages = [ ];
        overrides = { };
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
    persist-partial = {
      environment.variables.FLATPAK_SYSTEM_DIR = "/target";
      services.flatpak = {
        flatpakDir = "/target";
        forceRunOnActivation = true;
        UNCHECKEDpostEverythingCommand = ''
          touch /target/repo/thisfileshouldpersist
          touch /target/thisfileshouldnotpersist
        '';
      };
    };
    persist = {
      environment.variables.FLATPAK_SYSTEM_DIR = "/target";
      services.flatpak = {
        flatpakDir = "/target";
        UNCHECKEDpostEverythingCommand = ''
          touch /target/repo/thisfileshouldpersist
          touch /target/thisfileshouldnotpersist
        '';
      };
    };
  };

  testScript = ''
    bare.wait_for_unit("multi-user.target")
    bare.succeed("which flatpak")
    bare.succeed("systemctl list-unit-files -l | grep 'manage-flatpaks'")

    nothing.wait_for_unit("multi-user.target")
    nothing.succeed("[ $(flatpak list | wc -l) -eq 0 ]")

    custom_dirs.wait_until_succeeds("stat /target", timeout=60)

    # ironically the main feature of this module doesn't have a working test
    #installation.wait_until_succeeds("stat /target/.module", timeout=120)
    #installation.wait_until_succeeds("stat /target/repo", timeout=120)
    #installation.wait_until_succeeds("stat /target/exports", timeout=120)
    #installation.succeed("stat /target/exports/bin/org.kde.xwaylandvideobridge")
    #installation.succeed("flatpak run --command=true org.kde.xwaylandvideobridge")

    persist_partial.start(allow_reboot=True)
    persist_partial.wait_for_unit("multi-user.target")
    persist_partial.wait_for_file("/target/repo", timeout=120)
    # Added by POST hook, both should succeed
    persist_partial.succeed("stat /target/repo/thisfileshouldpersist")
    persist_partial.succeed("stat /target/thisfileshouldnotpersist")
    persist_partial.reboot()
    persist_partial.wait_for_unit("multi-user.target")
    persist_partial.wait_until_fails("stat /target/.module/new", timeout=60)
    persist_partial.succeed("stat /target/repo/thisfileshouldpersist")
    persist_partial.fail("stat /target/thisfileshouldnotpersist")

    persist.start(allow_reboot=True)
    persist.wait_for_unit("multi-user.target")
    persist.wait_for_file("/target/repo", timeout=120)
    # Added by POST hook, both should succeed
    persist.succeed("stat /target/repo/thisfileshouldpersist")
    persist.succeed("stat /target/thisfileshouldnotpersist")
    persist.reboot()
    persist.wait_for_unit("multi-user.target")
    persist.wait_until_fails("stat /target/.module/new", timeout=60)
    persist.succeed("stat /target/repo/thisfileshouldpersist")
    persist.succeed("stat /target/thisfileshouldnotpersist")
  '';
}
