#!/usr/bin/env python3
"""Compares screenshots pixel by pixel, pair by pair (the speed kit's proof).

Usage: compare-shots.py <dir> <prefix> [<report>]
Every <dir>/<prefix><name>.png is compared with <dir>/<name>.png. One line per pair: "same" (the same pixels), or
"DIFF" with the number of differing pixels, the largest channel difference and the box they lie in. A missing partner
counts as a difference. Exit 0 only when every pair is the same. Pure python (zlib), no packages needed.
"""
import os
import struct
import sys
import zlib


def read_png(path):
    data = open(path, "rb").read()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("not a PNG")
    pos, idat, head = 8, [], None
    while pos < len(data):
        (length,) = struct.unpack(">I", data[pos:pos + 4])
        kind = data[pos + 4:pos + 8]
        body = data[pos + 8:pos + 8 + length]
        pos += 12 + length
        if kind == b"IHDR":
            head = struct.unpack(">IIBBBBB", body)
        elif kind == b"IDAT":
            idat.append(body)
        elif kind == b"IEND":
            break
    width, height, depth, colour, _, _, interlace = head
    if depth != 8 or interlace != 0 or colour not in (2, 6, 0, 4):
        raise ValueError("unsupported PNG (depth %d, colour %d, interlace %d)" % (depth, colour, interlace))
    bpp = {0: 1, 2: 3, 4: 2, 6: 4}[colour]
    return width, height, bpp, zlib.decompress(b"".join(idat))


def unfilter(width, height, bpp, raw):
    stride = width * bpp
    out = bytearray(height * stride)
    prev = bytearray(stride)
    pos = 0
    for y in range(height):
        kind = raw[pos]
        line = bytearray(raw[pos + 1:pos + 1 + stride])
        pos += 1 + stride
        if kind == 1:
            for i in range(bpp, stride):
                line[i] = (line[i] + line[i - bpp]) & 255
        elif kind == 2:
            line = bytearray((a + b) & 255 for a, b in zip(line, prev))
        elif kind == 3:
            for i in range(stride):
                left = line[i - bpp] if i >= bpp else 0
                line[i] = (line[i] + ((left + prev[i]) >> 1)) & 255
        elif kind == 4:
            for i in range(stride):
                a = line[i - bpp] if i >= bpp else 0
                b = prev[i]
                c = prev[i - bpp] if i >= bpp else 0
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                pred = a if pa <= pb and pa <= pc else (b if pb <= pc else c)
                line[i] = (line[i] + pred) & 255
        out[y * stride:(y + 1) * stride] = line
        prev = line
    return out


def compare(path_a, path_b):
    wa, ha, ba, raw_a = read_png(path_a)
    wb, hb, bb, raw_b = read_png(path_b)
    if (wa, ha, ba) != (wb, hb, bb):
        return "DIFF size %dx%d/%d against %dx%d/%d" % (wa, ha, ba, wb, hb, bb)
    if raw_a == raw_b:
        return "same"
    a = unfilter(wa, ha, ba, raw_a)
    b = unfilter(wb, hb, bb, raw_b)
    if a == b:
        return "same"
    count, worst = 0, 0
    x0, y0, x1, y1 = wa, ha, -1, -1
    stride = wa * ba
    for y in range(ha):
        row = y * stride
        if a[row:row + stride] == b[row:row + stride]:
            continue
        for x in range(wa):
            i = row + x * ba
            d = max(abs(a[i + k] - b[i + k]) for k in range(ba))
            if d:
                count += 1
                worst = max(worst, d)
                x0, y0, x1, y1 = min(x0, x), min(y0, y), max(x1, x), max(y1, y)
    return "DIFF %d px (%.4f %%), max channel diff %d, box x %d-%d y %d-%d" % (
        count, 100.0 * count / (wa * ha), worst, x0, x1, y0, y1)


def main():
    folder, prefix = sys.argv[1], sys.argv[2]
    report = sys.argv[3] if len(sys.argv) > 3 else None
    lines, bad = [], 0
    for name in sorted(os.listdir(folder)):
        if not (name.startswith(prefix) and name.endswith(".png")):
            continue
        partner = os.path.join(folder, name[len(prefix):])
        if not os.path.exists(partner):
            verdict = "DIFF no partner " + os.path.basename(partner)
        else:
            try:
                verdict = compare(os.path.join(folder, name), partner)
            except Exception as error:  # a broken file is a difference too
                verdict = "DIFF unreadable: %s" % error
        bad += verdict != "same"
        lines.append("%-48s %s" % (name[len(prefix):], verdict))
    lines.append("pairs: %d, the same: %d, different: %d" % (len(lines), len(lines) - bad, bad))
    text = "\n".join(lines) + "\n"
    sys.stdout.write(text)
    if report:
        open(report, "w").write(text)
    return 0 if bad == 0 and len(lines) > 1 else 1


if __name__ == "__main__":
    sys.exit(main())
