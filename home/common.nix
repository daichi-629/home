{config, pkgs, lib, ... }:

{
  home.stateVersion = "25.11";
  programs.home-manager.enable= true;

  home.packages = with pkgs; [
    git
    repgrep
    fd
    fzf
    jq
    bat
    eza
    zoxide
    direnv
    tmux
    neovim
  ];
  home.file."powerlevel10k".source =  "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k";

  programs.git = {
    enable = true;
  };
  programs.zsh = {
    enable = true;
  };
  programs.zsh.initContent = lib.mkMerge [
    (lib.mkOrder 1000 (builtins.readFile ../zsh/rc.zsh))
  ];
}
