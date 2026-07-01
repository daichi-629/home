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
  pname = "wrangler";
  src = ./.;
  packageName = "wrangler";
  inherit packageLockFile;
  binName = "wrangler";
  binPath = "bin/wrangler.js";
  description = "Cloudflare Workers command-line tool";
  homepage = "https://www.npmjs.com/package/wrangler";
}
