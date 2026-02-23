{ pkgs, config, ... }: {
  my.lang.node.enable = true;
  my.lang.rust.enable = true;
  my.tools.claude.enable = true;
  my.lang.latex.enable = true;
  my.tools.codex.enable = true;
  my.tools.opencode.enable = true;
  home.packages = with pkgs; [
    obsidian
    wl-clipboard
    ni
  ];
  imports = [ ./DESKTOP-R3C4CNN/sops.nix ];
}
