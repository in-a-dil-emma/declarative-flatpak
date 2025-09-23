{ lib, ... }:
let
  inherit (lib) mkForce;
in
{
  projectRootFile = ".git/config";
  enableDefaultExcludes = true;
  settings = {
    formatter.shellcheck = {
      includes = mkForce [
        "*.sh"
      ];
      options = [
        "-a"
        "--color=always"
      ];
    };
    global.excludes = [
      "npins/**"
    ];
  };
  programs = {
    shellcheck.enable = true;
    deadnix.enable = true;
    statix.enable = true;
    nixfmt.enable = true;
  };
}
