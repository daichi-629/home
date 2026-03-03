#!/bin/bash
# Send notifications via OSC escape sequences to active terminals.
# Keep it fast and non-blocking; never hang on slow tty writes.

TITLE="${1:-Claude Code}"
MESSAGE="${2:-Task completed}"

LOG_DIR="$HOME/.claude/hooks"
LOG_FILE="$LOG_DIR/notification.log"
LAST_FILE="$LOG_DIR/notification.last"
mkdir -p "$LOG_DIR"
WRITE_TIMEOUT_SEC="${WRITE_TIMEOUT_SEC:-0.2}"
DEDUPE_WINDOW_SEC="${DEDUPE_WINDOW_SEC:-3}"

# Read hook input JSON from stdin
if [ -t 0 ]; then
    HOOK_INPUT=""
else
    HOOK_INPUT=$(cat)
fi

# Extract project information (keep it minimal/fast)
PROJECT_NAME=""

if [ -n "$HOOK_INPUT" ] && command -v jq >/dev/null 2>&1; then
    # Extract project name from cwd
    CWD=$(echo "$HOOK_INPUT" | jq -r '.cwd // empty' 2>/dev/null)
    if [ -n "$CWD" ]; then
        PROJECT_NAME=$(basename "$CWD")
    fi

fi

# Build enhanced message
ENHANCED_MESSAGE="$MESSAGE"
if [ -n "$PROJECT_NAME" ]; then
    ENHANCED_MESSAGE="[$PROJECT_NAME] $ENHANCED_MESSAGE"
fi

# De-duplicate identical notifications fired in quick succession
DEDUPLE_KEY_MESSAGE="$ENHANCED_MESSAGE"
case "$MESSAGE" in
    "User question detected, awaiting your input"|"Permission request detected, awaiting your approval")
        DEDUPLE_KEY_MESSAGE="[interactive-attention]"
        ;;
esac

PAYLOAD_HASH=""
if command -v sha256sum >/dev/null 2>&1; then
    PAYLOAD_HASH=$(printf '%s|%s' "$TITLE" "$DEDUPLE_KEY_MESSAGE" | sha256sum | awk '{print $1}')
elif command -v shasum >/dev/null 2>&1; then
    PAYLOAD_HASH=$(printf '%s|%s' "$TITLE" "$DEDUPLE_KEY_MESSAGE" | shasum -a 256 | awk '{print $1}')
fi

if [ -n "$PAYLOAD_HASH" ] && [ -f "$LAST_FILE" ]; then
    LAST_TS=""
    LAST_HASH=""
    read -r LAST_TS LAST_HASH < "$LAST_FILE" || true
    NOW_TS=$(date +%s)
    if [ -n "$LAST_TS" ] && [ -n "$LAST_HASH" ]; then
        if [ "$LAST_HASH" = "$PAYLOAD_HASH" ] && [ $((NOW_TS - LAST_TS)) -lt "$DEDUPE_WINDOW_SEC" ]; then
            exit 0
        fi
    fi
fi

if [ -n "$PAYLOAD_HASH" ]; then
    NOW_TS=$(date +%s)
    printf '%s %s\n' "$NOW_TS" "$PAYLOAD_HASH" > "$LAST_FILE"
fi

# Log notification
{
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Notification sent:"
    echo "  Project: ${PROJECT_NAME:-N/A}"
    echo "  Message: $MESSAGE"
} >> "$LOG_FILE"

build_osc_payload() {
    case "${TERM:-}:${TERM_PROGRAM:-}" in
        xterm-kitty*:*|*:kitty|xterm-kitty*)
            # kitty handles OSC 9 notifications; sending both duplicates them.
            printf '\033]9;%s: %s\007' "$TITLE" "$ENHANCED_MESSAGE"
            ;;
        *:WezTerm|wezterm:*|xterm-wezterm*)
            # WezTerm also shows duplicate notifications if both sequences are sent.
            printf '\033]9;%s: %s\007' "$TITLE" "$ENHANCED_MESSAGE"
            ;;
        *)
            printf '\033]777;notify;%s;%s\007' "$TITLE" "$ENHANCED_MESSAGE"
            ;;
    esac
}

OSC_PAYLOAD=$(build_osc_payload)

write_osc() {
    local pts="$1"
    if command -v timeout >/dev/null 2>&1; then
        timeout "$WRITE_TIMEOUT_SEC" sh -c 'printf "%s" "$1" > "$2"' sh "$OSC_PAYLOAD" "$pts" 2>/dev/null || true
        return
    fi
    if command -v perl >/dev/null 2>&1; then
        WRITE_TIMEOUT_SEC="$WRITE_TIMEOUT_SEC" OSC_PAYLOAD="$OSC_PAYLOAD" perl -e '
            alarm $ENV{WRITE_TIMEOUT_SEC};
            open my $fh, ">", $ARGV[0] or exit;
            print $fh $ENV{OSC_PAYLOAD};
        ' "$pts" 2>/dev/null || true
        return
    fi
    # Last resort: background best-effort write.
    (printf "%s" "$OSC_PAYLOAD" > "$pts" 2>/dev/null) &
}

resolve_target_tty() {
    local candidate=""
    local pid=""
    local tty_name=""

    candidate=$(tty 2>/dev/null || true)
    if [ -n "$candidate" ] && [ "$candidate" != "not a tty" ] && [ -w "$candidate" ] 2>/dev/null; then
        printf '%s\n' "$candidate"
        return 0
    fi

    pid=$$
    while [ -n "$pid" ] && [ "$pid" -gt 1 ] 2>/dev/null; do
        tty_name=$(ps -o tty= -p "$pid" 2>/dev/null | tr -d '[:space:]')
        if [ -n "$tty_name" ] && [ "$tty_name" != "?" ] && [ "$tty_name" != "notty" ]; then
            candidate="/dev/$tty_name"
            if [ -w "$candidate" ] 2>/dev/null; then
                printf '%s\n' "$candidate"
                return 0
            fi
        fi
        pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d '[:space:]')
    done

    return 1
}

# Send only to the current terminal.
CURRENT_TTY=$(resolve_target_tty || true)
if [ -n "$CURRENT_TTY" ]; then
    write_osc "$CURRENT_TTY"
fi
exit 0
