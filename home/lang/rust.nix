{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.my.lang.rust;
in
{
  options.my.lang.rust.enable = lib.mkEnableOption "rust toolchain";

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.gdb
      pkgs.curl
    ];

    home.activation.rustupInstall = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -x "$HOME/.cargo/bin/rustup" ]; then
        ${pkgs.curl}/bin/curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
      fi
    '';

    # Make cargo-installed binaries (e.g., cargo-binstall) available on PATH.
    home.sessionPath = [ "$HOME/.cargo/bin" ];
  };
}
