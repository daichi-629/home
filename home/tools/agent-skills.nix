{ config, lib, ... }:

let
  tools = config.my.tools;
  anyAgentToolEnabled =
    tools.claude.enable
    || tools.codex.enable
    || tools.gemini.enable
    || tools.opencode.enable
    || tools.copilot.enable;
in
{
  config.programs.agent-skills = lib.mkIf anyAgentToolEnabled {
    enable = true;

    sources.claude-my-skills = {
      input = "claude-my-skills";
      subdir = ".";
      filter.maxDepth = 1;
    };

    skills.enableAll = [ "claude-my-skills" ];

    targets = {
      claude = {
        enable = tools.claude.enable;
        dest = ".claude/skills";
        structure = "link";
      };
      codex = {
        enable = tools.codex.enable;
        structure = "copy-tree";
      };
      gemini = {
        enable = tools.gemini.enable;
        structure = "copy-tree";
      };
      opencode = {
        enable = tools.opencode.enable;
        structure = "copy-tree";
      };
      copilot = {
        enable = tools.copilot.enable;
        structure = "copy-tree";
      };
    };
  };
}
