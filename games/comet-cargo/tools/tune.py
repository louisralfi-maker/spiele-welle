#!/usr/bin/env python3
"""Mirror of the Swift Core (FlightSim, Rocket, Rings, Ratings, Economy, Autopilot) for tuning on a Mac that must not
compile. Every formula and the order of every floating-point operation follow the Swift code, so the numbers printed here
are the numbers Tests/TuningTests.swift asserts. Run: python3 tools/tune.py (a few seconds, one core).

Change a constant here and in the Swift file named next to it, together.
"""
import math

# --- FlightSim.swift ---
DT = 1.0 / 120.0
GRAVITY = 0.7             # km/s^2, constant, no drag

# --- Rocket.swift ---
STAGE_SCALE = 0.62        # each stage has 62 % of the mass of the one below; the top stage has scale 1
STAGE_DRY = 1.0
STAGE_FUEL = 2.3
STAGE_BURN = 3.6          # s, every stage at tanks level 0
STAGE_THRUST = 10.0
CAPSULE_MASS = 1.7
SATELLITE_MASS = 0.12
ENGINE_STEP = 1.035       # thrust x 1.035 per engines level
TANK_STEP = 1.06          # fuel and burn time x 1.06 per tanks level

# --- Rings.swift ---
RINGS = [20.0, 35.0, 55.0, 80.0, 110.0, 150.0, 200.0, 260.0, 330.0, 410.0, 500.0, 600.0, 720.0, 860.0, 1000.0]
BAND_SECONDS = 0.45      # a fast rocket's band spans this many seconds of flight on each side of the centre line
MAX_GAP_SHARE = 0.45     # no band reaches past this share of the gap to its nearest neighbour (or the ground)
def base_half_width(k):
    return 2.8 + 0.018 * RINGS[k]
def max_half_width(k):
    below = RINGS[0] if k == 0 else RINGS[k] - RINGS[k - 1]
    above = below if k == len(RINGS) - 1 else RINGS[k + 1] - RINGS[k]
    return MAX_GAP_SHARE * min(below, above)
def half_width(k, speed=0.0):
    moving = max(0.0, speed) * BAND_SECONDS
    return min(max_half_width(k), max(base_half_width(k), moving))

# --- Ratings.swift ---
def window_scale(guidance):
    return 1.0 + 0.1 * guidance
def drop_rating(fuel_left, since_burnout, guidance):
    """since_burnout is None while the stage still burns."""
    m = window_scale(guidance)
    if since_burnout is not None:
        return 'perfect' if since_burnout <= 0.2 * m else 'late'
    if fuel_left <= 0.05 * m: return 'perfect'
    if fuel_left <= 0.12 * m: return 'great'
    if fuel_left <= 0.30: return 'good'
    return 'early'
KICK = {'perfect': 0.06, 'great': 0.03, 'good': 0.0, 'early': 0.0, 'late': 0.0}
def release_rating(altitude, speed, guidance):
    m = window_scale(guidance)
    for k in range(len(RINGS)):
        w = half_width(k, speed)
        d = abs(altitude - RINGS[k]) / w
        if d <= 1.0:
            if d <= min(1.0, 0.25 * m): return k, 'perfect'
            if d <= min(1.0, 0.6 * m): return k, 'great'
            return k, 'good'
    return None, 'lost'

# --- Economy.swift ---
def swift_round(x):  # Swift .rounded(): to nearest, halves away from zero
    return int(math.floor(x + 0.5)) if x >= 0 else -int(math.floor(-x + 0.5))
def base_pay(k):
    return swift_round(5.0 * math.pow(1.33, k))
PAY_MULT = {'perfect': 2.0, 'great': 1.5, 'good': 1.0, 'lost': 0.0}
def delivery_pay(k, rating):
    if k is None: return 0
    return swift_round(base_pay(k) * PAY_MULT[rating])
RING_SLOTS = 5
RING_BONUS = 10
MAX_LEVEL = {'engines': 10, 'tanks': 10, 'stages': 5, 'cargo': 6, 'guidance': 5}
MIN_LEVEL = {'engines': 0, 'tanks': 0, 'stages': 2, 'cargo': 2, 'guidance': 0}
TRACKS = ['engines', 'tanks', 'stages', 'cargo', 'guidance']
STAGE_PRICES = [800, 10000, 60000]
CARGO_PRICES = [150, 800, 3000, 10000]
FIRST_LEVEL_PRICE = 30
def price(track, level):
    if level >= MAX_LEVEL[track]: return None
    if track in ('engines', 'tanks'):
        if level == 0: return FIRST_LEVEL_PRICE
        return swift_round(60.0 * math.pow(1.8, level))
    if track == 'stages': return STAGE_PRICES[level - 2]
    if track == 'cargo': return CARGO_PRICES[level - 2]
    return swift_round(50.0 * math.pow(1.8, level))

