{ rust-overlay, config, pkgs, lib, ... }:

let cfg = config.my.lang.rust;
in {
  options.my.lang.rust.enable = lib.mkEnableOption "rust toolchain";

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.rust-bin.stable.latest.default.override {
        extensions = [ "rust-analyzer" ];
      })
    ];
  };
}

