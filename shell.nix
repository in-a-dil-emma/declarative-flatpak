{ inputs
, mkShell, callPackage, nixos-shell
, ncurses, ostree, gawk, jq, nil }:

mkShell {
  packages = [
    nixos-shell
    ncurses
    ostree
    gawk
    nil
    jq

    (callPackage ./scripts/run-shell.nix { })
    (callPackage ./scripts/run-tests.nix { })
  ];
  shellHook = ''
    echo -e "\033[31mrun-shell\033[0m to run your code in nixos-shell"
    echo -e "\033[31mrun-tests\033[0m to run nixos tests"
  '';
  NIX_PATH="nixpkgs=${inputs.nixpkgs}";
}