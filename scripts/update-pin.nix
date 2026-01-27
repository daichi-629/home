{ pkgs, self, ... }:
let pythonEnv = pkgs.python3.withPackages (ps: [ ]);
in {
  updatePins = pkgs.writeShellScriptBin "update-pins" ''
    exec ${pythonEnv}/bin/python ${self}/scripts/update-pins.py "$@"
  '';
}

