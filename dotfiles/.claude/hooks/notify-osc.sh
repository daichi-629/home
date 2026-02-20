#!/bin/bash
# Send notifications via OSC escape sequences to active terminals

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

# Extract project and task information
PROJECT_NAME=""
TASK_SUMMARY=""

if [ -n "$HOOK_INPUT" ] && command -v jq >/dev/null 2>&1; then
    # Extract project name from cwd
    CWD=$(echo "$HOOK_INPUT" | jq -r '.cwd // empty' 2>/dev/null)
    if [ -n "$CWD" ]; then
        PROJECT_NAME=$(basename "$CWD")
    fi

    # Extract transcript path
    TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)

    # Try to get task description from session file
    if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
        # Method 1: Find first queue-operation enqueue
        TASK_SUMMARY=$(cat "$TRANSCRIPT_PATH" 2>/dev/null | \
            jq -r 'select(.type == "queue-operation" and .operation == "enqueue") |
                   .content[].text // empty' 2>/dev/null | \
            while IFS= read -r line; do
                # Skip system messages
                if [[ ! "$line" =~ ^\<(ide_opened_file|system-reminder|command-) ]]; then
                    echo "$line"
                    break
                fi
            done | head -c 100)

        # Method 2: Fallback to first user message
        if [ -z "$TASK_SUMMARY" ]; then
            TASK_SUMMARY=$(cat "$TRANSCRIPT_PATH" 2>/dev/null | \
                jq -r 'select(.type == "user") |
                       select(.isMeta == null or .isMeta == false) |
                       if .message.content | type == "array"
                       then .message.content[].text // empty
                       else .message.content end' 2>/dev/null | \
                while IFS= read -r line; do
                    if [ -n "$line" ] && [ "$line" != "null" ] && \
                       [[ ! "$line" =~ ^\<(ide_opened_file|system-reminder|command-) ]]; then
                        echo "$line"
                        break
                    fi
                done | head -c 100)
        fi
    fi
fi

# Build enhanced message
ENHANCED_MESSAGE="$MESSAGE"
if [ -n "$PROJECT_NAME" ]; then
    ENHANCED_MESSAGE="[$PROJECT_NAME] $ENHANCED_MESSAGE"
fi
if [ -n "$TASK_SUMMARY" ]; then
    ENHANCED_MESSAGE="$ENHANCED_MESSAGE - Task: $TASK_SUMMARY"
fi

# De-duplicate identical notifications fired in quick succession
PAYLOAD_HASH=""
if command -v sha256sum >/dev/null 2>&1; then
    PAYLOAD_HASH=$(printf '%s|%s' "$TITLE" "$ENHANCED_MESSAGE" | sha256sum | awk '{print $1}')
elif command -v shasum >/dev/null 2>&1; then
    PAYLOAD_HASH=$(printf '%s|%s' "$TITLE" "$ENHANCED_MESSAGE" | shasum -a 256 | awk '{print $1}')
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
    echo "  Task: ${TASK_SUMMARY:-N/A}"
} >> "$LOG_FILE"

# Send to all writable pts devices
for pts in /dev/pts/*; do
    if [ "$pts" = "/dev/pts/ptmx" ]; then
        continue
    fi

    if [ -w "$pts" ] 2>/dev/null; then
        {
            printf '\033]777;notify;%s;%s\007' "$TITLE" "$ENHANCED_MESSAGE"
            printf '\033]9;%s: %s\007' "$TITLE" "$ENHANCED_MESSAGE"
            printf '\a'
        } > "$pts" 2>/dev/null
    fi
done

exit 0

