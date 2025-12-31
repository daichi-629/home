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

  programs.git = {
    enable = true;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
  };
}
