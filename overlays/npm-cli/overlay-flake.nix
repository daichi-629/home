{
  self,
  nixpkgs,
  packageAttr,
  packageNix,
  updateLockNix,
  updateBinName,
  versionsDir,
  extraCallPackageArgs ? { },
}:

let
  lib = nixpkgs.lib;
  systems = [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];
  forAllSystems = lib.genAttrs systems;

  versionFiles = builtins.readDir versionsDir;
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
      mkPackage =
        packageLockFile:
        pkgs.callPackage packageNix (
          extraCallPackageArgs
          // {
            inherit packageLockFile;
          }
        );
      versionedPackages = builtins.listToAttrs (
        builtins.map (version: {
          name = version;
          value = mkPackage (versionsDir + "/package-lock_${version}.json");
        }) versionNames
      );
      latestPackage = mkPackage (versionsDir + "/package-lock_${latestVersion}.json");
    in
    {
      ${packageAttr} = latestPackage;
      default = latestPackage;
    }
    // versionedPackages
  );

  overlays.default = _final: prev: {
    ${packageAttr} = self.packages.${prev.stdenv.hostPlatform.system}.${packageAttr};
  };

  apps = forAllSystems (
    system:
    let
      pkgs = import nixpkgs { inherit system; };
      update = pkgs.callPackage updateLockNix extraCallPackageArgs;
    in
    {
      update = {
        type = "app";
        program = "${update}/bin/${updateBinName}";
      };
    }
  );
}