# --- Rocket.swift ---
def make_rocket(lv):
    n = lv['stages']
    thrust_mul = math.pow(ENGINE_STEP, lv['engines'])
    tank_mul = math.pow(TANK_STEP, lv['tanks'])
    stages = []
    for i in range(n):
        scale = math.pow(STAGE_SCALE, i - (n - 1))
        stages.append(dict(dry=STAGE_DRY * scale, fuel=STAGE_FUEL * scale * tank_mul,
                           burn=STAGE_BURN * tank_mul, thrust=STAGE_THRUST * scale * thrust_mul))
    return dict(stages=stages, sats=lv['cargo'], guidance=lv['guidance'])

# --- FlightSim.swift ---
class Sim:
    def __init__(self, rocket):
        self.r = rocket
        self.tick = 0; self.phase = 'pad'; self.h = 0.0; self.v = 0.0; self.stage = 0
        self.fuel = rocket['stages'][0]['fuel']; self.sats = rocket['sats']
        self.ignition = None; self.burnout = None; self.maxh = 0.0
        self.drops = []; self.deliveries = []; self.lost = 0; self.queue = []
        self.last_drop_tick = -1; self.unused = 0
    def last(self): return self.stage == len(self.r['stages']) - 1
    def mass(self):
        m = CAPSULE_MASS + self.sats * SATELLITE_MASS
        st = self.r['stages']
        for i in range(self.stage, len(st)):
            m += st[i]['dry']
            m += self.fuel if i == self.stage else st[i]['fuel']
        return m
    def apply(self, inp):
        st = self.r['stages']
        if inp == 'ignite':
            if self.phase == 'pad': self.phase = 'burning'; self.ignition = self.tick
        elif inp == 'drop':
            if self.phase in ('burning', 'spent') and self.last_drop_tick != self.tick:
                self.last_drop_tick = self.tick
            else:
                return
            if not self.last():
                if self.phase == 'spent':
                    rating = drop_rating(0.0, (self.tick - self.burnout) * DT, self.r['guidance'])
                    f = 0.0
                else:
                    f = self.fuel / st[self.stage]['fuel']
                    rating = drop_rating(f, None, self.r['guidance'])
                self.v = self.v * (1.0 + KICK[rating])
                self.drops.append((rating, f))
                self.stage += 1; self.fuel = st[self.stage]['fuel']; self.phase = 'burning'; self.burnout = None
        elif inp == 'release':
            if self.phase in ('burning', 'spent', 'coasting') and self.sats > 0:
                k, rating = release_rating(self.h, self.v, self.r['guidance'])
                self.sats -= 1
                self.deliveries.append((k, rating, delivery_pay(k, rating)))
    def step(self):
        if self.phase == 'ended': return
        q = self.queue; self.queue = []
        for inp in q: self.apply(inp)
        if self.phase == 'pad':
            self.tick += 1; return
        st = self.r['stages'][self.stage]
        m = self.mass()
        thrust = st['thrust'] if self.phase == 'burning' else 0.0
        a = thrust / m - GRAVITY
        self.v += a * DT
        self.h += self.v * DT
        self.tick += 1
        if self.h < 0.0:
            self.h = 0.0
            if self.v < 0.0: self.v = 0.0
        if self.h > self.maxh: self.maxh = self.h
        if self.phase == 'burning':
            self.fuel -= st['fuel'] / st['burn'] * DT
            if self.fuel <= 0.0:
                self.fuel = 0.0; self.burnout = self.tick
                self.phase = 'coasting' if self.last() else 'spent'
        if self.phase in ('spent', 'coasting') and self.v <= 0.0:
            self.phase = 'ended'; self.lost = self.sats; self.sats = 0
            self.unused = len(self.r['stages']) - 1 - self.stage
    def flight_time(self): return (self.tick - self.ignition) * DT

# --- Autopilot.swift ---
def estimate_apex(rocket):
    s = Sim(rocket)
    while s.phase != 'ended':
        if s.phase == 'pad': s.queue.append('ignite')
        elif s.phase == 'spent': s.queue.append('drop')
        s.step()
    return s.maxh
def plan(rocket):
    apex = estimate_apex(rocket)
    reach = [k for k in range(len(RINGS)) if RINGS[k] + 0.5 < apex]
    n = rocket['sats']
    return reach[-n:] if n > 0 and reach else []
class Autopilot:
    def __init__(self, rocket, mode='perfect', releases=True):
        self.targets = plan(rocket) if releases else []
        self.next = 0; self.mode = mode
    def inputs(self, s):
        out = []
        if s.phase == 'pad': return ['ignite']
        if not s.last():
            if self.mode == 'perfect' and s.phase == 'spent': out.append('drop')
            if self.mode == 'early' and s.phase == 'burning' and s.fuel / s.r['stages'][s.stage]['fuel'] <= 0.5: out.append('drop')
            if self.mode == 'late' and s.phase == 'spent' and (s.tick - s.burnout) * DT >= 1.0: out.append('drop')
        if s.phase in ('burning', 'spent', 'coasting') and s.sats > 0:
            while self.next < len(self.targets) and RINGS[self.targets[self.next]] <= s.h: self.next += 1
            if self.next < len(self.targets):
                ring = RINGS[self.targets[self.next]]
                if s.h + s.v * DT >= ring:
                    out.append('release'); self.next += 1
        return out

