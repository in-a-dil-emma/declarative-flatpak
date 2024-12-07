{ writeShellScriptBin }:

writeShellScriptBin "run-tests" ''
  nix flake check --print-build-logs
''