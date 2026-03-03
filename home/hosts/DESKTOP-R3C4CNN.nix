{ pkgs, config, ... }: {
  my.lang.node.enable = true;
  my.lang.rust.enable = true;
  my.tools.claude.enable = true;
  my.lang.latex.enable = true;
  my.tools.codex.enable = true;
  my.tools.opencode.enable = true;
  home.packages = with pkgs; [ wl-clipboard ni graphviz-nox flatpak ];
  imports = [ ./DESKTOP-R3C4CNN/sops.nix ];

  home.sessionVariables = {
    DISPLAY = ":0";
    XDG_DATA_DIRS =
      "${config.home.homeDirectory}/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share";
  };
}
