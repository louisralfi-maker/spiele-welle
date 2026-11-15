#!/usr/bin/env python3
"""Lanternhold: night glass, the skin of every card, sheet and plaque (TITLE.md section 4, HUD.md rule 3).

No parchment anywhere (Louis, 15.11.2026). Every card stands on a pane of the night's navy over the world, drawn on the
game's pixel grid (1 game px = 2 pt = 6 device px on iPhone 17 Pro) and scaled with nearest neighbour only:

  - the pane: navy at 88 % (the world is felt behind it), one brass line of 1 game px set 2 game px inside the edge,
    the corners notched by 1 game px. No shadow, gradient, texture, wax or seal.
  - text in bone, names and the chosen state in lantern gold, secondary lines in mist (a muted blue-grey); every text
    colour has 7:1 or more on the pane over a white world and over a black one (`glassart.py contrast`).

Pieces (written to tools/glass/, outside Resources, so the atlas and the app bundle do not change; NightGlass.swift
builds the same pixels from the same grids at run time, `glassart.py check` proves they match):

  glassPanel          9x9 nine-slice, caps 4: the pane of a card or sheet
  glassPlaque         9x9, caps 4: a choice at rest (the pane with its brass line)
  glassPlaqueMarked   9x9, caps 4: the favoured or chosen one (the line in lantern gold)
  glassPlaquePressed  9x9, caps 4: pressed, filled with lantern amber, the line in deep navy (dark text on it)
  glassPlaqueOff      9x9, caps 4: cannot be paid (the line in dark mist; title and cost in mist)
  glassPlaqueDanger   9x9, caps 4: a destructive choice (the line in ember; the words stay bone)
  glassInset          9x9, caps 4: a plaque inside a pane (no second fill, so the pane is not darkened twice; its
                      line on its own edge, the corners notched)
  glassInsetMarked    the same, the line in lantern gold: the main button of a sheet (Resume, Continue)
  glassInsetDanger    the same, the line in ember: a destructive choice inside a sheet
  glassPortrait       5x5, caps 2: the portrait's brass line, 1 game px hugging the picture, notched; no mat
  glassRibbon<h>      the horn's ribbon (and the dawn report's banners): the pane with notched ends, brass line,
                      3-slice (caps h//2 + 3, middle column stretched), h game px high (13 and 15 written)
  glassSwitchOn/Off   24x12: the pause sheet's switch, a slot with a square knob (no wax seal)
  glassRule           3x1: a separator, 1 game px of night haze (the old ink rule)
  glassGem            3x3: the lozenge of a flourish (pixel diamond in brass)

  glassart.py build [--out DIR]     write every piece (default tools/glass)
  glassart.py sheet OUT.png          a contact sheet at 1x and 6x over noon, dusk and night
  glassart.py contrast               the contrast table
  glassart.py check SWIFT_FILE       compare the grids and colours with NightGlass.swift

PIL only, deterministic, well under a second.
"""
import argparse
import os
import re
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))

# --- the colours (hex; palette names from tools/palette.txt where the value is the palette's) -----------------------
NAVY = 0x121C3B           # palette nightBlue: the pane
NAVY_ALPHA = 224          # 0.88 of 255 (87.8 %)
NAVY_DEEP = 0x0A1124      # palette nightDeep: the line and the words on a pressed plaque, the switch's slot
BRASS = 0xA68A54          # palette straw: the brass line (the coin's shaded rim in the HUD kit)
BONE = 0xDED2B8           # palette parchment (the HUD kit's bone): running text
LANTERN_GOLD = 0xFFC65A   # palette fireGold: names, headings, the chosen state, the marked line
AMBER = 0xFFA34D          # the lantern's light (ART-look2.md "Warm pools"): a pressed plaque's fill
MIST = 0xC5CBD9           # palette mistLight: secondary lines (the muted blue-grey)
MIST_DIM = 0x98A1BB       # palette mist: words that cannot be chosen (disabled; no contrast rule)
MIST_DARK = 0x6A7393      # palette mistDark: the line of a plaque that cannot be paid
HAZE = 0x2F3F72           # palette nightHaze: separators
SLATE = 0x1E2B52          # palette nightSlate: the lifted face of a sheet's main button
SLATE_ALPHA = 200
EMBER = 0xD9481F          # palette ember: the line of a destructive choice

