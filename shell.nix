let
  inputs = import ./npins;
  pkgs = import inputs.nixpkgs {};
  treefmt = import inputs.treefmt-nix;

  inherit (pkgs) mkShellNoCC npins ncurses ostree gawk jq;
in mkShellNoCC {
  packages = [
    (treefmt.mkWrapper pkgs ./lib/treefmt.nix)
    ncurses
    ostree
    npins
    gawk
    jq
  ];
  NIX_PATH="nixpkgs=${inputs.nixpkgs}";
}
