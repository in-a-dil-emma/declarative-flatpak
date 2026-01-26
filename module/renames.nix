{ lib, ... }:
let
  inherit (lib) mkRenamedOptionModule;
in

{
  imports = [
    (mkRenamedOptionModule
      [ "services" "flatpak" "UNCHECKEDpostEverythingCommand" ]
      [ "services" "flatpak" "UNCHECKEDfinalizeCommand" ]
    )
  ];
}
