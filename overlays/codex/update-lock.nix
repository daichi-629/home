{ npm-cli, writeShellApplication, nodejs_22 }:

(npm-cli.lib.mkUpdateLock { inherit writeShellApplication nodejs_22; }) {
  name = "update-codex-lock";
  overlayName = "codex";
  overlayRootEnvVar = "CODEX_OVERLAY_ROOT";
  packageName = "@openai/codex";
}
