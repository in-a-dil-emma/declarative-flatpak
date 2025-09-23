{ lib, ... }:
let
  inherit (lib) mkRemovedOptionModule;
in

{
  imports = [
    (mkRemovedOptionModule [ "services" "flatpak" "waitForInternet" ]
      "This option was addded for VM tests and is no longer required, plus waiting for nss-lookup.target is just as reliable."
    )
  ];
}
