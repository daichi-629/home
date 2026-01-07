{ config, pkgs, lib, ... }:

let cfg = config.my.lang.node;
in {
  options.my.lang.node.enable = lib.mkEnableOption "Node.js toolchain";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ nodejs pnpm ];

    programs.zsh.initContent = ''
      case ":$PATH:" in
        *":$PNPM_HOME:"*) ;;
        *) export PATH="$PNPM_HOME:$PATH" ;;
      esac
    '';
    home.sessionVariables.PNPM_HOME = "$HOME/.local/share/pnpm";
    home.shellAliases = {
      npm = "pnpm";
      orgnpm = "$(which -a npm | grep -v pnpm | head -1)";
    };
  };
}

