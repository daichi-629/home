{ config, pkgs, lib, ... }:
let
  cfg = config.my.lang.latex;
in
{
  options.my.lang.latex.enable = lib.mkEnableOption "LaTex toolchain";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      texliveFull
    ];
    # 仮のpath
    home.sessionPath = [
      "/usr/local/texlive/2025/bin/x86_64-linux"
    ];
  };
}

