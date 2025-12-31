
{ config, pkgs, lib, ... }:

let
  cfg = config.my.tools.claude;
  pins = builtins.fromJSON (builtins.readFile ../../pins/repos.json);
in
{
  options.my.tools.claude.enable = lib.mkEnableOption "claude code toolchain";

  config = lib.mkIf cfg.enable (
  let
    skillRepo = builtins.fetchGit {
      url = pins.claude-my-skills.url;
      rev = pins.claude-my-skills.rev;
    };
    subAgentRepo = builtins.fetchGit {
      url = pins.claude-my-agents.url;
      rev = pins.claude-my-agents.rev;
    };
  in {
    home.packages = with pkgs; [
      claude-code
    ];
    home.file.".claude/skills" = {
      source = skillRepo;
      recursive = true;
    };
    home.file.".claude/agents"={
      source = subAgentRepo;
      recursive = true;
    };
    }
  );
}

