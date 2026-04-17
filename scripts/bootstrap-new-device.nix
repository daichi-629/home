{ pkgs, self, ... }:
let
  pythonEnv = pkgs.python3;
in
{
  bootstrapNewDevice = pkgs.writeShellScriptBin "bootstrap-new-device" ''
    set -euo pipefail

    usage() {
      cat <<'EOF'
Usage:
  bootstrap-new-device <host-id> <host-name> <username> [system]

Examples:
  bootstrap-new-device 4 thinkpad-x1 daichi
  bootstrap-new-device 4 thinkpad-x1 daichi aarch64-darwin

Environment variables:
  SECRETS_REPO_URL   Override secrets repository URL.
  SECRETS_DIR        Override secrets repository checkout path.
  HOME_COMMIT_MSG    Commit message for this repository.
  SECRETS_COMMIT_MSG Commit message for the secrets repository.
  FULL_FLAKE_UPDATE  Set to 1 to run `nix flake update` instead of only updating `my_secrets`.
EOF
    }

    if [ "$#" -lt 3 ] || [ "$#" -gt 4 ]; then
      usage >&2
      exit 1
    fi

    host_id="$1"
    host_name="$2"
    username="$3"
    system="''${4:-x86_64-linux}"

    case "$host_id" in
      ""|*[!0-9]*)
        echo "host-id must be numeric: $host_id" >&2
        exit 1
        ;;
    esac

    repo_root="$(${pkgs.git}/bin/git rev-parse --show-toplevel)"
    secrets_repo_url="''${SECRETS_REPO_URL:-git@github.com:daichi-629/home-secrets.git}"
    secrets_dir="''${SECRETS_DIR:-$repo_root/../secrets-home-manager}"

    if [ -n "$(${pkgs.git}/bin/git -C "$repo_root" status --porcelain)" ]; then
      echo "home-manager repo has uncommitted changes; aborting." >&2
      exit 1
    fi

    if [ ! -d "$secrets_dir/.git" ]; then
      ${pkgs.git}/bin/git clone "$secrets_repo_url" "$secrets_dir"
    else
      if [ -n "$(${pkgs.git}/bin/git -C "$secrets_dir" status --porcelain)" ]; then
        echo "secrets repo has uncommitted changes; aborting." >&2
        exit 1
      fi
      ${pkgs.git}/bin/git -C "$secrets_dir" pull --ff-only
    fi

    export REPO_ROOT="$repo_root"
    export SECRETS_DIR="$secrets_dir"
    export HOST_ID="$host_id"
    export HOST_NAME="$host_name"
    export USERNAME_VALUE="$username"
    export SYSTEM_VALUE="$system"

    ${pythonEnv}/bin/python <<'PY'
from pathlib import Path
import os

repo_root = Path(os.environ["REPO_ROOT"])
secrets_dir = Path(os.environ["SECRETS_DIR"])
host_id = os.environ["HOST_ID"]
host_name = os.environ["HOST_NAME"]
username = os.environ["USERNAME_VALUE"]
system = os.environ["SYSTEM_VALUE"]

host_module_template = """{ ... }:
{
  my.lang.node.enable = true;
  my.lang.rust.enable = true;
  my.lang.nix.enable = true;
  my.tools.claude.enable = true;
}
"""

def insert_into_attrset(path: Path, anchor: str, entry: str, duplicate_checks: list[str]) -> None:
    text = path.read_text()
    for needle in duplicate_checks:
        if needle in text:
            raise SystemExit(f"{path}: duplicate entry detected for {needle!r}")
    marker = f"{anchor} = {{\n"
    start = text.find(marker)
    if start == -1:
        raise SystemExit(f"{path}: anchor not found: {anchor}")

    i = start + len(marker)
    depth = 1
    while i < len(text) and depth > 0:
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
        i += 1
    if depth != 0:
        raise SystemExit(f"{path}: could not find closing brace for {anchor}")

    end = i - 1
    updated = text[:end] + entry + text[end:]
    path.write_text(updated)

secrets_flake = secrets_dir / "flake.nix"
home_flake = repo_root / "flake.nix"
host_file = repo_root / "home" / "hosts" / f"{host_id}.nix"

insert_into_attrset(
    secrets_flake,
    "lib.my.hosts",
    f'''        "{host_id}" = {{
          hostName = "{host_name}";
          username = "{username}";
        }};\n''',
    [f'"{host_id}" = {{', f'hostName = "{host_name}";'],
)

insert_into_attrset(
    home_flake,
    "hostSettings",
    f'''        "{host_id}" = {{
          system = "{system}";
        }};\n''',
    [f'"{host_id}" = {{'],
)

if host_file.exists():
    raise SystemExit(f"{host_file}: already exists")
host_file.write_text(host_module_template)
PY

    ${pkgs.git}/bin/git -C "$secrets_dir" add flake.nix
    if [ -n "$(${pkgs.git}/bin/git -C "$secrets_dir" status --porcelain)" ]; then
      secrets_commit_msg="''${SECRETS_COMMIT_MSG:-Add ''${host_name} host defaults}"
      ${pkgs.git}/bin/git -C "$secrets_dir" commit -m "$secrets_commit_msg"
      ${pkgs.git}/bin/git -C "$secrets_dir" push
    fi

    cd "$repo_root"
    if [ "''${FULL_FLAKE_UPDATE:-0}" = "1" ]; then
      ${pkgs.nix}/bin/nix flake update
    else
      ${pkgs.nix}/bin/nix flake lock --update-input my_secrets
    fi

    ${pkgs.git}/bin/git add flake.nix flake.lock "home/hosts/$host_id.nix"
    if [ -n "$(${pkgs.git}/bin/git status --porcelain)" ]; then
      home_commit_msg="''${HOME_COMMIT_MSG:-Add ''${host_name} home-manager host}"
      ${pkgs.git}/bin/git commit -m "$home_commit_msg"
      ${pkgs.git}/bin/git push
    fi
  '';
}
