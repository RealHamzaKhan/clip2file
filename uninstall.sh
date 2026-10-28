#!/bin/bash
# Clip2File uninstaller for macOS. Removes everything install.sh created:
# - the clip2file command
# - the Clip2File Quick Action
# - its keyboard shortcut entry in the Services preferences
set -euo pipefail

if [ "$(uname)" != "Darwin" ]; then
  echo "Clip2File is a macOS tool. This uninstaller needs a Mac." >&2
  exit 1
fi

SERVICE_KEY="(null) - Clip2File - runWorkflowAsService"
PBS_PLIST="$HOME/Library/Preferences/pbs.plist"
PLIST_BUDDY=/usr/libexec/PlistBuddy

rm -f "$HOME/.local/bin/clip2file"
rm -rf "$HOME/Library/Services/Clip2File.workflow"
if [ -f "$PBS_PLIST" ]; then
  "$PLIST_BUDDY" -c "Delete :NSServicesStatus:\"$SERVICE_KEY\"" "$PBS_PLIST" 2>/dev/null || true
fi
/System/Library/CoreServices/pbs -flush 2>/dev/null || true

echo "Clip2File removed: command, Quick Action, and shortcut are gone."
echo "Your .txt files in Downloads were not touched."
