{
  name = "More general NixOS tests";

  defaults = {
    imports = [
      ./shared.nix
    ];
  };

  nodes = {
    bare = {
      # Internal logic in module/internal-options.nix resets this value to default.
      services.flatpak.flatpakDir = null;
    };
    dirs = {
    };
    persist = {
      services.flatpak = {
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
    overrides = {
      services.flatpak = {
        flatpakDir = "/target";
        overrides."org.foobar.Foobar".Context.filesystems = [ "home" "host-os" ];
      };
    };
  };

  testScript = ''
    bare.wait_for_unit("multi-user.target")
    bare.wait_until_succeeds("systemctl is-active -q complete.target", timeout=120)
    bare.succeed("which flatpak")
    bare.succeed("[ $(flatpak list --system | wc -l) -eq 0 ]")

    dirs.wait_for_unit("multi-user.target")
    dirs.wait_until_succeeds("systemctl is-active -q complete.target", timeout=120)
    dirs.succeed("stat /target")

    persist.start(allow_reboot=True)
    persist.wait_for_unit("multi-user.target")
    persist.wait_until_succeeds("systemctl is-active -q complete.target", timeout=120)
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

    overrides.wait_for_unit("multi-user.target")
    overrides.wait_until_succeeds("systemctl is-active -q complete.target", timeout=120)
    overrides.succeed("stat /target/overrides/org.foobar.Foobar")
    overrides.succeed("grep -q '[Context]' /target/overrides/org.foobar.Foobar")
    overrides.succeed("grep -q 'filesystems=home;host-os' /target/overrides/org.foobar.Foobar")
  '';
}
