{
  hmCommonModules,
  username,
  pkgs,
  ...
}:
{
  homebrew = {
    enable = true;
    casks = [
      "brave-browser"
      "slack"
      "skim"
      "tailscale"
      "zoom"
      "microsoft-teams"
      "bitwarden"
      "obsidian"
      "zotero"
      "lm-studio"
      "microsoft-office"
      "ghostty"
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
    my.tools.neovim.options.socket.enable = true;
    home.packages = with pkgs; [
      git-crypt
      gnupg
    ];
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
