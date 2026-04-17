{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.my.lang.rust;
  rustToolchain = pkgs.rust-bin.stable.latest.default.override {
    extensions = [
      "clippy"
      "rust-analyzer"
      "rust-src"
      "rustfmt"
    ];
  };
in
{
  options.my.lang.rust.enable = lib.mkEnableOption "rust toolchain";

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.gdb
      rustToolchain
      pkgs.rustowl
    ];

    home.sessionPath = [ "$HOME/.cargo/bin" ];
  };
}