COLOURS = [
    ("navy", NAVY, "the pane, at %d/255 (%.1f %%)" % (NAVY_ALPHA, NAVY_ALPHA / 2.55)),
    ("navyDeep", NAVY_DEEP, "pressed line and words, the switch's slot"),
    ("brass", BRASS, "the brass line"),
    ("bone", BONE, "running text"),
    ("lanternGold", LANTERN_GOLD, "names, headings, the chosen state, the marked line"),
    ("amber", AMBER, "a pressed plaque's fill"),
    ("mist", MIST, "secondary lines"),
    ("mistDim", MIST_DIM, "words that cannot be chosen"),
    ("mistDark", MIST_DARK, "the line of a plaque that cannot be paid"),
    ("haze", HAZE, "separators"),
    ("slate", SLATE, "the lifted face of a sheet's main button, at %d/255" % SLATE_ALPHA),
    ("ember", EMBER, "the line of a destructive choice"),
]


def rgba(hexv, a=255):
    return ((hexv >> 16) & 255, (hexv >> 8) & 255, hexv & 255, a)


CLEAR = (0, 0, 0, 0)

# --- the pane's grid: f fill, l line, . clear. One shape for the whole plaque family --------------------------------

def pane_grid(inset=2, notched_line=False):
    """The pane: corners notched by 1 game px, a line of 1 game px `inset` game px inside the edge (2 for a card or a
    sheet; 1 for a choice plaque, whose words stand closer to its edge). notched_line also cuts the line's corners."""
    cap = inset + 2
    n = 2 * cap + 1
    rows = []
    for y in range(n):
        row = ""
        for x in range(n):
            if x in (0, n - 1) and y in (0, n - 1):
                row += "."
                continue
            on_v = x in (inset, n - 1 - inset) and inset <= y <= n - 1 - inset
            on_h = y in (inset, n - 1 - inset) and inset <= x <= n - 1 - inset
            corner = x in (inset, n - 1 - inset) and y in (inset, n - 1 - inset)
            if (on_v or on_h) and not (notched_line and corner):
                row += "l"
            else:
                row += "f"
        rows.append(row)
    return rows


PANE = pane_grid(2)
PANE_CAP = 4
PLAQUE = pane_grid(1)
PLAQUE_CAP = 3

INSET = [
    ".lllllll.",
    "lfffffffl",
    "lfffffffl",
    "lfffffffl",
    "lfffffffl",
    "lfffffffl",
    "lfffffffl",
    "lfffffffl",
    ".lllllll.",
]

PORTRAIT = [
    ".....",
    "..l..",
    ".l.l.",
    "..l..",
    ".....",
]
PORTRAIT_CAP = 2

# (fill, line) per skin; a fill of None leaves the pane clear inside.
SKINS = {
    "glassPanel": (rgba(NAVY, NAVY_ALPHA), rgba(BRASS)),
    "glassPlaque": (rgba(NAVY, NAVY_ALPHA), rgba(BRASS)),
    "glassPlaqueMarked": (rgba(NAVY, NAVY_ALPHA), rgba(LANTERN_GOLD)),
    "glassPlaquePressed": (rgba(AMBER), rgba(NAVY_DEEP)),
    "glassPlaqueOff": (rgba(NAVY, NAVY_ALPHA), rgba(MIST_DARK)),
    "glassPlaqueDanger": (rgba(NAVY, NAVY_ALPHA), rgba(EMBER)),
    "glassInset": (CLEAR, rgba(BRASS)),
    "glassInsetMarked": (rgba(SLATE, SLATE_ALPHA), rgba(LANTERN_GOLD)),
    "glassInsetDanger": (CLEAR, rgba(EMBER)),
}


