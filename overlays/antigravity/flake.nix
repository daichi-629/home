{
  description = "Google Antigravity CLI overlay.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
  };

  outputs =
    { self, nixpkgs }:
    let
      lib = nixpkgs.lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          antigravity-cli = pkgs.callPackage ./package.nix { };
          update = pkgs.callPackage ./update-sources.nix { };
        in
        {
          inherit antigravity-cli;
          default = antigravity-cli;
          update-sources = update;
        }
      );

      overlays.default = _final: prev: {
        antigravity-cli = self.packages.${prev.stdenv.hostPlatform.system}.antigravity-cli;
      };

      apps = forAllSystems (system: {
        update = {
          type = "app";
          program = "${self.packages.${system}.update-sources}/bin/update-antigravity-sources";
        };
      });
    };
}
