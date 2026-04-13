{
  pkgs,
  pkgs_unstable,
  config,
  ...
}:
{
  my.nvim.clipboard.provider = "wayland";
  my.lang.node.enable = true;
  my.lang.rust.enable = true;
  my.lang.nix.enable = true;
  my.tools.claude.enable = true;
  my.lang.latex.enable = true;
  my.lang.ruby.enable = true;
  my.tools.codex.enable = true;
  my.tools.opencode.enable = true;
  my.tools.playwright.enable = true;
  my.tools.copilot.enable = true;

  home.packages = with pkgs; [
    wl-clipboard
    poppler-utils
    ni
    graphviz-nox
    flatpak
    hledger
    hledger-ui
    hledger-web
    bitwarden-cli
    imagemagick
    zathura
    zathuraPkgs.zathura_pdf_poppler
  ];

  my.emails.enableAccounts = [
    "gmail1"
    "campus_mail"
  ];
  sops.age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";

  home.sessionVariables = {
    DISPLAY = ":0";
    XDG_DATA_DIRS = "${config.home.homeDirectory}/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share";
  };
}
