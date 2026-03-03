{ config, pkgs, pkgs_unstable, lib, ... }:

let
  cfg = config.my.tools.claude;
  mkRepo = import ../lib/mk-worktree-repo.nix { inherit lib pkgs; };
  pinFile = ../../pins/repos.json;
  repo = mkRepo {
    pinKey = "claude-my-skills";
    workdirName = "claude-my-skills";
    pinsFile = pinFile;
    homeDir = config.home.homeDirectory;
  };
  repo2 = mkRepo {
    pinKey = "claude-my-subagents";
    workdirName = "claude-my-subagents";
    pinsFile = pinFile;
    homeDir = config.home.homeDirectory;
  };
in {
  options.my.tools.claude = {
    enable = lib.mkEnableOption "claude code toolchain";

    useNativeInstall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use native installation script instead of nixpkgs (always gets latest version)";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    # Common configuration
    {
      home.activation = repo.activation // repo2.activation // {
        claudeSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
          mkdir -p "$HOME/.claude"

          # Seed the file once, then let Claude manage future edits.
          if [ ! -e "$HOME/.claude/settings.json" ]; then
            cp "${../../dotfiles/.claude/settings.json}" "$HOME/.claude/settings.json"
          fi
        '';
      };

      home.file.".claude/skills".source =
        config.lib.file.mkOutOfStoreSymlink repo.workdir;

      home.file.".claude/agents".source =
        config.lib.file.mkOutOfStoreSymlink repo2.workdir;
      home.file.".claude/hooks/notify-osc.sh".source =
        ../../dotfiles/.claude/hooks/notify-osc.sh;
      home.file.".claude/hooks/format.sh".source =
        ../../dotfiles/.claude/hooks/format.sh;

      # Needed by notify-osc.sh timeout fallback.
      home.packages = with pkgs; [ perl ];
    }

    # Native installation - always gets latest version
    (lib.mkIf cfg.useNativeInstall {
      home.activation.installClaudeCode = lib.hm.dag.entryAfter ["writeBoundary"] ''
        if ! command -v claude &> /dev/null || [ ! -f "$HOME/.claude/bin/claude" ]; then
          echo "Installing Claude Code using native installer..."
          # Set PATH to include all tools needed by install.sh
          export PATH="${lib.makeBinPath (with pkgs; [ curl bash ])}:$PATH"
          $DRY_RUN_CMD ${pkgs.curl}/bin/curl -fsSL https://claude.ai/install.sh | $DRY_RUN_CMD ${pkgs.bash}/bin/bash
        else
          echo "Claude Code already installed at $HOME/.claude/bin/claude"
        fi
      '';

      # Add Claude to PATH
      home.sessionPath = [ "$HOME/.claude/bin" ];
    })

    # Nixpkgs installation - may be outdated
    (lib.mkIf (!cfg.useNativeInstall) {
      home.packages = with pkgs_unstable; [ claude-code ];
    })
  ]);
}
