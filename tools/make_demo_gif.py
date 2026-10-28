#!/usr/bin/env python3
"""Build assets/demo.gif for Clip2File.

An animated walk-through in 4 scenes:
  A. Title card
  B. Copy some text (Cmd+C), with the selection sweep
  C. Terminal: press Ctrl+Option+T, run clip2file, file saved, notification
  D. Gmail compose: Cmd+V and the .txt file attaches

The file name in the demo (meeting-notes-for-tuesday.txt) is the real output
of clip2file.sh on the sample clipboard text used here.

Run:  python3 tools/make_demo_gif.py
Needs: Pillow (pip install pillow) and DejaVu fonts.
"""
from PIL import Image, ImageDraw, ImageFont

W, H = 1040, 640
FPS = 10
BG = (11, 14, 20)
PANEL = (22, 27, 34)
PANEL2 = (28, 34, 44)
BORDER = (48, 54, 61)
TEXT = (230, 237, 243)
DIM = (139, 148, 158)
GREEN = (63, 185, 80)
ORANGE = (249, 115, 22)
BLUE = (31, 111, 235)
WHITE = (255, 255, 255)

SANS = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
SANSB = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
MONO = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
MONOB = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf"


def font(path, size):
    return ImageFont.truetype(path, size)


def rr(d, box, r, fill=None, outline=None, width=1):
    d.rounded_rectangle(box, radius=r, fill=fill, outline=outline, width=width)


def centered(d, cx, y, s, fnt, fill):
    w = d.textlength(s, font=fnt)
    d.text((cx - w / 2, y), s, font=fnt, fill=fill)
    return w


def keycap(d, x, y, label, fnt, pressed=False, scale=1.0):
    pad_x, h = int(16 * scale), int(46 * scale)
    w = d.textlength(label, font=fnt) + pad_x * 2
    dy = 3 if pressed else 0
    rr(d, (x, y + dy, x + w, y + dy + h), int(10 * scale),
       fill=(33, 38, 45) if not pressed else (52, 60, 72),
       outline=(99, 110, 123), width=2)
    tw = d.textlength(label, font=fnt)
    d.text((x + (w - tw) / 2, y + dy + h / 2 - fnt.size / 2 - 2), label, font=fnt, fill=TEXT)
    return w


def key_row(d, cx, y, labels, fnt, press_index=-1):
    gap = 10
    widths = [d.textlength(t, font=fnt) + 32 for t in labels]
    total = sum(widths) + gap * (len(labels) - 1)
    x = cx - total / 2
    for i, (t, w) in enumerate(zip(labels, widths)):
        keycap(d, x, y, t, fnt, pressed=(i == press_index))
        x += w + gap


def window_chrome(d, box, title):
    x0, y0, x1, y1 = box
    rr(d, box, 14, fill=PANEL, outline=BORDER, width=2)
    d.rounded_rectangle((x0, y0, x1, y0 + 52), radius=14, fill=PANEL2)
    d.rectangle((x0, y0 + 38, x1, y0 + 52), fill=PANEL2)
    for i, c in enumerate(((255, 95, 86), (255, 189, 46), (39, 201, 63))):
        cx = x0 + 28 + i * 26
        d.ellipse((cx - 8, y0 + 18, cx + 8, y0 + 34), fill=c)
    f = font(SANS, 20)
    tw = d.textlength(title, font=f)
    d.text(((x0 + x1) / 2 - tw / 2, y0 + 14), title, font=f, fill=DIM)


def caption(d, s, color=TEXT):
    f = font(SANSB, 30)
    tw = d.textlength(s, font=f)
    rr(d, (W / 2 - tw / 2 - 22, H - 78, W / 2 + tw / 2 + 22, H - 24), 27,
       fill=(20, 24, 32), outline=BORDER, width=1)
    d.text((W / 2 - tw / 2, H - 66), s, font=f, fill=color)


def scene_title(d, t):
    f_big = font(SANSB, 92)
    centered(d, W / 2, 215, "Clip2File", f_big, WHITE)
    w = d.textlength("Clip2File", font=f_big)
    d.rectangle((W / 2 - w / 2 + 4, 322, W / 2 + w / 2 - 4, 330), fill=ORANGE)
    centered(d, W / 2, 360, "Copy text. Press one shortcut. Get a .txt file.",
             font(SANS, 31), DIM)


NOTES = ["Meeting notes for Tuesday",
         "We agreed to ship on Friday.",
         "Budget is approved."]


def scene_copy(d, t):
    box = (150, 90, 890, 430)
    window_chrome(d, box, "Notes")
    f = font(SANS, 28)
    # selection sweep: progress 0..1 over local time 0.2..1.5
    p = max(0.0, min(1.0, (t - 0.2) / 1.3))
    total_w = 640
    for i, line in enumerate(NOTES):
        y = 185 + i * 62
        lw = d.textlength(line, font=f)
        if p > 0:
            covered = max(0.0, min(1.0, p * 3 - i))
            if covered > 0:
                d.rectangle((196, y - 4, 196 + lw * covered + 10, y + 38), fill=BLUE)
        d.text((200, y), line, font=f, fill=TEXT)
    if t > 1.2:
        key_row(d, W / 2, 470, ["Cmd", "C"], font(SANSB, 24),
                press_index=1 if 1.2 < t < 1.7 else -1)
    caption(d, "1. Copy any text")


