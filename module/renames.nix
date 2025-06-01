{ lib, ... }: let
  inherit (lib) mkRenamedOptionModule;
in 

{
  imports = [
    (mkRenamedOptionModule [ "services" "flatpak" "runOnActivation" ] [ "services" "flatpak" "forceRunOnActivation" ])
  ];
}
