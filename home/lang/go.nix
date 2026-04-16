{ config, pkgs, lib, ... }:

let cfg = config.my.lang.go;
in {
  options.my.lang.go.enable = lib.mkEnableOption "Go language support";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      go
      golines
      golangci-lint
      delve
    ];
  };
}
