{ pkgs, config, ... }: {
  my.lang.node.enable = true;
  my.lang.rust.enable = true;
  my.tools.claude.enable = true;
  my.lang.latex.enable = true;
  my.tools.codex.enable = true;
  my.tools.opencode.enable = true;
  home.packages = with pkgs; [
    xclip
    xeyes
    obsidian
    (writeShellScriptBin "notify-discord" ''
      exec ${
        ./DESKTOP-R3C4CNN/scripts/notify_discord.sh
      } -u $(cat ${config.sops.secrets.discord_webhook_url.path}) "$@"
    '')
  ];
  imports = [ ./DESKTOP-R3C4CNN/sops.nix ];
}
