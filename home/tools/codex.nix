{ config, pkgs_unstable, lib, ... }:

let cfg = config.my.tools.codex;
in {
  options.my.tools.codex.enable = lib.mkEnableOption "Codex toolchain";

  config = lib.mkIf cfg.enable { home.packages = with pkgs_unstable; [ codex ]; };
}

