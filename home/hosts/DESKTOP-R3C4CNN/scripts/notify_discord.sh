#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
使い方:
  discord_webhook.sh -u <webhook_url> -m <message> [options]

必須:
  -u  Discord Webhook URL
  -m  送信メッセージ（content）

任意:
  -n  表示名（username）
  -a  アイコンURL（avatar_url）
  -t  埋め込みのタイトル（embed.title）
  -d  埋め込みの説明（embed.description）
  -l  埋め込みのリンク（embed.url）
  -c  埋め込みの色（#RRGGBB または RRGGBB）
  -f  添付ファイル（パス）

例:
  ./discord_webhook.sh -u "https://discord.com/api/webhooks/..." -m "hello"
  ./discord_webhook.sh -u "$DISCORD_WEBHOOK_URL" -m "deploy" -t "通知" -d "完了" -c "#2ecc71"
  ./discord_webhook.sh -u "$DISCORD_WEBHOOK_URL" -m "ログ" -f ./app.log
USAGE
}

WEBHOOK_URL="${DISCORD_WEBHOOK_URL:-}"
MESSAGE=""
USERNAME=""
AVATAR_URL=""
EMBED_TITLE=""
EMBED_DESC=""
EMBED_URL=""
EMBED_COLOR=""
FILE_PATH=""

while getopts "u:m:n:a:t:d:l:c:f:h" opt; do
  case "$opt" in
    u) WEBHOOK_URL="$OPTARG" ;;
    m) MESSAGE="$OPTARG" ;;
    n) USERNAME="$OPTARG" ;;
    a) AVATAR_URL="$OPTARG" ;;
    t) EMBED_TITLE="$OPTARG" ;;
    d) EMBED_DESC="$OPTARG" ;;
    l) EMBED_URL="$OPTARG" ;;
    c) EMBED_COLOR="$OPTARG" ;;
    f) FILE_PATH="$OPTARG" ;;
    h) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done


if [[ -z "${WEBHOOK_URL}" || -z "${MESSAGE}" ]]; then
  usage
  exit 1
fi

PAYLOAD="$(
MESSAGE="$MESSAGE" \
USERNAME="$USERNAME" \
AVATAR_URL="$AVATAR_URL" \
EMBED_TITLE="$EMBED_TITLE" \
EMBED_DESC="$EMBED_DESC" \
EMBED_URL="$EMBED_URL" \
EMBED_COLOR="$EMBED_COLOR" \
python3 - <<'PY'
import json, os, re, sys

message = os.environ.get("MESSAGE", "")
username = os.environ.get("USERNAME", "")
avatar_url = os.environ.get("AVATAR_URL", "")
embed_title = os.environ.get("EMBED_TITLE", "")
embed_desc = os.environ.get("EMBED_DESC", "")
embed_url = os.environ.get("EMBED_URL", "")
embed_color = os.environ.get("EMBED_COLOR", "")

payload = {"content": message}

if username:
  payload["username"] = username
if avatar_url:
  payload["avatar_url"] = avatar_url

embeds = []
if any([embed_title, embed_desc, embed_url, embed_color]):
  e = {}
  if embed_title:
    e["title"] = embed_title
  if embed_desc:
    e["description"] = embed_desc
  if embed_url:
    e["url"] = embed_url
  if embed_color:
    s = embed_color.strip()
    if s.startswith("#"):
      s = s[1:]
    if not re.fullmatch(r"[0-9a-fA-F]{6}", s or ""):
      print("embed color は #RRGGBB か RRGGBB で指定してください", file=sys.stderr)
      sys.exit(2)
    e["color"] = int(s, 16)
  embeds.append(e)

if embeds:
  payload["embeds"] = embeds

print(json.dumps(payload, ensure_ascii=False))
PY
)" || exit $?

if [[ -n "${FILE_PATH}" ]]; then
  if [[ ! -f "${FILE_PATH}" ]]; then
    echo "ファイルが見つかりません: ${FILE_PATH}" >&2
    exit 1
  fi

  curl -sS -X POST \
    -F "payload_json=${PAYLOAD}" \
    -F "file=@${FILE_PATH}" \
    "${WEBHOOK_URL}" >/dev/null
else
  curl -sS -X POST \
    -H "Content-Type: application/json" \
    -d "${PAYLOAD}" \
    "${WEBHOOK_URL}" >/dev/null
fi
