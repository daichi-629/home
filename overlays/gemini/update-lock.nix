{ npm-cli, writeShellApplication, nodejs_22 }:

(npm-cli.lib.mkUpdateLock { inherit writeShellApplication nodejs_22; }) {
  name = "update-gemini-cli-lock";
  overlayName = "gemini";
  overlayRootEnvVar = "GEMINI_OVERLAY_ROOT";
  packageName = "@google/gemini-cli";
}