def fly(rocket, mode='perfect', releases=True, track=None):
    s = Sim(rocket); ap = Autopilot(rocket, mode, releases)
    while s.phase != 'ended':
        s.queue.extend(ap.inputs(s))
        s.step()
        if track is not None and s.phase != 'pad': track.append((s.h, s.v))
    return s

def levels(engines=0, tanks=0, stages=2, cargo=2, guidance=0):
    return dict(engines=engines, tanks=tanks, stages=stages, cargo=cargo, guidance=guidance)
STARTER = levels()
MAXED = levels(10, 10, 5, 6, 5)

def crossing_times(rocket):
    """(ring, seconds inside the band, speed at the centre) for each ring crossed upward with v >= 0.5 at the centre."""
    tr = []
    fly(rocket, releases=False, track=tr)
    out = []
    for k, r in enumerate(RINGS):
        inside = [i for i, (h, v) in enumerate(tr) if abs(h - r) <= half_width(k, v) and v > 0]
        if not inside: continue
        exits = any(h > r + half_width(k, v) for h, v in tr[inside[-1]:])
        vc = next((v for h, v in tr if h >= r), None)
        if not exits or vc is None or vc < 0.5: continue
        out.append((k, len(inside) * DT, vc))
    return out

def economy_bot(verbose=False):
    lv = levels(); coins = 0; slots = [0] * len(RINGS); buys = []
    apex_cache = {}
    def apex_of(l):
        key = tuple(l[t] for t in TRACKS)
        if key not in apex_cache: apex_cache[key] = estimate_apex(make_rocket(l))
        return apex_cache[key]
    for flight in range(1, 1000):
        s = fly(make_rocket(lv))
        reached15 = False
        for k, rating, pay in s.deliveries:
            coins += pay
            if k is None: continue
            slots[k] += 1
            if slots[k] == RING_SLOTS: coins += RING_BONUS * base_pay(k)
            if k == len(RINGS) - 1: reached15 = True
        if reached15: return flight, lv, buys, coins
        while True:
            here = apex_of(lv); best = None
            for t in TRACKS:
                p = price(t, lv[t])
                if p is None or p > coins: continue
                nxt = dict(lv); nxt[t] += 1
                gain = apex_of(nxt) - here
                if gain <= 0: continue
                ratio = gain / p
                if best is None or ratio > best[0]: best = (ratio, t, p)
            if best is None: break
            coins -= best[2]; lv[best[1]] += 1; buys.append((flight, best[1], lv[best[1]]))
    return None, lv, buys, coins

def main():
    st = fly(make_rocket(STARTER), releases=False)
    print(f"1 starter: apex {st.maxh:.1f} km (105..135), ignition to apex {st.flight_time():.2f} s (18..35)")
    mx = fly(make_rocket(MAXED), releases=False)
    print(f"2 maxed:   apex {mx.maxh:.1f} km (>= 1050), ignition to apex {mx.flight_time():.2f} s (<= 95)")
    for name, lv in (('starter', STARTER), ('maxed', MAXED)):
        ct = crossing_times(make_rocket(lv))
        print(f"3 {name} ring crossings (0.8..3.0 s): " + ', '.join(f"r{k+1} {t:.2f}s@{v:.1f}" for k, t, v in ct))
    for name, lv in (('starter', STARTER), ('maxed', MAXED)):
        p = fly(make_rocket(lv), releases=False).maxh
        e = fly(make_rocket(lv), 'early', releases=False).maxh
        l = fly(make_rocket(lv), 'late', releases=False).maxh
        print(f"4 {name}: early -{100*(1-e/p):.1f} % (>= 15), late -{100*(1-l/p):.1f} % (>= 5)")
    for t in ('engines', 'tanks'):
        a = [fly(make_rocket(dict(STARTER, **{t: L})), releases=False).maxh for L in range(11)]
        print(f"5 {t} gain per level (3..12 %): " + ' '.join(f"{100*(a[i+1]/a[i]-1):.1f}" for i in range(10)))
    n, lv, buys, coins = economy_bot()
    print(f"6 economy bot: first delivery into ring 15 after {n} flights (90..180), levels {lv}")
    print("  buys (flight, track, new level): " + ' '.join(f"{f}:{t[0]}{L}" for f, t, L in buys))
    print("  pay per ring: " + ' '.join(str(base_pay(k)) for k in range(len(RINGS))))

if __name__ == '__main__':
    main()
