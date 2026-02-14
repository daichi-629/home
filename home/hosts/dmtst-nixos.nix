{ pkgs, config, ... }:
let
  dotconfigs = ./dmtst-nixos/dot_config;
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;
  configs = {
    hypr = "hypr";
  };
in
{
  home.packages = with pkgs; [
    brave
    obsidian
    bitwarden-desktop
    bitwarden-cli
    xfce.thunar
    xfce.thunar-archive-plugin
    xfce.thunar-media-tags-plugin
    xfce.thunar-volman
  ];
  programs.wofi.enable = true;
  programs.hyprpanel.enable = true;

  xdg.configFile = builtins.mapAttrs (name: subpath: {
    source = create_symlink "${dotconfigs}/${subpath}";
  }) configs;
}
