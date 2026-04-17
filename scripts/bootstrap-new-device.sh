#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/bootstrap-new-device.sh [options]

Options:
  --host-id ID           Override host id. Default: auto-assign or reuse existing.
  --host-name NAME       Override host name. Default: current hostname.
  --username NAME        Override username. Default: current login user.
  --system SYSTEM        Override nix system. Default: detect from uname.
  --secrets-dir PATH     Override secrets repo path. Default: ../secrets-home-manager
  --secrets-repo URL     Override secrets repo URL.
  --home-commit-msg MSG  Override commit message for this repo.
  --secrets-commit-msg MSG
                         Override commit message for secrets repo.
  --full-flake-update    Run `nix flake update` instead of only updating `my_secrets`.
  -h, --help             Show this help.

Examples:
  scripts/bootstrap-new-device.sh
  scripts/bootstrap-new-device.sh --host-name thinkpad-x1
  scripts/bootstrap-new-device.sh --host-id 4 --username daichi
EOF
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing required command: $1" >&2
    exit 1
  fi
}

detect_system() {
  local arch os
  arch="$(uname -m)"
  os="$(uname -s)"

  case "$arch" in
    x86_64|amd64) arch="x86_64" ;;
    aarch64|arm64) arch="aarch64" ;;
    *)
      echo "unsupported architecture: $arch" >&2
      exit 1
      ;;
  esac

  case "$os" in
    Linux) os="linux" ;;
    Darwin) os="darwin" ;;
    *)
      echo "unsupported operating system: $os" >&2
      exit 1
      ;;
  esac

  printf '%s-%s\n' "$arch" "$os"
}

repo_clean() {
  local repo="$1"
  [ -z "$(git -C "$repo" status --porcelain)" ]
}

HOST_ID=""
HOST_NAME="$(hostname)"
USERNAME_VALUE="$(id -un)"
SYSTEM_VALUE="$(detect_system)"
FULL_FLAKE_UPDATE=0
REPO_ROOT="$(git rev-parse --show-toplevel)"
SECRETS_DIR="${SECRETS_DIR:-$REPO_ROOT/../secrets-home-manager}"
SECRETS_REPO_URL="${SECRETS_REPO_URL:-git@github.com:daichi-629/home-secrets.git}"
HOME_COMMIT_MSG="${HOME_COMMIT_MSG:-}"
SECRETS_COMMIT_MSG="${SECRETS_COMMIT_MSG:-}"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --host-id)
      HOST_ID="$2"
      shift 2
      ;;
    --host-name)
      HOST_NAME="$2"
      shift 2
      ;;
    --username)
      USERNAME_VALUE="$2"
      shift 2
      ;;
    --system)
      SYSTEM_VALUE="$2"
      shift 2
      ;;
    --secrets-dir)
      SECRETS_DIR="$2"
      shift 2
      ;;
    --secrets-repo)
      SECRETS_REPO_URL="$2"
      shift 2
      ;;
    --home-commit-msg)
      HOME_COMMIT_MSG="$2"
      shift 2
      ;;
    --secrets-commit-msg)
      SECRETS_COMMIT_MSG="$2"
      shift 2
      ;;
    --full-flake-update)
      FULL_FLAKE_UPDATE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

case "$HOST_ID" in
  ""|*[!0-9]*) ;;
  *) ;;
esac
if [ -n "$HOST_ID" ] && ! [[ "$HOST_ID" =~ ^[0-9]+$ ]]; then
  echo "host id must be numeric: $HOST_ID" >&2
  exit 1
fi

require_cmd git
require_cmd python3
require_cmd nix

if ! repo_clean "$REPO_ROOT"; then
  echo "home-manager repo has uncommitted changes; aborting." >&2
  exit 1
fi

if [ ! -d "$SECRETS_DIR/.git" ]; then
  git clone "$SECRETS_REPO_URL" "$SECRETS_DIR"
else
  if ! repo_clean "$SECRETS_DIR"; then
    echo "secrets repo has uncommitted changes; aborting." >&2
    exit 1
  fi
  git -C "$SECRETS_DIR" pull --ff-only
fi

export REPO_ROOT SECRETS_DIR HOST_ID HOST_NAME USERNAME_VALUE SYSTEM_VALUE

RESULT="$(
python3 <<'PY'
from pathlib import Path
import os
import re

repo_root = Path(os.environ["REPO_ROOT"])
secrets_dir = Path(os.environ["SECRETS_DIR"])
host_id_override = os.environ["HOST_ID"]
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

def find_attrset_bounds(text: str, anchor: str) -> tuple[int, int]:
    marker = f"{anchor} = {{\n"
    start = text.find(marker)
    if start == -1:
        raise SystemExit(f"anchor not found: {anchor}")
    i = start + len(marker)
    depth = 1
    while i < len(text) and depth > 0:
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
        i += 1
    if depth != 0:
        raise SystemExit(f"could not find closing brace for {anchor}")
    return start, i - 1

