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
  pname = "codex";
  src = ./.;
  packageName = "@openai/codex";
  inherit packageLockFile;
  binName = "codex";
  binPath = "bin/codex.js";
  description = "OpenAI Codex CLI";
  homepage = "https://www.npmjs.com/package/@openai/codex";
}