def from_grid(rows, legend):
    h, w = len(rows), len(rows[0])
    im = Image.new("RGBA", (w, h), CLEAR)
    px = im.load()
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            px[x, y] = legend.get(ch, CLEAR)
    return im


def pane(name, notched_line=False, inset=None):
    """A skin of the pane family. Cards and sheets (glassPanel) have their line 2 game px in; plaques 1 (inset=None
    picks that); inset can force either for the rivals."""
    fill, line = SKINS[name]
    if inset is None:
        inset = 2 if name == "glassPanel" else 1
    grid = pane_grid(inset, notched_line)
    if name.startswith("glassInset"):
        # A plaque inside a pane: its line on its own edge (no room is lost), the corners notched, no fill.
        grid = INSET
    return from_grid(grid, {"f": fill, "l": line})


def portrait():
    return from_grid(PORTRAIT, {"l": rgba(BRASS)})


def ribbon_grid(h):
    """The ribbon: a pane whose two ends are cut in a V of 1:1 pixel stairs. Its brass line runs 2 game px inside the
    top and bottom edges and 3 game px inside the stairs (measured along the row; a diagonal at 3 across is about 2
    square to it), so it reads as one inset all round. 3-slice: the middle column stretches."""
    depth = h // 2
    cap = depth + 4
    w = 2 * cap + 1
    mid = h // 2
    rows = []
    for y in range(h):
        xl = depth - abs(y - mid)
        row = ""
        for x in range(w):
            if x < xl or x > w - 1 - xl:
                row += "."
            elif 2 <= y <= h - 3 and (x - xl == 3 or (w - 1 - xl) - x == 3):
                row += "l"
            elif y in (2, h - 3) and xl + 3 <= x <= w - 1 - xl - 3:
                row += "l"
            else:
                row += "f"
        rows.append(row)
    return rows, cap


def ribbon(h):
    rows, _ = ribbon_grid(h)
    return from_grid(rows, {"f": rgba(NAVY, NAVY_ALPHA), "l": rgba(BRASS)})


def switch_grid(on):
    rows = []
    for y in range(12):
        row = []
        for x in range(24):
            if (x in (0, 23)) and (y in (0, 11)):
                row.append(".")
            elif x in (0, 23) or y in (0, 11):
                row.append("l")
            else:
                kx0 = 12 if on else 2
                if kx0 <= x <= kx0 + 9 and 2 <= y <= 9:
                    corner = (x in (kx0, kx0 + 9)) and (y in (2, 9))
                    edge = x in (kx0, kx0 + 9) or y in (2, 9)
                    row.append("s" if corner else ("k" if edge else "m"))
                else:
                    row.append("s")
        rows.append("".join(row))
    return rows


def switch(on):
    legend = {"l": rgba(BRASS), "s": rgba(NAVY_DEEP, 235),
              "k": rgba(LANTERN_GOLD) if on else rgba(MIST_DARK),
              "m": rgba(AMBER) if on else rgba(HAZE)}
    return from_grid(switch_grid(on), legend)


def rule():
    return from_grid(["hhh"], {"h": rgba(HAZE)})


def gem():
    return from_grid([".g.", "ggg", ".g."], {"g": rgba(LANTERN_GOLD)})


def pieces(notched_line=False):
    out = {}
    for name in SKINS:
        out[name] = pane(name, notched_line)
    out["glassPortrait"] = portrait()
    for h in (13, 15):
        out["glassRibbon%d" % h] = ribbon(h)
    out["glassSwitchOn"] = switch(True)
    out["glassSwitchOff"] = switch(False)
    out["glassRule"] = rule()
    out["glassGem"] = gem()
    return out


