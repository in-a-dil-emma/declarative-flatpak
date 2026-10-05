let
  inputs = import ./npins;
  pkgs = import inputs.nixpkgs { };
  treefmt = import inputs.treefmt-nix;

  inherit (pkgs)
    mkShellNoCC
    ncurses
    ostree
    npins
    gawk
    jq
    ;
in
mkShellNoCC {
  shellHook = ''
    echo 'Nixpkgs is pinned to ${pkgs.lib.version}'
  '';
  packages = [
    (treefmt.mkWrapper pkgs ./lib/treefmt.nix)
    ncurses
    ostree
    npins
    gawk
    jq
  ];
  NIX_PATH = "nixpkgs=${inputs.nixpkgs}";
}
