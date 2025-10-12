{ pkgs, lib, ... }:

let
  flatpak-types = callPackage ../lib/types/flatpak.nix { };

  overrideValue' = oneOf [
    str
    number
    path
    attrs
  ];
  overrideValue = either (listOf overrideValue') overrideValue';
  inherit (lib.types)
    attrsOf
    number
    either
    listOf
    nullOr
    attrs
    oneOf
    bool
    path
    str
    ;
  inherit (lib.options) literalMD literalExpression;
  inherit (lib) mkOption mkEnableOption pipe;
  inherit (pkgs) callPackage;

  inherit (flatpak-types) package remote;
in
{
  options.services.flatpak = {
    packages = mkOption {
      type = listOf package;
      default = [ ];
      example = literalExpression ''
        [
          "flathub:app/org.kde.index//stable"
          "flathub-beta:app/org.kde.kdenlive/x86_64/stable"
          "kustom-source:app/org.kde.krita/x86_64/stable:1234567890123456789012345678901234567890123456789012345678901234"
        ]
      '';
      description = ''
        Which packages to install.

        As soon as you use more than one remote you should start prefixing them to avoid conflicts.
        The package must be prefixed with the remote's name and a colon.
      '';
    };
    flatpakDir = mkOption {
      type = nullOr path;
      default = null;
      description = literalMD ''
        Path where to link the flatpak file to.

        By default will be:
        - /var/lib/flatpak (for NixOS)
        - ~/.local/share/flatpak (for home-manager)

        If left at default value, the corresponding directory will be picked.
      '';
    };
    preRemotesCommand = mkOption {
      type = nullOr str;
      default = "";
      description = ''
        Which commands to run before remoted are configured.

        All essential variables have been initialized by now.
      '';
    };
    preInstallCommand = mkOption {
      type = nullOr str;
      default = "";
      description = ''
        Which commands to run before refs are installed.
      '';
    };
    preSwitchCommand = mkOption {
      type = nullOr str;
      default = "";
      description = ''
        Which commands to run before the generation is activated.
      '';
    };
    UNCHECKEDpostEverythingCommand = mkOption {
      type = nullOr str;
      default = "";
      description = literalMD ''
        Which commands to run after the script completed execution.

        The error status of this command will **not** be checked. Errors that occur will **not** cause the transaction to fail!
      '';
    };
    remotes = mkOption {
      type = remote;
      default = { };
      example = literalExpression ''
        services.flatpak.remotes = {
          "flathub" = "https://flathub.org/repo/flathub.flatpakrepo";
          "flathub-beta" = "/path/flathub-beta.flatpakrepo";
        };
      '';
      description = ''
        Declare flatpak remotes.
      '';
    };
    overrides = mkOption {
      type = pipe overrideValue [
        attrsOf
        attrsOf
        attrsOf
      ];
      default = { };
      example = literalExpression ''
        services.flatpak.overrides = {
          "global" = {
            filesystems = [
              "home"
              "!~/Games/Heroic"
            ];
            environment = {
              "MOZ_ENABLE_WAYLAND" = 1;
            };
            sockets = [
              "!x11"
              "fallback-x11"
            ];
          };
        }
      '';
      description = ''
        Overrides to apply.

        Paths prefixed with '!' will deny read permissions for that path, also applies to sockets.
        Paths may not be escaped.
      '';
    };
    # failureNotification = {
    #   enable = mkOption {
    #
    #   };
    #   targetGroup = mkOption {
    #
    #   };
    #   messageTemplate = mkOption {
    #
    #   };
    # };
    # blockStartup = mkOption {
    #   type = bool;
    #   default = false;
    #   description = ''
    #   '';
    # };
    forceRunOnActivation = mkOption {
      type = bool;
      default = false;
    };
    onCalendar = mkOption {
      type = str;
      default = "weekly";
    };
    veryVerbose = mkEnableOption "Verbose logging.";
  };
}
