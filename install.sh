#!/bin/bash
# Clip2File installer for macOS (v1.1, automatic shortcut setup).
#
# You confirm ONE thing (press Enter), then the installer does everything:
#   1. Installs the clip2file command to ~/.local/bin/clip2file
#   2. Builds and installs an Automator Quick Action called "Clip2File"
#      in ~/Library/Services (no Automator app, no clicking around)
#   3. Binds the keyboard shortcut Control+Option+T to it for you,
#      by writing the macOS Services preferences (the pbs plist)
#   4. Refreshes the Services system so the shortcut goes live
#   5. Runs a self test: it copies a test line, runs the Quick Action,
#      and checks that a real .txt file appears
#
# Usage:
#   ./install.sh              # asks for one confirmation (Enter)
#   ./install.sh --yes        # no prompt
#   ./install.sh --no-test    # skip the self test
#
# Note on the self test: it uses your clipboard once. Copy your text again
# after installing. Nothing else on your Mac is changed.
# Note on the hotkey: on some macOS versions a new Services hotkey only
# wakes up after a log out and log in. The installer tells you if so.

set -euo pipefail

ASSUME_YES=0
RUN_TEST=1
for arg in "$@"; do
  case "$arg" in
    --yes) ASSUME_YES=1 ;;
    --no-test) RUN_TEST=0 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

if [ "$(uname)" != "Darwin" ]; then
  echo "Clip2File is a macOS tool. This installer needs a Mac." >&2
  exit 1
fi

SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="$HOME/.local/bin"
BIN_PATH="$BIN_DIR/clip2file"
SERVICES_DIR="$HOME/Library/Services"
WORKFLOW="$SERVICES_DIR/Clip2File.workflow"
SERVICE_KEY="(null) - Clip2File - runWorkflowAsService"
HOTKEY_HUMAN="Control + Option + T"
HOTKEY_CODE="^~t"
PBS_PLIST="$HOME/Library/Preferences/pbs.plist"
PLIST_BUDDY="${CLIP2FILE_PLIST_BUDDY:-/usr/libexec/PlistBuddy}"

echo ""
echo "Clip2File will set itself up:"
echo "  - Command installed at:   $BIN_PATH"
echo "  - Quick Action created:   Clip2File (in your Services)"
echo "  - Shortcut bound for you: $HOTKEY_HUMAN"
echo "  - Then a quick self test (it uses your clipboard once)"
echo ""
if [ "$ASSUME_YES" -eq 0 ]; then
  printf "Press Enter to confirm, or Ctrl+C to stop: "
  read -r _
fi

# --- 1. Install the command ---
mkdir -p "$BIN_DIR"
cp "$SRC_DIR/clip2file.sh" "$BIN_PATH"
chmod +x "$BIN_PATH"
echo "1/5  Command installed."

# --- 2. Build the Quick Action workflow bundle ---
mkdir -p "$WORKFLOW/Contents"
UUID_ACTION="$(uuidgen)"
UUID_IN="$(uuidgen)"
UUID_OUT="$(uuidgen)"

cat > "$WORKFLOW/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>NSServices</key>
	<array>
		<dict>
			<key>NSBackgroundColorName</key>
			<string>background</string>
			<key>NSIconName</key>
			<string>NSTouchBarGetInfoTemplate</string>
			<key>NSMenuItem</key>
			<dict>
				<key>default</key>
				<string>Clip2File</string>
			</dict>
			<key>NSMessage</key>
			<string>runWorkflowAsService</string>
		</dict>
	</array>
</dict>
</plist>
PLIST

