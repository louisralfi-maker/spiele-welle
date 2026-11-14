#!/usr/bin/env python3
"""Lanternhold's sound effects and ambience loops, synthesised in pure Python (no numpy, no PIL).

Every file in Resources/Sound/ comes from this script: mono 16-bit WAV at 22.05 kHz. A fixed seed per sound and a
small own random generator make each run write the same bytes (on the same machine; the manifest's sha256 lets a
rebuild be checked). No music and no melody: signals only (DESIGN.md "Sound and haptics").

    python3 games/lanternhold/tools/soundsynth.py            # all files
    python3 games/lanternhold/tools/soundsynth.py bow coin   # only these
    python3 games/lanternhold/tools/soundsynth.py --list

The Mac this runs on overheats under long CPU load (CLAUDE.md "This Mac"): the script makes one sound at a time and
pauses between them when it can read the CPU temperature (tools/smcread) and it passes 80 C.
"""

import hashlib
import math
import os
import struct
import subprocess
import sys
import time

SR = 22050
TWO_PI = 2.0 * math.pi
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, "..", "Resources", "Sound"))
SMCREAD = os.path.normpath(os.path.join(HERE, "..", "..", "..", "tools", "smcread"))


# ----------------------------------------------------------------------------------------------------------------
# Random numbers: a small xorshift generator, the same on every Python.

class Rng:
    def __init__(self, seed):
        self.s = (seed * 0x9E3779B97F4A7C15 + 0x632BE59BD9B4E019) & 0xFFFFFFFFFFFFFFFF or 1

    def next(self):
        s = self.s
        s ^= (s << 13) & 0xFFFFFFFFFFFFFFFF
        s ^= s >> 7
        s ^= (s << 17) & 0xFFFFFFFFFFFFFFFF
        self.s = s
        return s

    def random(self):
        return (self.next() >> 11) * (1.0 / 9007199254740992.0)

    def uniform(self, a, b):
        return a + (b - a) * self.random()

    def bipolar(self):
        return 2.0 * self.random() - 1.0


# ----------------------------------------------------------------------------------------------------------------
# Building blocks. A signal is a plain list of floats at SR.

def secs(t):
    return int(round(t * SR))


def zeros(n):
    return [0.0] * n


def noise(n, rng):
    return [rng.bipolar() for _ in range(n)]


def brown(n, rng, leak=0.995):
    out = [0.0] * n
    y = 0.0
    for i in range(n):
        y = y * leak + rng.bipolar() * 0.08
        out[i] = y
    return out


def lowpass(x, fc):
    """One-pole low pass."""
    a = math.exp(-TWO_PI * fc / SR)
    b = 1.0 - a
    y = 0.0
    out = [0.0] * len(x)
    for i, v in enumerate(x):
        y = b * v + a * y
        out[i] = y
    return out


def highpass(x, fc):
    """One-pole high pass (the input minus its low pass)."""
    lp = lowpass(x, fc)
    return [v - l for v, l in zip(x, lp)]


def _biquad_coeffs(kind, f, q):
    f = max(10.0, min(f, SR * 0.45))
    w = TWO_PI * f / SR
    cw = math.cos(w)
    alpha = math.sin(w) / (2.0 * q)
    if kind == "lp":
        b0, b1, b2 = (1 - cw) / 2, 1 - cw, (1 - cw) / 2
    elif kind == "hp":
        b0, b1, b2 = (1 + cw) / 2, -(1 + cw), (1 + cw) / 2
    else:  # band pass, 0 dB peak
        b0, b1, b2 = alpha, 0.0, -alpha
    a0 = 1 + alpha
    return b0 / a0, b1 / a0, b2 / a0, (-2 * cw) / a0, (1 - alpha) / a0


def biquad(x, kind, f, q=0.707):
    """RBJ biquad; `f` is a number or a function of time (seconds), updated every 32 samples."""
    out = [0.0] * len(x)
    x1 = x2 = y1 = y2 = 0.0
    varying = callable(f)
    b0, b1, b2, a1, a2 = _biquad_coeffs(kind, f(0.0) if varying else f, q)
    for i, v in enumerate(x):
        if varying and (i & 31) == 0:
            b0, b1, b2, a1, a2 = _biquad_coeffs(kind, f(i / SR), q)
        y = b0 * v + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        x2, x1 = x1, v
        y2, y1 = y1, y
        out[i] = y
    return out


def sine(n, freq, phase=0.0):
    """A sine of a fixed frequency or of a function of time (seconds), phase-continuous."""
    out = [0.0] * n
    if callable(freq):
        p = phase
        for i in range(n):
            out[i] = math.sin(p)
            p += TWO_PI * freq(i / SR) / SR
    else:
        step = TWO_PI * freq / SR
        for i in range(n):
            out[i] = math.sin(phase + step * i)
    return out


