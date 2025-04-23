let
  inputs = import ./npins;
  pkgs = import inputs.nixpkgs {};
  inherit (pkgs) mkShellNoCC npins ncurses ostree gawk jq;
in mkShellNoCC {
  packages = [
    ncurses
    ostree
    npins
    gawk
    jq
  ];
  NIX_PATH="nixpkgs=${inputs.nixpkgs}";
}
