{ pkgs, ... }: {
  my.lang.node.enable = true;
  my.lang.rust.enable = true;
  my.tools.claude.enable = true;
  my.lang.latex.enable = true;
  my.tools.codex.enable = true;
  my.tools.opencode.enable = true;
  home.packages = with pkgs; [ xclip ];
}