def decay(n, tau, attack=0.0):
    """exp(-t/tau) with a linear attack."""
    out = [0.0] * n
    na = secs(attack)
    k = math.exp(-1.0 / (tau * SR))
    g = 1.0
    for i in range(n):
        a = (i + 1) / na if i < na else 1.0
        out[i] = g * a
        if i >= na:
            g *= k
    return out


def mul(a, b):
    return [x * y for x, y in zip(a, b)]


def gain(x, g):
    return [v * g for v in x]


def add_into(dst, src, at=0, g=1.0):
    """Mixes `src` into `dst` from sample `at` (clipped to dst's length)."""
    n = min(len(src), len(dst) - at)
    for i in range(max(0, -at), n):
        dst[at + i] += src[i] * g
    return dst


def fade(x, fin=0.002, fout=0.02):
    n = len(x)
    a = max(1, secs(fin))
    b = max(1, secs(fout))
    out = list(x)
    for i in range(min(a, n)):
        out[i] *= i / a
    for i in range(min(b, n)):
        out[n - 1 - i] *= i / b
    return out


def normalize(x, peak=0.89):
    m = max(1e-9, max(abs(v) for v in x))
    return [v * peak / m for v in x]


def soft(x, drive=1.2):
    """Gentle saturation: warmth, and no hard clipping anywhere."""
    t = math.tanh(drive)
    return [math.tanh(v * drive) / t for v in x]


