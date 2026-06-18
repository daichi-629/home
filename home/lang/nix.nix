{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.lang.nix;
in
{
  options.my.lang.nix.enable = lib.mkEnableOption "Nix language support";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      nil
      nixfmt
      statix
      deadnix
    ];
  };
}
