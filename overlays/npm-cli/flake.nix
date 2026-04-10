{
  description = "Shared helpers for npm CLI overlays.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
  };

  outputs = { ... }: {
    lib = {
      mkNpmCli = import ./package.nix;
      mkUpdateLock = import ./update-lock.nix;
    };
  };
}
