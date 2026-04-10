{
  description = "Playwright CLI overlay.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    npm-cli = {
      url = "path:../npm-cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, npm-cli }:
    let
      lib = nixpkgs.lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = lib.genAttrs systems;

      versionFiles = builtins.readDir ./versions;
      versionNames =
        builtins.map
          (file: lib.removeSuffix ".json" (lib.removePrefix "package-lock_" file))
          (
            builtins.filter
              (file: lib.hasPrefix "package-lock_" file && lib.hasSuffix ".json" file)
              (builtins.attrNames versionFiles)
          );
      latestVersion = builtins.head (builtins.sort (a: b: builtins.compareVersions a b > 0) versionNames);
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          mkPlaywright = packageLockFile: pkgs.callPackage ./package.nix { inherit npm-cli packageLockFile; };
          versionedPackages = builtins.listToAttrs (
            builtins.map (version: {
              name = version;
              value = mkPlaywright ./versions/${"package-lock_" + version + ".json"};
            }) versionNames
          );
          latestPackage = mkPlaywright ./versions/${"package-lock_" + latestVersion + ".json"};
        in
        {
          playwright-cli = latestPackage;
          default = latestPackage;
        }
        // versionedPackages
      );

      overlays.default = _final: prev: {
        playwright-cli = self.packages.${prev.stdenv.hostPlatform.system}.playwright-cli;
      };

      apps = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          update = pkgs.callPackage ./update-lock.nix { inherit npm-cli; };
        in
        {
          update = {
            type = "app";
            program = "${update}/bin/update-playwright-lock";
          };
        }
      );
    };
}
