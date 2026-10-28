# Clip2File

Copy text. Press one shortcut. Get a real `.txt` file, ready to attach.

No more: copy, open a text editor, paste, save as, find the file, attach it.

## How it works

1. You copy any text, anywhere (`Cmd+C`)
2. You press one shortcut, for example `Control + Option + T`
3. Clip2File saves the text as a `.txt` file in your Downloads folder
   - The file name comes from the first line of your text
   - Example: first line "Meeting notes for Tuesday" becomes `meeting-notes-for-tuesday.txt`
   - Empty or symbol-only first lines fall back to a timestamp name like `clip-2026-10-28_223015.txt`
   - It never overwrites an old file. It adds `-2`, `-3`, and so on
4. Clip2File puts the **file itself** on your clipboard
5. You go to Gmail, WhatsApp Web, Slack, Google Drive, any upload box, and press `Cmd+V`
   - The file attaches. That is the whole trick most tools miss.

You also get a small notification with the file name.

## Install (macOS)

```bash
chmod +x install.sh clip2file.sh
./install.sh
```

The installer copies the script to `~/.local/bin/clip2file` and prints the
one-time steps to bind it to a keyboard shortcut in Apple's Shortcuts app
(Shortcuts, new shortcut, Run Shell Script, one line, Add Keyboard Shortcut).
That part takes about 2 minutes and you only do it once.

### No-install test

Copy some text, then in Terminal:

```bash
pbpaste > ~/Downloads/test.txt
```

That is the core idea in one line, built into every Mac. Clip2File is that
line, plus a good file name, plus the file back on your clipboard, plus a shortcut.

### Raycast users

Run `install.sh` first, then add the `raycast/` folder under Raycast Settings,
Extensions, Script Commands, and set a hotkey there instead.

## Options

```bash
clip2file            # .txt file (default)
clip2file --md       # .md file instead
clip2file --reveal   # also show the new file in Finder
CLIP2FILE_DIR=~/Desktop clip2file   # save somewhere else
```

## Why not use what macOS already has?

- **Text Clippings**: drag selected text to the Desktop and macOS makes a file.
  But it is a `.textclipping` file. Other people and most websites cannot open it.
  It is not a plain `.txt` you can attach and send.
- **TextEdit**: works, but it is 6 or 7 steps, every single time.
- **Terminal `pbpaste`**: works, but you have to open Terminal and type a file name.
- **Clipboard managers** (Maccy, Raycast clipboard, Paste): great for history.
  None of them turn a copy into an attachable file in one press.

So the gap is real, and it is small. That is what makes it a good open source tool:
one job, done in one press, no account, no network, no tracking.

## Roadmap for v2 (native app)

- Tiny menu bar app in Swift, no Terminal step at all
- Choose the format each time: `.txt`, `.md`, `.csv`, `.json`
- If the clipboard holds an image, save a `.png` instead
- If the text looks like code, keep the right extension
- Setting for the output folder
- Homebrew install: `brew install clip2file`

## Privacy

Everything runs on your Mac. Clip2File never sends your clipboard anywhere.
Your clipboard can hold passwords and private text, so this matters.

## License

MIT. See `LICENSE`.
