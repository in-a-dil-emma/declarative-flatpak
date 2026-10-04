{ lib, ... }:
let
  inherit (lib)
    mkMerge
    mkIf
    ;
in
rec {
  mkElse = cond: mkIf (!cond);
  mkIfElse =
    cond: yes: no:
    mkMerge [
      (mkIf cond yes)
      (mkElse cond no)
    ];
  # Beaufitul name.
  mkIfElseIf =
    guard: cond: yes: no:
    mkMerge [
      (mkIf (guard && cond) yes)
      (mkIf (guard && !cond) no)
    ];
  mkMergeIf = cond: mkIf cond mkMerge;
}
