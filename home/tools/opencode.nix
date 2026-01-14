{ config, pkgs_unstable, lib, ... }:

let cfg = config.my.tools.opencode;
in {
  options.my.tools.opencode.enable = lib.mkEnableOption "Opencode toolchain";

  config =
    lib.mkIf cfg.enable { home.packages = with pkgs_unstable; [ opencode ]; };
}
