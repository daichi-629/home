{ pkgs, self, ... }:
{
  bootstrapNewDevice = pkgs.writeShellScriptBin "bootstrap-new-device" ''
    exec ${pkgs.bash}/bin/bash ${self}/scripts/bootstrap-new-device.sh "$@"
  '';
}
