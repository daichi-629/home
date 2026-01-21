{ config, pkgs, lib, ... }:
let cfg = config.my.lang.latex;
in {
  options.my.lang.latex.enable = lib.mkEnableOption "LaTex toolchain";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ texliveFull ];
    home.file.".latexindent.yaml".source = ../../dotfiles/.latexindent.yaml;
    home.file.".indentconfig.yamlh".source = ../../dotfiles/.indentconfig.yaml;
  };
}

