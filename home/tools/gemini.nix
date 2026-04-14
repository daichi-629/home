{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.my.tools.gemini;
in
{
  options.my.tools.gemini.enable = lib.mkEnableOption "Gemini CLI toolchain";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.gemini-cli ];
  };
}
