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
  options.my.tools.claude.enable = lib.mkEnableOption "claude code toolchain";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs_unstable; [ claude-code ];
    home.activation = repo.activation // repo2.activation;

    home.file.".claude/skills".source =
      config.lib.file.mkOutOfStoreSymlink repo.workdir;

    home.file.".claude/agents".source =
      config.lib.file.mkOutOfStoreSymlink repo2.workdir;
    home.file."claude/settings.json".source =
      ../../dotfiles/claude/settings.json;
  };
}

