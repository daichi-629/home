
{
  pkgs_unstable,
  config,
  lib,
  ...
}:

let
  cfg = config.my.tools.codex;
in
{
  options.my.tools.copilot.enable = lib.mkEnableOption "copilot toolchain";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs_unstable.github-copilot-cli ];
  };
}
