{
  description = "Google Gemini CLI overlay.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    npm-cli = {
      url = "path:../npm-cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, npm-cli }:
    npm-cli.lib.mkNpmCliOverlay {
      inherit self nixpkgs;
      packageAttr = "gemini-cli";
      packageNix = ./package.nix;
      updateLockNix = ./update-lock.nix;
      updateBinName = "update-gemini-cli-lock";
      versionsDir = ./versions;
      extraCallPackageArgs = { inherit npm-cli; };
    };
}
