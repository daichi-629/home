
{ config, pkgs, lib, ... }:

let
  cfg = config.my.tools.claude;
  skillRepo = builtins.fetchGit {
    url ="git@github.com:daichi-629/claude-my-skills.git";
    ref = "main";
  };
in
{
  options.my.tools.claude.enable = lib.mkEnableOption "claude code toolchain";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      claude-code
    ];
    home.file.".claude/skills" = {
      source = skillRepo;
      recursive = true;
    }
  };
}

