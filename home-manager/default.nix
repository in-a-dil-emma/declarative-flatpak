{
  config,
  ...
}:

{
  imports = [
    ../module
    ./options.nix
    ./service.nix
  ];

  # is this necessary too?
  config.xdg.enable = true;
}
