{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.lang.lean;
in
{
  options.my.lang.lean.enable = lib.mkEnableOption "Lean language support";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      elan
    ];
  };
}
