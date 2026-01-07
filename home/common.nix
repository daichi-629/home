{ config, pkgs, lib, ... }:
let
  mkRepo = import ./lib/mk-worktree-repo.nix { inherit lib pkgs; };
  pinFile = ../pins/repos.json;
  repo = mkRepo {
    pinKey = "my-nvim-config";
    workdirName = "my-nvim-config";
    pinsFile = pinFile;
    homeDir = config.home.homeDirectory;
  };
in {
  imports = [
    ./lang/node.nix
    ./lang/tex.nix
    ./lang/rust.nix
    ./lang/python.nix
    ./tools/claude.nix
    ./tools/codex.nix
  ];
  home.stateVersion = "25.11";
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    git
    ripgrep
    fd
    fzf
    jq
    bat
    eza
    zoxide
    direnv
    tmux
    neovim
    ghq
    zellij
    lazygit
    gh
    gh-dash
    cmake
    gcc
    gnumake
    wget
    zip
    unzip
    nixfmt-rfc-style
    nil
  ];
  home.sessionVariables = {
    EDITOR = "nvim";
    HISTSIZE = 1000;
    SAVEHIST = 100000;
    HISTFILE = "$HOME/.zsh_history";
  };

  home.file."powerlevel10k".source =
    "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k";
  home.file.".p10k.zsh".source = ../dotfiles/.p10k.zsh;

  programs.git = { enable = true; };
  programs.zsh = { enable = true; };
  programs.zsh.initContent = lib.mkMerge [
    (lib.mkOrder 1000 (builtins.readFile ./zsh/rc.zsh))
    (lib.mkOrder 1001 (builtins.readFile ./zsh/fzf.zsh))
  ];
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };


  home.activation = repo.activation;

  xdg.enable = true;
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink repo.workdir;
  xdg.configFile."zellij/config.kdl".source = ../config/zellij/config.kdl;
  xdg.configFile."git/ignore".source = ../config/git/ignore;
}
