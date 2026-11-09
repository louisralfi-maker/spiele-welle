import zlib, struct
def read_png(path):
    data = open(path, 'rb').read()
    assert data[:8] == b'\x89PNG\r\n\x1a\n'
    pos = 8; idat = b''; w = h = 0; ct = bd = 0; plte = None; trns = None
    while pos < len(data):
        n = struct.unpack('>I', data[pos:pos+4])[0]; t = data[pos+4:pos+8]; d = data[pos+8:pos+8+n]; pos += 12 + n
        if t == b'IHDR': w, h, bd, ct, _, _, il = struct.unpack('>IIBBBBB', d)
        elif t == b'PLTE': plte = [tuple(d[i:i+3]) for i in range(0, len(d), 3)]
        elif t == b'tRNS': trns = d
        elif t == b'IDAT': idat += d
    raw = zlib.decompress(idat)
    bpp = {6: 4, 2: 3, 3: 1, 0: 1, 4: 2}[ct]
    stride = w * bpp; out = []; prev = bytearray(stride); i = 0
    for y in range(h):
        f = raw[i]; i += 1; line = bytearray(raw[i:i+stride]); i += stride
        for x in range(stride):
            a = line[x-bpp] if x >= bpp else 0; b = prev[x]; c = prev[x-bpp] if x >= bpp else 0
            if f == 1: line[x] = (line[x] + a) & 255
            elif f == 2: line[x] = (line[x] + b) & 255
            elif f == 3: line[x] = (line[x] + ((a + b) >> 1)) & 255
            elif f == 4:
                p = a + b - c; pa, pb, pc = abs(p-a), abs(p-b), abs(p-c)
                line[x] = (line[x] + (a if pa <= pb and pa <= pc else (b if pb <= pc else c))) & 255
        prev = line
        row = []
        for x in range(w):
            if ct == 6: row.append(tuple(line[x*4:x*4+4]))
            elif ct == 2: row.append(tuple(line[x*3:x*3+3]) + (255,))
            elif ct == 3:
                k = line[x]; a = trns[k] if trns and k < len(trns) else 255; row.append(plte[k] + (a,))
            elif ct == 0: row.append((line[x],)*3 + (255,))
            elif ct == 4: row.append((line[x*2],)*3 + (line[x*2+1],))
        out.append(row)
    return w, h, out, ct