def nine(im, cap, w, h, scale=6):
    """Draw a nine-slice piece at w x h game px (nearest neighbour), then scale by `scale`, as SwiftUI will."""
    sw, sh = im.size
    out = Image.new("RGBA", (w, h), CLEAR)
    capx = cap if sw > 2 * cap else (sw - 1) // 2
    capy = cap if sh > 2 * cap else (sh - 1) // 2

    def src(i, n, sn, c):
        if i < c:
            return i
        if i >= n - c:
            return sn - (n - i)
        return c

    sp = im.load()
    op = out.load()
    for y in range(h):
        for x in range(w):
            op[x, y] = sp[src(x, w, sw, capx), src(y, h, sh, capy)]
    return out.resize((w * scale, h * scale), Image.NEAREST) if scale != 1 else out


# --- contrast ---------------------------------------------------------------------------------------------------------

def _lin(c):
    c = c / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def luminance(rgb):
    r, g, b = (_lin(v) for v in rgb[:3])
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a, b):
    la, lb = luminance(a), luminance(b)
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)


def over(top, alpha, under):
    """sRGB-space compositing, as Core Animation blends."""
    return tuple(alpha * t + (1 - alpha) * u for t, u in zip(top[:3], under[:3]))


WORLDS = [
    ("white", (255, 255, 255)),
    ("noon snow", (0xE4, 0xE9, 0xEE)),
    ("noon sky", (0xA8, 0xBD, 0xC7)),
    ("hearth fire", (0xFF, 0xC6, 0x5A)),
    ("hall stone", (0x46, 0x40, 0x3C)),
    ("night", (0x1C, 0x21, 0x52)),
    ("black", (0, 0, 0)),
]


def contrast_table(alpha=NAVY_ALPHA / 255.0):
    texts = [("bone", BONE), ("lanternGold", LANTERN_GOLD), ("mist", MIST)]
    lines = ["pane navy #%06X at %.3f over:" % (NAVY, alpha)]
    worst = 99.0
    for wname, w in WORLDS:
        bg = over(rgba(NAVY), alpha, w)
        cells = []
        for tname, t in texts:
            c = contrast(rgba(t), bg)
            worst = min(worst, c)
            cells.append("%s %.2f" % (tname, c))
        lines.append("  %-12s -> pane #%02X%02X%02X: %s" % (wname, *[round(v) for v in bg], ", ".join(cells)))
    lines.append("  worst %.2f (rule: 7.00 or more)" % worst)
    lines.append("pressed: navyDeep words on amber %.2f" % contrast(rgba(NAVY_DEEP), rgba(AMBER)))
    for wname, w in (("white", (255, 255, 255)), ("black", (0, 0, 0))):
        face = over(rgba(SLATE), SLATE_ALPHA / 255.0, over(rgba(NAVY), alpha, w))
        lines.append("main button: lanternGold on slate over the pane over %s %.2f" % (wname, contrast(rgba(LANTERN_GOLD), face)))
    lines.append("brass line on the pane over black %.2f, over white %.2f (a line, not text)" % (
        contrast(rgba(BRASS), over(rgba(NAVY), alpha, (0, 0, 0))),
        contrast(rgba(BRASS), over(rgba(NAVY), alpha, (255, 255, 255)))))
    return lines, worst


# --- the Swift check --------------------------------------------------------------------------------------------------