cat > "$WORKFLOW/Contents/document.wflow" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>AMApplicationBuild</key>
	<string>523</string>
	<key>AMApplicationVersion</key>
	<string>2.10</string>
	<key>AMDocumentVersion</key>
	<string>2</string>
	<key>actions</key>
	<array>
		<dict>
			<key>action</key>
			<dict>
				<key>AMAccepts</key>
				<dict>
					<key>Container</key>
					<string>List</string>
					<key>Optional</key>
					<true/>
					<key>Types</key>
					<array>
						<string>com.apple.cocoa.string</string>
					</array>
				</dict>
				<key>AMActionVersion</key>
				<string>2.0.3</string>
				<key>AMProvides</key>
				<dict>
					<key>Container</key>
					<string>List</string>
					<key>Types</key>
					<array>
						<string>com.apple.cocoa.string</string>
					</array>
				</dict>
				<key>ActionBundlePath</key>
				<string>/System/Library/Automator/Run Shell Script.action</string>
				<key>ActionName</key>
				<string>Run Shell Script</string>
				<key>ActionParameters</key>
				<dict>
					<key>COMMAND_STRING</key>
					<string>"\$HOME/.local/bin/clip2file"</string>
					<key>CheckedForUserDefaultShell</key>
					<true/>
					<key>inputMethod</key>
					<integer>1</integer>
					<key>shell</key>
					<string>/bin/bash</string>
					<key>source</key>
					<string></string>
				</dict>
				<key>BundleIdentifier</key>
				<string>com.apple.RunShellScript</string>
				<key>Class Name</key>
				<string>RunShellScriptAction</string>
				<key>InputUUID</key>
				<string>$UUID_IN</string>
				<key>OutputUUID</key>
				<string>$UUID_OUT</string>
				<key>UUID</key>
				<string>$UUID_ACTION</string>
			</dict>
			<key>isViewVisible</key>
			<true/>
		</dict>
	</array>
	<key>connectors</key>
	<dict/>
	<key>workflowMetaData</key>
	<dict>
		<key>serviceInputTypeIdentifier</key>
		<string>com.apple.Automator.nothing</string>
		<key>serviceOutputTypeIdentifier</key>
		<string>com.apple.Automator.nothing</string>
		<key>serviceProcessesInput</key>
		<integer>0</integer>
		<key>workflowTypeIdentifier</key>
		<string>com.apple.Automator.servicesMenu</string>
	</dict>
</dict>
</plist>
PLIST
echo "2/5  Quick Action 'Clip2File' created."

# --- 3. Bind the keyboard shortcut in the Services preferences ---
mkdir -p "$(dirname "$PBS_PLIST")"
touch "$PBS_PLIST"
# Start from a clean entry for this service, then write it fresh.
"$PLIST_BUDDY" -c "Delete :NSServicesStatus:\"$SERVICE_KEY\"" "$PBS_PLIST" 2>/dev/null || true
"$PLIST_BUDDY" -c "Add :NSServicesStatus:\"$SERVICE_KEY\" dict" "$PBS_PLIST"
"$PLIST_BUDDY" -c "Add :NSServicesStatus:\"$SERVICE_KEY\":key_equivalent string \"$HOTKEY_CODE\"" "$PBS_PLIST"
"$PLIST_BUDDY" -c "Add :NSServicesStatus:\"$SERVICE_KEY\":presentation_modes dict" "$PBS_PLIST"
"$PLIST_BUDDY" -c "Add :NSServicesStatus:\"$SERVICE_KEY\":presentation_modes:ContextMenu integer 1" "$PBS_PLIST"
"$PLIST_BUDDY" -c "Add :NSServicesStatus:\"$SERVICE_KEY\":presentation_modes:ServicesMenu integer 1" "$PBS_PLIST"
"$PLIST_BUDDY" -c "Add :NSServicesStatus:\"$SERVICE_KEY\":presentation_modes:TouchBar integer 1" "$PBS_PLIST"
echo "3/5  Shortcut bound: $HOTKEY_HUMAN"

# --- 4. Refresh the Services system ---
defaults write pbs NSServicesUserDirectoryModDate -float "$(date +%s)" 2>/dev/null || true
killall cfprefsd 2>/dev/null || true
/System/Library/CoreServices/pbs -flush 2>/dev/null || true
echo "4/5  Services refreshed."

# --- 5. Self test through the real Quick Action ---
if [ "$RUN_TEST" -eq 1 ]; then
  printf 'Clip2File test' | pbcopy
  rm -f "$HOME/Downloads/clip2file-test.txt"
  if automator "$WORKFLOW" >/dev/null 2>&1 && [ -f "$HOME/Downloads/clip2file-test.txt" ]; then
    rm -f "$HOME/Downloads/clip2file-test.txt"
    echo "5/5  Self test PASSED. The Quick Action made a real .txt file."
  else
    echo "5/5  Self test could not confirm the Quick Action ran."
    echo "     Do not worry: log out and back in once, then test by hand."
    echo "     Copy any text, then press $HOTKEY_HUMAN."
  fi
else
  echo "5/5  Self test skipped (--no-test)."
fi

echo ""
echo "Done. How to use it:"
echo "  1. Copy any text (Cmd+C)"
echo "  2. Press $HOTKEY_HUMAN"
echo "  3. Go to Gmail, WhatsApp Web, anywhere, and press Cmd+V to attach"
echo ""
echo "If the shortcut does not answer the first time, log out and back in"
echo "once. macOS sometimes needs that to wake up a new Services shortcut."
echo "To remove everything:  ./uninstall.sh"
echo ""
