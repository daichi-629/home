{
  hmCommonModules,
  username,
  ...
}:
{
  homebrew = {
    enable = true;
    casks = [
      "brave-browser"
      "slack"
      "tailscale"
      "zoom"
      "microsoft-teams"
      "bitwarden"
      "obsidian"
      "zotero"
      "ghostty"
    ];
  };

  home-manager.users.${username} = {
    imports = hmCommonModules;

    my.lang.node.enable = true;
    my.lang.rust.enable = true;
    my.lang.nix.enable = true;
    my.tools.claude.enable = true;
    my.tools.codex.enable = true;
    my.tools.latex.enable = true;
  };
}