def check(swift_path):
    text = open(swift_path, encoding="utf-8").read()
    ok = True
    for name, grid in (("pane", PANE), ("plaque", PLAQUE), ("inset", INSET), ("portrait", PORTRAIT)):
        m = re.search(r"static let %sGrid = \[(.*?)\]" % name, text, re.S)
        if not m:
            print("missing %sGrid" % name)
            ok = False
            continue
        rows = re.findall(r'"([^"]*)"', m.group(1))
        if rows != grid:
            print("%sGrid differs: %r" % (name, rows))
            ok = False
    for cname, value, _ in COLOURS:
        m = re.search(r"static let %s = Color\(hex: 0x([0-9A-Fa-f]{6})" % cname, text)
        if not m or int(m.group(1), 16) != value:
            print("colour %s differs or missing" % cname)
            ok = False
    m = re.search(r"static let navyInk = Ink\(rgb: 0x([0-9A-Fa-f]{6}), alpha: ([0-9]+)\)", text)
    if not m or int(m.group(1), 16) != NAVY or int(m.group(2)) != NAVY_ALPHA:
        print("navyInk differs")
        ok = False
    for h in (13, 15):
        print("ribbon %d: mirrored in ribbonGrid(height:) (same loops; not parsed)" % h)
    m = re.search(r"static let paneAlpha: Double = ([0-9.]+)", text)
    if not m or abs(float(m.group(1)) - NAVY_ALPHA / 255.0) > 0.002:
        print("paneAlpha differs")
        ok = False
    print("NightGlass.swift matches glassart.py" if ok else "MISMATCH")
    return ok


def contact_sheet(path, notched_line=False):
    grounds = [("noon", (0x86, 0xA6, 0xB6)), ("dusk", (0x6A, 0x50, 0x5A)), ("night", (0x1C, 0x21, 0x52))]
    ps = pieces(notched_line)
    tiles = []
    for name, im in ps.items():
        if name.startswith("glassRibbon"):
            h = im.size[1]
            tiles.append((name, nine(im, h // 2 + 3, im.size[0] + 18, h)))
        elif name in ("glassPortrait",):
            tiles.append((name, nine(im, PORTRAIT_CAP, 16, 16)))
        elif name.startswith("glassSwitch") or name in ("glassGem",):
            tiles.append((name, im.resize((im.size[0] * 6, im.size[1] * 6), Image.NEAREST)))
        elif name == "glassRule":
            tiles.append((name, nine(im, 1, 30, 1)))
        else:
            tiles.append((name, nine(im, PANE_CAP, 34, 14)))
    W = 1500
    rowh = 130
    sheet = Image.new("RGBA", (W * len(grounds), rowh * len(tiles) + 20), (0, 0, 0, 255))
    for gi, (_, g) in enumerate(grounds):
        band = Image.new("RGBA", (W, sheet.size[1]), g + (255,))
        # a bright and a dark stripe behind every tile, to see the pane's 12 %
        for i in range(0, sheet.size[1], 40):
            band.paste((255, 255, 255, 255) if (i // 40) % 3 == 0 else g + (255,), (0, i, W, i + 8))
        sheet.paste(band, (gi * W, 0))
        for ti, (name, im) in enumerate(tiles):
            src = ps[name]
            sheet.alpha_composite(src, (gi * W + 20, 20 + ti * rowh))
            sheet.alpha_composite(im, (gi * W + 80, 20 + ti * rowh))
    sheet.convert("RGB").save(path)


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd")
    b = sub.add_parser("build")
    b.add_argument("--out", default=os.path.join(HERE, "glass"))
    b.add_argument("--notched-line", action="store_true", help="the rival: the line's corners notched too")
    s = sub.add_parser("sheet")
    s.add_argument("out")
    s.add_argument("--notched-line", action="store_true")
    sub.add_parser("contrast")
    c = sub.add_parser("check")
    c.add_argument("swift")
    args = ap.parse_args()
    if args.cmd == "build":
        os.makedirs(args.out, exist_ok=True)
        for name, im in pieces(args.notched_line).items():
            im.save(os.path.join(args.out, name + ".png"), optimize=False)
        print("wrote %d pieces to %s" % (len(pieces()), args.out))
    elif args.cmd == "sheet":
        contact_sheet(args.out, args.notched_line)
    elif args.cmd == "contrast":
        lines, worst = contrast_table()
        print("\n".join(lines))
        for name, value, use in COLOURS:
            print("  %-12s #%06X  %s" % (name, value, use))
        sys.exit(0 if worst >= 7 else 1)
    elif args.cmd == "check":
        sys.exit(0 if check(args.swift) else 1)
    else:
        ap.print_help()


if __name__ == "__main__":
    main()
