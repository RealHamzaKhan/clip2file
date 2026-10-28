#!/bin/bash
# Clip2File: turn whatever you copied into a real .txt file, in one key press.
# 1. Reads the clipboard (pbpaste on macOS)
# 2. Saves it as a .txt file in ~/Downloads (name from the first line, or a timestamp)
# 3. Puts the FILE itself back on the clipboard, so Cmd+V in Gmail, WhatsApp Web,
#    Slack, a file picker, etc. attaches the file, not the raw text
# 4. Shows a notification with the file name
#
# Usage:
#   clip2file.sh              # .txt in ~/Downloads
#   clip2file.sh --md         # .md instead of .txt
#   clip2file.sh --reveal     # also open Finder on the new file
#   CLIP2FILE_DIR=/tmp/out clip2file.sh   # custom output folder
#
# Test hook (used on non-Mac machines): if pbpaste is missing, text is read from stdin.

set -euo pipefail

EXT="txt"
REVEAL=0
for arg in "$@"; do
  case "$arg" in
    --md) EXT="md" ;;
    --txt) EXT="txt" ;;
    --reveal) REVEAL=1 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

OUT_DIR="${CLIP2FILE_DIR:-$HOME/Downloads}"
mkdir -p "$OUT_DIR"

# --- 1. Get the clipboard text ---
if command -v pbpaste >/dev/null 2>&1; then
  TEXT="$(pbpaste)"
else
  TEXT="$(cat)"
fi

if [ -z "$(printf '%s' "$TEXT" | tr -d '[:space:]')" ]; then
  if command -v osascript >/dev/null 2>&1; then
    osascript -e 'display notification "Clipboard is empty. Copy some text first." with title "Clip2File"' >/dev/null 2>&1 || true
  fi
  echo "Clip2File: clipboard is empty." >&2
  exit 1
fi

# --- 2. Build a short, safe file name from the first line ---
FIRST_LINE="$(printf '%s' "$TEXT" | head -n 1)"
SLUG="$(printf '%s' "$FIRST_LINE" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//' \
  | cut -c 1-40 | sed -E 's/-+$//')"
STAMP="$(date +%Y-%m-%d_%H%M%S)"
if [ -n "$SLUG" ]; then
  BASE="$SLUG"
else
  BASE="clip-$STAMP"
fi

FILE="$OUT_DIR/$BASE.$EXT"
# Never overwrite an older clip. Add -2, -3, and so on.
N=2
while [ -e "$FILE" ]; do
  FILE="$OUT_DIR/$BASE-$N.$EXT"
  N=$((N + 1))
done

# --- 3. Save it ---
printf '%s' "$TEXT" > "$FILE"
# Add a final newline if the text does not end with one
if [ -n "$(tail -c 1 "$FILE")" ]; then
  printf '\n' >> "$FILE"
fi

# --- 4. Put the file itself on the clipboard (macOS only) ---
if command -v osascript >/dev/null 2>&1; then
  # Escape double quotes and backslashes for AppleScript
  ESCAPED="$(printf '%s' "$FILE" | sed 's/\\/\\\\/g; s/"/\\"/g')"
  osascript -e "set the clipboard to (POSIX file \"$ESCAPED\")" >/dev/null 2>&1 || true
  NAME_ONLY="$(basename "$FILE")"
  osascript -e "display notification \"Saved $NAME_ONLY. Press Cmd+V to attach it.\" with title \"Clip2File\"" >/dev/null 2>&1 || true
  if [ "$REVEAL" -eq 1 ]; then
    open -R "$FILE" >/dev/null 2>&1 || true
  fi
fi

echo "$FILE"
