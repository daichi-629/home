{
  description = "OpenAI Codex CLI overlay.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    npm-cli = {
      url = "path:../npm-cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, npm-cli }:
    npm-cli.lib.mkNpmCliOverlay {
      inherit self nixpkgs;
      packageAttr = "codex";
      packageNix = ./package.nix;
      updateLockNix = ./update-lock.nix;
      updateBinName = "update-codex-lock";
      versionsDir = ./versions;
      extraCallPackageArgs = { inherit npm-cli; };
    };
}
