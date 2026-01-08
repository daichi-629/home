{ pkgs, ... }: {
  my.lang.node.enable = true;
  my.lang.rust.enable = true;
  my.tools.claude.enable = true;
  my.lang.latex.enable = true;
  home.packages = with pkgs; [ xclip ];
}
