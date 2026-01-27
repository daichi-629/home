{ config, pkgs, pkgs_unstable, lib, sops-nix, ... }:
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
    sops-nix.homeManagerModules.sops
    ./lang/node.nix
    ./lang/latex.nix
    ./lang/rust.nix
    ./lang/python.nix
    ./tools/claude.nix
    ./tools/codex.nix
    ./tools/opencode.nix
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
    node2nix
    sops
    age
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
  home.file."bin/update-all".source =
    "${self.packages.${pkgs.system}.update-all}/bin/update-all";
  home.sessionPath = [ "$HOME/bin" "$HOME/.local/bin" ];
  home.shell.enableZshIntegration = true;
  home.shellAliases = {
    ls = "eza --icons=always --classify=always --hyperlink";
    ghqcd = "cd $(ghq root)/$(ghq list | fzf)";
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "daichi-629";
        email = "m.daichi.08191@gmail.com";
      };
      init = { defaultBranch = "main"; };
      pull = { ff = "only"; };
    };
  };
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    setOptions = [ "HIST_IGNORE_DUPS" "EXTENDED_HISTORY" ];
  };
  programs.zsh.initContent =
    lib.mkMerge [ (lib.mkOrder 1000 (builtins.readFile ./zsh/rc.zsh)) ];
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [ "--cmd" "cd" ];
  };

  home.activation = repo.activation;

  xdg.enable = true;
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink repo.workdir;
  xdg.configFile."zellij/config.kdl".source = ../config/zellij/config.kdl;
  xdg.configFile."git/ignore".source = ../config/git/ignore;
}
