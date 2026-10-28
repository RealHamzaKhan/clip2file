#!/bin/bash
# Clip2File installer for macOS. Safe and simple:
# - copies clip2file.sh to ~/.local/bin/clip2file
# - makes it executable
# - prints the 4 steps to give it a keyboard shortcut in the Shortcuts app
set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
DEST_DIR="$HOME/.local/bin"
mkdir -p "$DEST_DIR"
cp "$SRC_DIR/clip2file.sh" "$DEST_DIR/clip2file"
chmod +x "$DEST_DIR/clip2file"

echo ""
echo "Installed: $DEST_DIR/clip2file"
echo ""
echo "Test it now:"
echo "  1. Copy any text (Cmd+C)"
echo "  2. Open Terminal and run:  ~/.local/bin/clip2file"
echo "  3. A .txt file appears in your Downloads. The file is on your clipboard."
echo "     Go to Gmail or WhatsApp Web and press Cmd+V. It attaches the file."
echo ""
echo "Now give it a keyboard shortcut (2 minutes, one time only):"
echo "  1. Open the Shortcuts app on your Mac"
echo "  2. Click + to make a new shortcut. Name it: Clip2File"
echo "  3. Search for the action 'Run Shell Script' and add it"
echo "  4. Paste this one line as the script:  \$HOME/.local/bin/clip2file"
echo "  5. Click the (i) info button on the right, then 'Add Keyboard Shortcut'"
echo "  6. Press your shortcut. Good pick:  Control + Option + T"
echo ""
echo "Done. From now on: copy text, press the shortcut, paste anywhere to attach."
echo ""
