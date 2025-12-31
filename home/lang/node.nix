{ config, pkgs, lib, ... }:

let
  cfg = config.my.lang.node;
in
{
  options.my.lang.node.enable = lib.mkEnableOption "Node.js toolchain";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      nodejs
      pnpm
    ];

    programs.zsh.initContent = ''
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
alias npm="pnpm"
alias orgnpm="npm"
    '';

  };
}

