{ npm-cli, writeShellApplication, nodejs_22 }:

(npm-cli.lib.mkUpdateLock { inherit writeShellApplication nodejs_22; }) {
  packageName = "wrangler";
  overlayDir = ./.;
  updateBinName = "update-wrangler-lock";
}
