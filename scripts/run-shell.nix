{ writeShellScriptBin }:

writeShellScriptBin "run-shell" ''
  pushd vm &>/dev/null
  nix run ../#nixosConfigurations.shell.config.system.build.vm
  popd &>/dev/null
''