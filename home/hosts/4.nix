{
  hmCommonModules,
  username,
  pkgs,
  pkgs_unstable,
  ...
}:
{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
    };
    casks = [
      "brave-browser"
      "slack"
      "skim"
      "tailscale"
      "zoom"
      "microsoft-teams"
      "bitwarden"
      {
        name = "obsidian";
        greedy = true;
      }
      "zotero"
      "lm-studio"
      "microsoft-office"
      "ghostty"
      "docker"
    ];
  };

  home-manager.users.${username} = {
    imports = hmCommonModules;
    my.lang.node.enable = true;
    my.lang.rust.enable = true;
    my.lang.nix.enable = true;
    my.lang.latex.enable = true;
    my.tools.claude.enable = true;
    my.tools.codex.enable = true;
    my.tools.gemini.enable = true;
    my.tools.antigravity.enable = true;
    my.tools.herdr.enable = true;
    my.lang.lean.enable = true;
    my.tools.neovim.options.socket.enable = true;
    my.tools.scrapling.enable = true;
    my.tools.playwright.enable = true;
    home.packages =
      with pkgs;
      [
        git-crypt
        poppler-utils
        wrangler
      ];
    programs.gpg.enable = true;
    services.gpg-agent = {
      enable = true;
      enableZshIntegration = true;
      pinentry.package = pkgs.pinentry-curses;
    };

    programs.ghostty = {
      enable = false;

      package = pkgs.brewCasks.ghostty;

      enableZshIntegration = true;

      settings = {
        shell-integration-features = "ssh-env,ssh-terminfo";
      };
    };
  };
}
