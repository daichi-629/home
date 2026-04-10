{ npm-cli, writeShellApplication, nodejs_22 }:

(npm-cli.lib.mkUpdateLock { inherit writeShellApplication nodejs_22; }) {
  name = "update-playwright-lock";
  overlayName = "playwright";
  overlayRootEnvVar = "PLAYWRIGHT_OVERLAY_ROOT";
  packageName = "@playwright/cli";
}
