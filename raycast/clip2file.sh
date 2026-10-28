#!/bin/bash
# Raycast Script Command version. If you use Raycast:
# add this folder in Raycast Settings, Extensions, Script Commands, then set a hotkey there.

# @raycast.schemaVersion 1
# @raycast.title Clip2File: Clipboard to .txt File
# @raycast.mode silent
# @raycast.packageName Clip2File
# @raycast.icon 📎
# @raycast.description Saves clipboard text as a .txt file in Downloads and copies the file back to the clipboard, ready to attach.

"$HOME/.local/bin/clip2file"
