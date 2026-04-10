{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.my.tools.codex;
in
{
  options.my.tools.codex.enable = lib.mkEnableOption "Codex toolchain";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.codex ];
    programs.zsh.initContent = ''
      eval "$(codex completion zsh)"
    '';
  };
}
