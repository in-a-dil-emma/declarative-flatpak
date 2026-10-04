let
  inputs = import ../npins;
  pkgs = import inputs.nixpkgs { };
  inherit (pkgs) linkFarm;
  inherit (pkgs.testers) runNixOSTest;
in linkFarm "declarative-flatpak-tests" {
  standard = runNixOSTest ./standard.nix;
  graphical = runNixOSTest ./graphical.nix;
}