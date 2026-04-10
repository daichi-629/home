{
  description = "Shared helpers for npm CLI overlays.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
  };

  outputs = { ... }: {
    lib = {
      mkNpmCli = import ./package.nix;
      mkNpmCliOverlay = import ./overlay-flake.nix;
      mkUpdateLock = import ./update-lock.nix;
    };
  };
}
