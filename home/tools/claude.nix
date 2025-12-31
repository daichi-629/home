
{ config, pkgs, lib, ... }:

let
  cfg = config.my.tools.claude;
in
{
  options.my.tools.claude.enable = lib.mkEnableOption "claude code toolchain";

  config = lib.mkIf cfg.enable (
  let
    skillRepo = builtins.fetchGit {
     url ="git@github.com:daichi-629/claude-my-skills.git";
     rev = "2c4a31b0f0b3d5537939884c7c569b0e6f9dde75";
    };
    subAgentrepo = builtins.fetchGit {
      url = "git@github.com:daichi-629/claude-my-subagents.git";
      rev = "df6bb31261c42420babe8157886ff4df2e255fe5";
    };
  in {
    home.packages = with pkgs; [
      claude-code
    ];
    home.file.".claude/skills" = {
      source = skillRepo;
      recursive = true;
    };
    }
  );
}

