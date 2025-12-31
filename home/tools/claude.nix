{ config, pkgs, lib, ... }:

let
  cfg = config.my.tools.claude;
  mkRepo = import ./lib/mk-worktree-repo.nix { inherit lib pkgs; };
in
{
  options.my.tools.claude.enable = lib.mkEnableOption "claude code toolchain";
  imports = lib.optionals cfg.enable [
        (mkRepo {
      pinKey = "my-claude-skills";
      name = "my-claude-skills";
      workdirName = "my-claude-skills";
      homeFileLinks = {
        ".claude/skills" = "/";
      };
    })
  ];

  config = lib.mkIf cfg.enable 
   {
    home.packages = with pkgs; [
      claude-code
    ];
  };
}

