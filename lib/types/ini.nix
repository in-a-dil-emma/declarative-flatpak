{ pkgs, lib }:
{
  # Credit: https://github.com/PJungkamp #23 #25
  ini = pkgs.formats.ini {
    listToValue = l: (lib.concatMapStringsSep ";" (lib.generators.mkValueStringDefault { }) l) + ";";
  };
}