def smooth_random(n, rng, rate, octaves=3):
    """A slowly wandering value in about -1 ... 1 (sum of interpolated random points)."""
    out = [0.0] * n
    amp = 1.0
    total = 0.0
    for o in range(octaves):
        r = rate * (2 ** o)
        step = max(1, int(SR / r))
        pts = [rng.bipolar() for _ in range(n // step + 3)]
        for i in range(n):
            k, f = divmod(i, step)
            t = f / step
            t = t * t * (3 - 2 * t)
            out[i] += amp * (pts[k] * (1 - t) + pts[k + 1] * t)
        total += amp
        amp *= 0.5
    return [v / total for v in out]


def reverb(x, wet=0.3, size=1.0, damp=0.4, tail=0.0):
    """A small Schroeder reverb (four combs, two all-passes; Freeverb's delays at 22.05 kHz)."""
    n = len(x) + secs(tail)
    src = list(x) + [0.0] * (n - len(x))
    combs = [int(d * size) for d in (558, 594, 638, 678)]
    fb = 0.78
    acc = [0.0] * n
    for d in combs:
        buf = [0.0] * d
        idx = 0
        store = 0.0
        for i in range(n):
            out = buf[idx]
            store = out * (1 - damp) + store * damp
            buf[idx] = src[i] + store * fb
            idx += 1
            if idx == d:
                idx = 0
            acc[i] += out
    for d in (278, 111):
        buf = [0.0] * d
        idx = 0
        for i in range(n):
            b = buf[idx]
            v = acc[i]
            buf[idx] = v + b * 0.5
            acc[i] = b - v * 0.5
            idx += 1
            if idx == d:
                idx = 0
    return [s * (1 - wet) + a * wet * 0.25 for s, a in zip(src, acc)]


def loopify(x, length, cross):
    """A seamless loop of `length` samples from `length + cross`: the tail is crossfaded (equal power) onto the head,
    so the last sample runs straight into the first."""
    assert len(x) >= length + cross
    out = list(x[:length])
    for i in range(cross):
        t = i / cross
        out[i] = x[i] * math.sin(0.5 * math.pi * t) + x[length + i] * math.cos(0.5 * math.pi * t)
    return out


def grain(n, f, tau, rng=None, noisy=0.0):
    """A short struck grain: a decaying sine with some noise."""
    out = [0.0] * n
    k = math.exp(-1.0 / (tau * SR))
    g = 1.0
    step = TWO_PI * f / SR
    for i in range(n):
        v = math.sin(step * i)
        if rng is not None and noisy:
            v = v * (1 - noisy) + rng.bipolar() * noisy
        out[i] = v * g
        g *= k
    return out


def formant_voice(n, rng, f1, f2, q=6.0, pitch=None, breath=1.0):
    """A breathy voice without words: noise (and a soft glottal buzz) through two formants."""
    src = noise(n, rng)
    if pitch is not None:
        buzz = [0.0] * n
        p = 0.0
        for i in range(n):
            p += pitch(i / SR) / SR
            p -= math.floor(p)
            buzz[i] = (1 - 2 * p)
        buzz = lowpass(buzz, 900)
        src = [s * breath + b * (1 - breath) * 2.5 for s, b in zip(src, buzz)]
    a = biquad(src, "bp", f1, q)
    b = biquad(src, "bp", f2, q)
    return [u + 0.6 * v for u, v in zip(a, b)]


# ----------------------------------------------------------------------------------------------------------------
# Ambience loops (all loop without a click: `loopify`).

def fire_bed(n, rng, crackles=6.0, pops=0.6):
    roar = lowpass(brown(n, rng, 0.997), 260)
    wob = smooth_random(n, rng, 1.3)
    roar = [r * (0.7 + 0.3 * w) for r, w in zip(roar, wob)]
    hiss = gain(biquad(noise(n, rng), "bp", 2800, 0.8), 0.05)
    out = [r * 1.4 + h for r, h in zip(roar, hiss)]
    t = 0.0
    while True:
        t += -math.log(1 - rng.random()) / crackles
        at = secs(t)
        if at >= n:
            break
        amp = 0.15 + 0.85 * rng.random() ** 3
        for _ in range(1 + int(rng.random() * 3)):
            m = secs(0.004)
            click = [rng.bipolar() * math.exp(-i / (0.0007 * SR)) for i in range(m)]
            add_into(out, highpass(click, 1500), at, amp * 0.9)
            at += secs(rng.uniform(0.004, 0.02))
    t = 0.0
    while True:
        t += -math.log(1 - rng.random()) / pops
        at = secs(t)
        if at >= n:
            break
        m = secs(0.05)
        pop = [rng.bipolar() * math.exp(-i / (0.002 * SR)) for i in range(m)]
        thump = grain(m, rng.uniform(160, 240), 0.012)
        add_into(out, [p * 0.8 + q * 0.6 for p, q in zip(pop, thump)], at, rng.uniform(0.4, 0.9))
    return lowpass(out, 6500)


def wind(n, rng, lo, hi, body=1.0):
    drift = smooth_random(n, rng, 0.12)
    gust = smooth_random(n, rng, 0.2)
    centre = lambda t: lo + (hi - lo) * (0.5 + 0.5 * drift[min(n - 1, int(t * SR))])
    w = biquad(noise(n, rng), "bp", centre, 0.8)
    whistle_c = lambda t: 2.2 * centre(t)
    whistle = biquad(noise(n, rng), "bp", whistle_c, 5.0)
    rumble = lowpass(lowpass(noise(n, rng), 160), 160)
    out = [0.0] * n
    for i in range(n):
        g = 0.45 + 0.55 * (0.5 + 0.5 * gust[i])
        out[i] = g * (w[i] + 0.12 * g * whistle[i]) + body * 2.2 * rumble[i]
    return out


def amb_day():
    rng = Rng(101)
    L, F = secs(10.0), secs(1.5)
    x = wind(L + F, rng, 320, 720)
    return normalize(loopify(x, L, F), 0.7)


def amb_night():
    rng = Rng(202)
    L, F = secs(10.0), secs(1.5)
    n = L + F
    x = gain(wind(n, rng, 200, 430, body=1.3), 0.8)
    # Far below the wind: two of the lost, a long breathy moan each, low and far (no words, no gore).
    for start, length, f1, f2, p0, p1 in ((1.2, 2.6, 420, 780, 105, 82), (5.9, 2.2, 380, 700, 92, 74)):
        m = secs(length)
        env = [math.sin(math.pi * i / m) ** 2 for i in range(m)]
        voice = formant_voice(m, rng, lambda t, f=f1: f * (1 - 0.15 * t / length),
                              lambda t, f=f2: f * (1 - 0.2 * t / length), q=7.0,
                              pitch=lambda t, a=p0, b=p1: a + (b - a) * t / length, breath=0.55)
        add_into(x, mul(lowpass(voice, 1100), env), secs(start), 0.9)
    # A low, slow drone with a soft beat.
    drone = [0.5 * math.sin(TWO_PI * 55.0 * i / SR) + 0.5 * math.sin(TWO_PI * 55.35 * i / SR) for i in range(n)]
    add_into(x, drone, 0, 0.05)
    x = reverb(x, wet=0.35, size=1.4, damp=0.5)
    return normalize(loopify(x, L, F), 0.65)


def amb_rain():
    rng = Rng(303)
    L, F = secs(6.0), secs(1.0)
    n = L + F
    hiss = biquad(biquad(noise(n, rng), "hp", 900, 0.6), "lp", 6000, 0.6)
    swell = smooth_random(n, rng, 0.4)
    roof = lowpass(lowpass(noise(n, rng), 450), 450)
    x = [h * (0.8 + 0.2 * s) * 0.35 + r * 1.6 for h, s, r in zip(hiss, swell, roof)]
    t = 0.0
    while True:
        t += -math.log(1 - rng.random()) / 55.0
        at = secs(t)
        if at >= n:
            break
        m = secs(0.03)
        drop = grain(m, rng.uniform(1400, 4200), rng.uniform(0.003, 0.009))
        add_into(x, drop, at, 0.05 + 0.25 * rng.random() ** 2)
    x = lowpass(x, 7000)
    return normalize(loopify(x, L, F), 0.6)


def amb_fire():
    rng = Rng(404)
    L, F = secs(6.0), secs(1.0)
    x = fire_bed(L + F, rng)
    return normalize(loopify(x, L, F), 0.7)


def amb_hall():
    rng = Rng(505)
    L, F = secs(8.0), secs(1.5)
    n = L + F
    hearth = gain(lowpass(fire_bed(n, rng, crackles=4.0, pops=0.4), 3200), 0.7)
    murmur = zeros(n)
    # Six people talking quietly somewhere in the hall: phrases of syllables, muffled until no word is left.
    for v in range(6):
        pitch0 = rng.uniform(95, 190)
        t = rng.uniform(0, 1.5)
        while t < n / SR:
            phrase = rng.uniform(0.9, 2.6)
            m = secs(phrase)
            f1s = [rng.uniform(320, 720) for _ in range(40)]
            f2s = [rng.uniform(900, 1700) for _ in range(40)]
            rate = rng.uniform(3.5, 5.5)
            f1 = lambda tt, a=f1s, r=rate: a[int(tt * r) % 40]
            f2 = lambda tt, a=f2s, r=rate: a[int(tt * r) % 40]
            voice = formant_voice(m, rng, f1, f2, q=4.0,
                                  pitch=lambda tt, p=pitch0: p * (1 + 0.06 * math.sin(tt * 2.1)), breath=0.35)
            env = [0.0] * m
            for i in range(m):
                tt = i / SR
                syl = 0.5 - 0.5 * math.cos(TWO_PI * rate * tt)
                edge = min(1.0, tt / 0.15, (phrase - tt) / 0.25)
                env[i] = max(0.0, edge) * (0.35 + 0.65 * syl)
            add_into(murmur, mul(voice, env), secs(t), rng.uniform(0.5, 1.0))
            t += phrase + rng.uniform(0.6, 2.2)
    murmur = lowpass(lowpass(murmur, 750), 750)
    x = [h + 0.9 * m for h, m in zip(hearth, murmur)]
    # Someone crossing the stone floor.
    for k in range(5):
        at = secs(2.4 + k * 0.56 + rng.uniform(-0.03, 0.03))
        m = secs(0.12)
        thump = grain(m, rng.uniform(85, 105), 0.025)
        click = highpass([rng.bipolar() * math.exp(-i / (0.0025 * SR)) for i in range(m)], 1800)
        add_into(x, [a + 0.35 * b for a, b in zip(thump, click)], at, 0.22 * (1 - abs(k - 2) * 0.15))
    x = reverb(x, wet=0.45, size=1.6, damp=0.35)
    return normalize(loopify(x, L, F), 0.65)


# ----------------------------------------------------------------------------------------------------------------
# One-shots.

def coin_clink(rng, base, amp=1.0):
    n = secs(0.3)
    out = zeros(n)
    for ratio, a, tau in ((1.0, 1.0, 0.11), (1.52, 0.55, 0.07), (2.11, 0.35, 0.05), (2.83, 0.2, 0.03)):
        add_into(out, grain(n, base * ratio * rng.uniform(0.995, 1.005), tau), 0, a * amp)
    tick = highpass([rng.bipolar() * math.exp(-i / (0.0008 * SR)) for i in range(secs(0.01))], 2500)
    add_into(out, tick, 0, 0.4 * amp)
    return out


def coin():
    rng = Rng(11)
    x = zeros(secs(0.38))
    add_into(x, coin_clink(rng, 1850), 0)
    add_into(x, coin_clink(rng, 1960, 0.55), secs(0.065))
    return fade(normalize(lowpass(x, 5500)), 0.001, 0.05)


def coins():
    rng = Rng(12)
    x = zeros(secs(0.75))
    pouch = lowpass([rng.bipolar() * math.exp(-i / (0.03 * SR)) for i in range(secs(0.1))], 320)
    add_into(x, pouch, 0, 1.2)
    t = 0.02
    for k in range(7):
        add_into(x, coin_clink(rng, rng.uniform(1500, 2300), 1.0 - k * 0.1), secs(t))
        t += rng.uniform(0.035, 0.085)
    return fade(normalize(lowpass(x, 5500)), 0.001, 0.08)


def hammer_tap(rng, g=1.0):
    n = secs(0.16)
    body = grain(n, rng.uniform(200, 225), 0.035)
    wood = grain(n, rng.uniform(700, 780), 0.02)
    hit = biquad([rng.bipolar() * math.exp(-i / (0.01 * SR)) for i in range(n)], "bp", 1100, 1.5)
    return [g * (a + 0.4 * b + 1.2 * c) for a, b, c in zip(body, wood, hit)]


def build_start():
    rng = Rng(21)
    x = zeros(secs(0.75))
    for k, t in enumerate((0.0, 0.21, 0.43)):
        add_into(x, hammer_tap(rng, 1.0 - 0.1 * k), secs(t + rng.uniform(-0.01, 0.01)))
    return fade(normalize(reverb(x, wet=0.15, size=0.7)), 0.001, 0.05)


def build_done():
    rng = Rng(22)
    x = zeros(secs(0.95))
    for t, f, g in ((0.0, 150, 1.0), (0.11, 132, 0.9)):
        n = secs(0.25)
        knock = [a + 0.5 * b for a, b in zip(grain(n, f, 0.06), grain(n, f * 3.1, 0.025))]
        hit = biquad([rng.bipolar() * math.exp(-i / (0.008 * SR)) for i in range(n)], "bp", 900, 1.2)
        add_into(x, [k + 0.8 * h for k, h in zip(knock, hit)], secs(t), g)
    add_into(x, grain(secs(0.7), 98, 0.22), secs(0.2), 0.6)
    dust = mul(biquad(noise(secs(0.5), rng), "bp", 1600, 0.7), decay(secs(0.5), 0.12, attack=0.05))
    add_into(x, dust, secs(0.22), 0.12)
    return fade(normalize(reverb(x, wet=0.2, size=0.8)), 0.001, 0.08)


def lantern():
    rng = Rng(31)
    x = zeros(secs(0.95))
    m = secs(0.09)
    strike = biquad(noise(m, rng), "bp", lambda t: 2000 + 25000 * t, 1.5)
    add_into(x, mul(strike, decay(m, 0.03, attack=0.01)), 0, 0.5)
    m = secs(0.8)
    flame = biquad(noise(m, rng), "lp", lambda t: 220 + 900 * min(1.0, t / 0.12) * math.exp(-t / 0.5), 0.9)
    add_into(x, mul(flame, decay(m, 0.3, attack=0.07)), secs(0.06), 2.2)
    for k in range(4):
        at = secs(rng.uniform(0.15, 0.7))
        click = highpass([rng.bipolar() * math.exp(-i / (0.0007 * SR)) for i in range(secs(0.004))], 1500)
        add_into(x, click, at, rng.uniform(0.15, 0.4))
    return fade(normalize(soft(x)), 0.002, 0.1)


def horn():
    """A low horn, two long tones of the same pitch (DESIGN.md "Feel"): a signal, no melody."""
    rng = Rng(41)
    f0 = 98.0
    total = secs(3.3)
    x = zeros(total)
    for start, length in ((0.0, 1.3), (1.55, 1.6)):
        n = secs(length)
        att, rel = 0.2, 0.35
        env = [0.0] * n
        for i in range(n):
            t = i / SR
            a = min(1.0, t / att)
            r = min(1.0, (length - t) / rel)
            env[i] = (a * a * (3 - 2 * a)) * max(0.0, r)
        tone = [0.0] * n
        phase = 0.0
        for i in range(n):
            t = i / SR
            vib = 1 + 0.004 * math.sin(TWO_PI * 4.6 * t) * min(1.0, max(0.0, (t - 0.4) / 0.4))
            phase += TWO_PI * f0 * vib / SR
            e = env[i]
            s = 0.0
            for k in range(1, 13):
                s += math.sin(k * phase) * (e ** (0.6 + 0.18 * k)) / (k ** 1.05)
            tone[i] = s
        breath = mul(biquad(noise(n, rng), "bp", 900, 1.2), env)
        add_into(x, [a + 0.04 * b for a, b in zip(tone, breath)], secs(start))
    x = lowpass(lowpass(x, 2600), 3200)
    x = reverb(x, wet=0.3, size=1.5, damp=0.45)
    return fade(normalize(soft(x, 1.0)), 0.01, 0.3)


def bell():
    """A small chapel bell struck once, then again softer: hum, prime, tierce, quint, nominal."""
    rng = Rng(42)
    x = zeros(secs(3.2))
    hum = 220.0
    partials = ((0.5, 0.5, 2.6), (1.0, 1.0, 1.9), (1.19, 0.55, 1.3), (1.5, 0.35, 1.0), (2.0, 0.6, 1.1),
                (2.51, 0.22, 0.55), (3.01, 0.15, 0.4))
    for start, g in ((0.0, 1.0), (1.25, 0.6)):
        n = secs(3.2 - start)
        strike = zeros(n)
        for ratio, a, tau in partials:
            f = hum * 2 * ratio
            add_into(strike, grain(n, f, tau), 0, a * 0.5)
            add_into(strike, grain(n, f + 0.7, tau), 0, a * 0.5)
        clang = highpass([rng.bipolar() * math.exp(-i / (0.003 * SR)) for i in range(secs(0.02))], 1200)
        add_into(strike, clang, 0, 0.3)
        add_into(x, strike, secs(start), g)
    x = lowpass(x, 5000)
    x = reverb(x, wet=0.3, size=1.3)
    return fade(normalize(x), 0.001, 0.4)


def bow():
    rng = Rng(51)
    x = zeros(secs(0.42))
    n = secs(0.25)
    f = lambda t: 175 - 30 * min(1.0, t / 0.05)
    twang = mul(sine(n, f), decay(n, 0.07))
    twang2 = mul(sine(n, lambda t: 2 * f(t)), decay(n, 0.035))
    add_into(x, [a + 0.35 * b for a, b in zip(twang, twang2)], 0, 0.9)
    m = secs(0.3)
    whoosh = biquad(noise(m, rng), "bp", lambda t: 2600 * math.exp(-t / 0.12) + 700, 1.8)
    env = [math.sin(math.pi * min(1.0, i / m)) ** 1.5 * math.exp(-i / (0.12 * SR)) for i in range(m)]
    add_into(x, mul(whoosh, env), secs(0.01), 1.4)
    return fade(normalize(lowpass(x, 6500)), 0.001, 0.05)


def arrow_hit():
    rng = Rng(52)
    n = secs(0.2)
    thunk = mul(sine(n, lambda t: 170 - 60 * min(1.0, t / 0.05)), decay(n, 0.045))
    thud = lowpass([rng.bipolar() * math.exp(-i / (0.012 * SR)) for i in range(n)], 1500)
    tick = grain(n, 2400, 0.006)
    x = [a + 1.2 * b + 0.25 * c for a, b, c in zip(thunk, thud, tick)]
    return fade(normalize(x), 0.001, 0.03)


def creature_hit():
    """A lost one hurt: a short breath, never a scream."""
    rng = Rng(61)
    n = secs(0.36)
    voice = formant_voice(n, rng, lambda t: 560 - 200 * t, lambda t: 980 - 250 * t, q=5.0,
                          pitch=lambda t: 140 - 50 * t, breath=0.7)
    env = decay(n, 0.09, attack=0.018)
    x = lowpass(mul(voice, env), 2200)
    return fade(normalize(x), 0.002, 0.05)


def dissolve():
    """A lost one dissolving: a sad, breathy sigh fading into soot."""
    rng = Rng(62)
    total = secs(1.35)
    x = zeros(total)
    n = secs(1.1)
    length = n / SR
    voice = formant_voice(n, rng, lambda t: 720 - 380 * (t / length), lambda t: 1150 - 450 * (t / length), q=6.0,
                          pitch=lambda t: 175 - 60 * (t / length), breath=0.6)
    env = [0.0] * n
    for i in range(n):
        t = i / SR
        env[i] = min(1.0, t / 0.22) * math.exp(-max(0.0, t - 0.22) / 0.35)
    add_into(x, lowpass(mul(voice, env), 1800), 0)
    m = secs(1.0)
    hiss = highpass(noise(m, rng), 3000)
    sparkle = smooth_random(m, rng, 30.0, octaves=1)
    hiss = [h * max(0.0, s) * math.exp(-i / (0.3 * SR)) * min(1.0, i / (0.1 * SR)) for i, (h, s) in
            enumerate(zip(hiss, sparkle))]
    add_into(x, hiss, secs(0.15), 0.35)
    x = reverb(x, wet=0.25, size=1.0)
    return fade(normalize(lowpass(x, 6000)), 0.005, 0.15)


def debris(x, rng, start, end, count, g):
    for k in range(count):
        t = start + (end - start) * (rng.random() ** 1.8)
        m = secs(0.08)
        stone = grain(m, rng.uniform(300, 1300), rng.uniform(0.008, 0.025), rng, noisy=0.4)
        add_into(x, stone, secs(t), g * rng.uniform(0.2, 1.0) * (1 - 0.6 * (t - start) / (end - start + 1e-9)))


def wall_hit():
    rng = Rng(71)
    x = zeros(secs(0.5))
    n = secs(0.4)
    add_into(x, grain(n, 70, 0.11), 0, 1.0)
    add_into(x, lowpass([rng.bipolar() * math.exp(-i / (0.07 * SR)) for i in range(n)], 600), 0, 1.6)
    debris(x, rng, 0.0, 0.16, 8, 0.25)
    return fade(normalize(soft(lowpass(x, 5000))), 0.001, 0.06)


def wall_break():
    rng = Rng(72)
    x = zeros(secs(1.7))
    n = secs(1.2)
    add_into(x, grain(n, 55, 0.35), 0, 1.0)
    rumble = lowpass(lowpass(noise(secs(1.6), rng), 220), 220)
    add_into(x, mul(rumble, decay(secs(1.6), 0.45, attack=0.03)), 0, 5.0)
    add_into(x, lowpass([rng.bipolar() * math.exp(-i / (0.12 * SR)) for i in range(n)], 900), 0, 1.2)
    debris(x, rng, 0.03, 1.3, 28, 0.35)
    x = reverb(x, wet=0.2, size=1.2)
    return fade(normalize(soft(lowpass(x, 4500), 1.4)), 0.001, 0.2)


def gate():
    """The heavy gate: a wooden creak on old hinges, the thud, the latch."""
    rng = Rng(81)
    x = zeros(secs(1.6))
    creak_len = 0.9
    m = secs(creak_len)
    pulses = zeros(m)
    t = 0.0
    while t < creak_len:
        rate = 28 + 30 * math.sin(math.pi * t / creak_len) + rng.uniform(-4, 4)
        pulses[secs(t)] = rng.uniform(0.6, 1.0)
        t += 1.0 / rate
    creak = [a + 0.7 * b for a, b in zip(biquad(pulses, "bp", 640, 7.0), biquad(pulses, "bp", 1350, 7.0))]
    env = [math.sin(math.pi * i / m) ** 0.7 for i in range(m)]
    add_into(x, mul(creak, env), 0, 1.0)
    n = secs(0.5)
    thud = [a + 1.4 * b for a, b in zip(grain(n, 62, 0.12),
                                         lowpass([rng.bipolar() * math.exp(-i / (0.05 * SR)) for i in range(n)], 500))]
    add_into(x, thud, secs(0.95), 2.2)
    add_into(x, grain(secs(0.08), 2900, 0.012, rng, noisy=0.3), secs(1.12), 0.35)
    x = reverb(x, wet=0.25, size=1.1)
    return fade(normalize(lowpass(x, 5000)), 0.003, 0.15)


def step(seed, cutoff):
    rng = Rng(seed)
    n = secs(0.18)
    scuff = lowpass([rng.bipolar() for _ in range(n)], cutoff)
    env = decay(n, 0.035, attack=0.006)
    thump = grain(n, rng.uniform(85, 100), 0.03)
    x = [a * e * 1.5 + 0.7 * b for a, e, b in zip(scuff, env, thump)]
    return fade(normalize(x), 0.002, 0.04)


def step_1():
    return step(91, 900)


def step_2():
    return step(92, 750)


def parchment():
    rng = Rng(101)
    total = secs(0.7)
    x = zeros(total)
    t = 0.0
    while t < 0.6:
        density = 0.25 + math.sin(math.pi * min(1.0, t / 0.6)) ** 0.8
        m = secs(rng.uniform(0.003, 0.012))
        crk = highpass([rng.bipolar() * math.exp(-i / (m * 0.3 + 1)) for i in range(m)], 2500)
        add_into(x, crk, secs(t), rng.uniform(0.3, 0.7) * density)
        t += rng.uniform(0.004, 0.03) / density
    swish = biquad(noise(total, rng), "bp", 1500, 0.8)
    env = [math.sin(math.pi * i / total) ** 1.2 for i in range(total)]
    add_into(x, mul(swish, env), 0, 0.3)
    return fade(normalize(lowpass(lowpass(x, 6000), 6000)), 0.004, 0.06)


def tap():
    rng = Rng(111)
    n = secs(0.09)
    x = [a + 0.8 * b for a, b in zip(grain(n, 1250, 0.012), grain(n, 380, 0.022))]
    add_into(x, highpass([rng.bipolar() * math.exp(-i / (0.0006 * SR)) for i in range(secs(0.005))], 2000), 0, 0.3)
    return fade(normalize(x), 0.0005, 0.02)


def seal():
    """A wax seal pressed onto parchment: a soft push, a little squish, the stamp let go."""
    rng = Rng(112)
    x = zeros(secs(0.36))
    n = secs(0.2)
    add_into(x, grain(n, 130, 0.05), 0, 1.0)
    squish = lowpass([rng.bipolar() for _ in range(n)], 700)
    add_into(x, mul(squish, decay(n, 0.05, attack=0.02)), secs(0.005), 1.3)
    add_into(x, grain(secs(0.05), 1600, 0.008), secs(0.15), 0.15)
    return fade(normalize(x), 0.002, 0.05)


def decline():
    rng = Rng(113)
    x = zeros(secs(0.32))
    for t, f in ((0.0, 210), (0.12, 158)):
        n = secs(0.16)
        knock = grain(n, f, 0.035)
        hit = lowpass([rng.bipolar() * math.exp(-i / (0.006 * SR)) for i in range(n)], 1200)
        add_into(x, [a + 0.6 * b for a, b in zip(knock, hit)], secs(t))
    return fade(normalize(x), 0.001, 0.04)


def engine():
    """The ballista's or the catapult's release: a heavy wooden thunk with a short creak."""
    rng = Rng(121)
    x = zeros(secs(0.6))
    n = secs(0.45)
    add_into(x, grain(n, 88, 0.13), 0, 1.0)
    add_into(x, lowpass([rng.bipolar() * math.exp(-i / (0.03 * SR)) for i in range(n)], 900), 0, 1.4)
    m = secs(0.18)
    pulses = zeros(m)
    t = 0.0
    while t < 0.17:
        pulses[secs(t)] = rng.uniform(0.5, 1.0)
        t += 1.0 / rng.uniform(40, 60)
    add_into(x, biquad(pulses, "bp", 820, 6.0), secs(0.05), 0.5)
    return fade(normalize(soft(x)), 0.001, 0.08)


SOUNDS = [
    ("amb_day", amb_day), ("amb_night", amb_night), ("amb_rain", amb_rain), ("amb_fire", amb_fire),
    ("amb_hall", amb_hall),
    ("coin", coin), ("coins", coins), ("build_start", build_start), ("build_done", build_done),
    ("lantern", lantern), ("horn", horn), ("bell", bell), ("bow", bow), ("arrow_hit", arrow_hit),
    ("creature_hit", creature_hit), ("dissolve", dissolve), ("wall_hit", wall_hit), ("wall_break", wall_break),
    ("gate", gate), ("step_1", step_1), ("step_2", step_2), ("parchment", parchment), ("tap", tap),
    ("seal", seal), ("decline", decline), ("engine", engine),
]


# ----------------------------------------------------------------------------------------------------------------

def without_dc(name, x):
    """No offset: a loop loses its mean (a filter would break the seam), a one-shot is high-passed at 25 Hz and
    faded again."""
    peak = max(abs(v) for v in x)
    if name.startswith("amb_"):
        mean = sum(x) / len(x)
        x = [v - mean for v in x]
    else:
        x = fade(highpass(x, 25), 0.0005, 0.01)
    return normalize(x, peak)


def write_wav(path, x):
    frames = bytearray()
    for v in x:
        s = int(round(max(-1.0, min(1.0, v)) * 32767))
        frames += struct.pack("<h", s)
    header = b"RIFF" + struct.pack("<I", 36 + len(frames)) + b"WAVE"
    header += b"fmt " + struct.pack("<IHHIIHH", 16, 1, 1, SR, SR * 2, 2, 16)
    header += b"data" + struct.pack("<I", len(frames))
    data = header + bytes(frames)
    with open(path, "wb") as f:
        f.write(data)
    return hashlib.sha256(data).hexdigest(), len(data)


def temperature():
    try:
        out = subprocess.run([SMCREAD], capture_output=True, text=True, timeout=10).stdout
        for part in out.split():
            if part.startswith("TCXC="):
                return float(part[5:])
    except Exception:
        return None
    return None


def cool_down():
    t = temperature()
    if t is None or t <= 80:
        return
    print(f"  CPU {t:.0f} C: waiting below 75 C", flush=True)
    while True:
        time.sleep(15)
        t = temperature()
        if t is None or t < 75:
            return


def main(argv):
    if "--list" in argv:
        for name, _ in SOUNDS:
            print(name)
        return 0
    wanted = [a for a in argv if not a.startswith("-")]
    os.makedirs(OUT, exist_ok=True)
    manifest = {}
    path = os.path.join(OUT, "MANIFEST.txt")
    if os.path.exists(path):
        for line in open(path):
            parts = line.split()
            if len(parts) == 3:
                manifest[parts[0]] = (parts[1], parts[2])
    for name, make in SOUNDS:
        if wanted and name not in wanted:
            continue
        cool_down()
        began = time.time()
        x = without_dc(name, make())
        digest, size = write_wav(os.path.join(OUT, name + ".wav"), x)
        manifest[name] = (str(size), digest)
        print(f"{name:14s} {len(x) / SR:5.2f} s {size / 1024:7.1f} KB  {time.time() - began:5.1f} s", flush=True)
        time.sleep(1)
    names = [n for n, _ in SOUNDS if n in manifest]
    with open(path, "w") as f:
        for n in names:
            f.write(f"{n} {manifest[n][0]} {manifest[n][1]}\n")
    total = sum(int(manifest[n][0]) for n in names)
    print(f"total {total / 1024 / 1024:.2f} MB in {len(names)} files")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
