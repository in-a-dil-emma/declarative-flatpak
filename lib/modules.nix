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
  mkIfElseIf = guard: cond: mkIfElse (guard && cond);
  mkMergeIf = cond: mkIf cond mkMerge;
}
