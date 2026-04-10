{
  lib,
  buildNpmPackage,
  importNpmLock,
  makeWrapper,
  nodejs_22,
  npm-cli,
  packageLockFile,
}:

(npm-cli.lib.mkNpmCli {
  inherit
    lib
    buildNpmPackage
    importNpmLock
    makeWrapper
    nodejs_22
    ;
}) {
  pname = "playwright-cli";
  src = ./.;
  packageName = "@playwright/cli";
  inherit packageLockFile;
  binName = "playwright-cli";
  binPath = "playwright-cli.js";
  description = "Playwright CLI wrapper";
  homepage = "https://www.npmjs.com/package/@playwright/cli";
}
