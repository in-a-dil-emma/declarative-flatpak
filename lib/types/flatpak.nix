{ lib }:

let
  inherit (lib) mkOptionType;
  regexes = import ../regexes.nix;
in
{
  package = mkOptionType {
    name = "package";
    description = "flathub package definition";
    check =
      x:
      if builtins.match "^${regexes.fpkg}$" x != null then
        true
      else
        throw ''
          Hi there. Your package "${x}" needs to follow the naming scheme:
            remote:type/ref/arch/branch:commit

          Consult README.md
        '';
  };
  remote = mkOptionType {
    name = "remote";
    description = "flathub remote";
    check =
      x:
      if builtins.all (elm: builtins.match "^${regexes.fremote}$" elm != null) (builtins.attrNames x) then
        true
      else
        throw ''
          Hello again. Your remote "${x}" contains forbidden symbols.
          It may only contain characters from a to z (upper and lowercase), numbers and hyphens (-).
        '';
  };
}
