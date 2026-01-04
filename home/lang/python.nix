{ config, pkgs, lib, ... }:

let cfg = config.my.lang.python;
in {
  options.my.lang.python.enable = lib.mkEnableOption "python toolchain";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ uv ];

  };
}