def scene_terminal(d, t):
    box = (90, 70, 950, 470)
    window_chrome(d, box, "Terminal")
    fm = font(MONO, 25)
    fmb = font(MONOB, 25)
    x, y = 130, 165
    d.text((x, y), "# you copied text. now run:", font=fm, fill=DIM)
    if t < 1.5:
        labels = ["Ctrl", "Option", "T"]
        idx = int(t / 0.45)
        key_row(d, W / 2, 250, labels, font(SANSB, 24),
                press_index=min(idx, 2) if t > 0.2 else -1)
        d.text((x, 360), "(the shortcut runs the command for you)", font=fm, fill=DIM)
    else:
        cmd = "clip2file"
        typed = cmd if t > 2.6 else cmd[:max(0, int((t - 1.5) * 9))]
        d.text((x, y + 70), "$ ", font=fmb, fill=GREEN)
        d.text((x + d.textlength("$ ", font=fmb), y + 70), typed, font=fm, fill=TEXT)
        if t > 2.6 and int(t * 2) % 2 == 0:
            cx = x + d.textlength("$ " + typed, font=fm)
            d.rectangle((cx + 4, y + 74, cx + 18, y + 100), fill=TEXT)
        if t > 3.0:
            d.text((x, y + 135), "/Users/you/Downloads/meeting-notes-for-tuesday.txt",
                   font=fm, fill=GREEN)
        if t > 3.5:
            d.text((x, y + 200), "Saved. The file is on your clipboard now.",
                   font=fm, fill=DIM)
    if t > 3.4:
        # notification pill, top right
        msg = "Clip2File: saved meeting-notes-for-tuesday.txt"
        f = font(SANS, 19)
        tw = d.textlength(msg, font=f)
        rr(d, (950 - tw - 46, 86, 936, 134), 12, fill=(33, 38, 45), outline=BORDER, width=1)
        d.text((950 - tw - 24, 100), msg, font=f, fill=TEXT)
    caption(d, "2. Press Control + Option + T")


def scene_attach(d, t):
    box = (170, 70, 870, 440)
    window_chrome(d, box, "New Message")
    f = font(SANS, 24)
    d.text((205, 165), "To:  team@example.com", font=f, fill=DIM)
    d.line((205, 205, 835, 205), fill=BORDER, width=2)
    d.text((205, 225), "Subject:  Meeting notes", font=f, fill=DIM)
    d.line((205, 265, 835, 265), fill=BORDER, width=2)
    if t > 0.9:
        key_row(d, W / 2, 300, ["Cmd", "V"], font(SANSB, 22),
                press_index=1 if 0.9 < t < 1.4 else -1)
    if t > 1.6:
        # attachment chip pops in with a small scale bounce
        s = min(1.0, (t - 1.6) / 0.35)
        chip_w, chip_h = int(430 * s), int(58 * s)
        x0, y0 = 205, 380
        if s > 0.3:
            rr(d, (x0, y0, x0 + chip_w, y0 + chip_h), 12, fill=(33, 38, 45),
               outline=(99, 110, 123), width=2)
            if s > 0.7:
                # little document icon
                d.rectangle((x0 + 16, y0 + 12, x0 + 36, y0 + 46), outline=ORANGE, width=3)
                d.text((x0 + 48, y0 + 15), "meeting-notes-for-tuesday.txt",
                       font=font(SANS, 21), fill=TEXT)
    caption(d, "3. Paste anywhere. The file attaches.", color=GREEN)


SCENES = [
    (1.5, scene_title),
    (2.8, scene_copy),
    (5.2, scene_terminal),
    (3.4, scene_attach),
]
TOTAL = sum(s for s, _ in SCENES)


def main():
    frames = []
    n = int(TOTAL * FPS)
    starts = []
    acc = 0.0
    for dur, _ in SCENES:
        starts.append(acc)
        acc += dur
    for i in range(n):
        t = i / FPS
        img = Image.new("RGB", (W, H), BG)
        d = ImageDraw.Draw(img)
        for (dur, fn), start in zip(SCENES, starts):
            if start <= t < start + dur:
                fn(d, t - start)
                break
        frames.append(img)
    # hold the last frame a little longer before looping
    for _ in range(6):
        frames.append(frames[-1].copy())
    frames[0].save("assets/demo.gif", save_all=True, append_images=frames[1:],
                   duration=int(1000 / FPS), loop=0, optimize=True)
    print("wrote assets/demo.gif,", len(frames), "frames")


if __name__ == "__main__":
    main()
