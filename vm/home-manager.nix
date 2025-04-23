{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users."user" = { config, lib, ... }: {
      imports = [
        ../src/modules/home-manager.nix
      ];

      services.flatpak = {
        packages = [
          "flathub-beta:app/org.chromium.Chromium//beta"
          "flathub:app/com.usebottles.bottles//stable"
        ];
        remotes = {
          "flathub" = "https://flathub.org/repo/flathub.flatpakrepo";
          "flathub-beta" = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
        };
        # flatpak-dir = "${config.home.homeDirectory}/flatpak";
        # debug = true;
        onCalendar = "hourly";
        runOnActivation = true;
      };

      home.file.".zshrc".text = "";

      home.stateVersion = lib.trivial.release;
    };
  };
}
