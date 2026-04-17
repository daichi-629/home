{ pkgs, self, ... }:
{
  bootstrapNewDevice = pkgs.writeShellScriptBin "bootstrap-new-device" ''
    export PATH="${pkgs.lib.makeBinPath [
      pkgs.bash
      pkgs.coreutils
      pkgs.git
      pkgs.hostname
      pkgs.nix
      pkgs.openssh
      pkgs.python3
    ]}:$PATH"
    exec ${pkgs.bash}/bin/bash ${self}/scripts/bootstrap-new-device.sh "$@"
  '';
}
