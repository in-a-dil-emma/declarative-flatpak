{
  name = "Tests in \"graphical\" sessions for NixOS";

  defaults = {
    imports = [
      ./shared.nix
    ];

    systemd.targets."graphical".enable = true;

    services.flatpak.runWithoutGui = false;
  };

  nodes = {
    graphical = { };
  };

  testScript = ''
    graphical.wait_for_unit("multi-user.target")
    graphical.require_unit_state("graphical.target", "inactive")
    graphical.start_job("graphical.target")
    graphical.wait_until_succeeds("systemctl is-active -q complete.target", timeout=120)
  '';
}
