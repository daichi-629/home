{ config, lib, ... }:

let
  tools = config.my.tools;
  anyAgentToolEnabled =
    tools.claude.enable
    || tools.codex.enable
    || tools.gemini.enable
    || tools.opencode.enable
    || tools.copilot.enable;
  agentInstructions = ''
    # Agent Instructions

    When storing user data that should persist across sessions, never use
    `~/.claude`, `~/.skills`, `~/.codex`, or other tool-specific directories.
    Use `~/.agent-memo` instead.

    This does not apply to project documentation or other project-owned files.
  '';
in
{
  config = lib.mkIf anyAgentToolEnabled {
    programs.agent-skills = {
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

    home.file."AGENTS.md".text = agentInstructions;
    home.file."CLAUDE.md".text = agentInstructions;
  };
}