def insert_entry(text: str, anchor: str, entry: str) -> str:
    _start, end = find_attrset_bounds(text, anchor)
    return text[:end] + entry + text[end:]

def write_if_changed(path: Path, text: str) -> bool:
    before = path.read_text()
    if before == text:
        return False
    path.write_text(text)
    return True

secrets_flake = secrets_dir / "flake.nix"
home_flake = repo_root / "flake.nix"
secrets_text = secrets_flake.read_text()
home_text = home_flake.read_text()

secret_host_pattern = re.compile(
    r'"(?P<id>\d+)"\s*=\s*\{\s*hostName\s*=\s*"(?P<host>[^"]+)";\s*username\s*=\s*"(?P<user>[^"]+)";\s*\};',
    re.MULTILINE,
)
home_host_pattern = re.compile(
    r'"(?P<id>\d+)"\s*=\s*\{\s*system\s*=\s*"(?P<system>[^"]+)";\s*\};',
    re.MULTILINE,
)

secret_hosts = {
    match.group("id"): {
        "hostName": match.group("host"),
        "username": match.group("user"),
    }
    for match in secret_host_pattern.finditer(secrets_text)
}
home_hosts = {
    match.group("id"): {
        "system": match.group("system"),
    }
    for match in home_host_pattern.finditer(home_text)
}

existing_id = next(
    (
        host_id
        for host_id, identity in secret_hosts.items()
        if identity["hostName"] == host_name and identity["username"] == username
    ),
    None,
)

if host_id_override:
    host_id = host_id_override
    if existing_id is not None and existing_id != host_id:
        raise SystemExit(
            f"host {username}@{host_name} already exists as id {existing_id}, not {host_id}"
        )
    if host_id in secret_hosts:
        identity = secret_hosts[host_id]
        if identity["hostName"] != host_name or identity["username"] != username:
            raise SystemExit(
                f"host id {host_id} already belongs to {identity['username']}@{identity['hostName']}"
            )
else:
    if existing_id is not None:
        host_id = existing_id
    else:
        ids = [int(value) for value in secret_hosts.keys()]
        host_id = str(max(ids, default=0) + 1)

secrets_changed = False
home_changed = False
host_file_created = False

if host_id not in secret_hosts:
    secrets_text = insert_entry(
        secrets_text,
        "lib.my.hosts",
        f'''        "{host_id}" = {{
          hostName = "{host_name}";
          username = "{username}";
        }};\n''',
    )
    secrets_flake.write_text(secrets_text)
    secrets_changed = True

if host_id not in home_hosts:
    home_text = insert_entry(
        home_text,
        "hostSettings",
        f'''        "{host_id}" = {{
          system = "{system}";
        }};\n''',
    )
    home_flake.write_text(home_text)
    home_changed = True
elif home_hosts[host_id]["system"] != system:
    updated = re.sub(
        rf'("{host_id}"\s*=\s*\{{\s*system\s*=\s*")[^"]+(";\s*\}};)',
        rf'\g<1>{system}\2',
        home_text,
        count=1,
    )
    home_changed = write_if_changed(home_flake, updated)

host_file = repo_root / "home" / "hosts" / f"{host_id}.nix"
if not host_file.exists():
    host_file.write_text(host_module_template)
    host_file_created = True

print(f"HOST_ID={host_id}")
print(f"HOST_NAME={host_name}")
print(f"USERNAME={username}")
print(f"SYSTEM={system}")
print(f"SECRETS_CHANGED={'1' if secrets_changed else '0'}")
print(f"HOME_CHANGED={'1' if home_changed else '0'}")
print(f"HOST_FILE_CREATED={'1' if host_file_created else '0'}")
PY
)"

eval "$RESULT"

echo "resolved host: ${USERNAME}@${HOST_NAME} (id=${HOST_ID}, system=${SYSTEM})"

if [ "$SECRETS_CHANGED" = "1" ]; then
  git -C "$SECRETS_DIR" add flake.nix
  if [ -z "$SECRETS_COMMIT_MSG" ]; then
    SECRETS_COMMIT_MSG="Add ${HOST_NAME} host defaults"
  fi
  git -C "$SECRETS_DIR" commit -m "$SECRETS_COMMIT_MSG"
  git -C "$SECRETS_DIR" push
else
  echo "secrets repo: no host identity change"
fi

cd "$REPO_ROOT"
if [ "$FULL_FLAKE_UPDATE" = "1" ]; then
  nix flake update
else
  nix flake lock --update-input my_secrets
fi

if [ "$HOME_CHANGED" = "1" ] || [ "$HOST_FILE_CREATED" = "1" ] || [ -n "$(git status --porcelain)" ]; then
  git add flake.nix flake.lock "home/hosts/${HOST_ID}.nix"
  if [ -z "$HOME_COMMIT_MSG" ]; then
    HOME_COMMIT_MSG="Add ${HOST_NAME} home-manager host"
  fi
  git commit -m "$HOME_COMMIT_MSG"
  git push
else
  echo "home-manager repo: no changes"
fi
