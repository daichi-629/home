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
  pname = "gemini-cli";
  src = ./.;
  packageName = "@google/gemini-cli";
  inherit packageLockFile;
  binName = "gemini";
  binPath = "bundle/gemini.js";
  description = "Google Gemini CLI";
  homepage = "https://www.npmjs.com/package/@google/gemini-cli";
  npmFlags = [ "--omit=optional" ];
}
