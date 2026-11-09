#!/usr/bin/env python3
"""Lanternhold economy mirror (DESIGN.md "Economy", "Tuning targets"): taxes, happiness, growth and the affordability
of the reference build order over 20 days, in pure python, in well under a second. For quick checks on the old Mac,
which never builds Swift (CLAUDE.md "This Mac").

It reads its numbers from the Swift sources, so it cannot drift from them:
  Core/Balance.swift   the `var name = value` lines and the ItemStats rows (prices, build times)
  Core/Autoplay.swift  the reference build order (.build("plot", .item), .recruitArchers, .recruitGuards(n))
  Core/Realm.swift     the unlock days

The battle is left out: no losses, no rubble, no patches (the runner's TuningTests measure those). Builders are a
capacity of builder-seconds per day. Usage: python3 tools/tune.py [--days 20] [--set taxPerPayer=5.5 ...] [--quiet]
"""
import argparse
import math
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
GAME = os.path.dirname(HERE)
DAY_SECONDS = 156.0          # 06:00 to 19:00, 12 s per hour
WALKING_SHARE = 0.25         # part of a builder's day spent walking (the Swift builders walk to every job)


def read(name):
    with open(os.path.join(GAME, name), encoding="utf-8") as handle:
        return handle.read()


def load_balance():
    text = read("Core/Balance.swift")
    values = {}
    for name, value in re.findall(r"^\s*var (\w+) = (-?[0-9][0-9_]*(?:\.[0-9]+)?)\s*$", text, re.M):
        values[name] = float(value.replace("_", ""))
    items = {}
    for item, price, time in re.findall(r"ItemStats\(\.(\w+), price: (\d+), time: ([0-9.]+)\)", text):
        items[item] = (int(price), float(time))
    arrays = {}
    for name, body in re.findall(r"^\s*var (\w+): \[(?:Int|Double)\] = \[([^\]]*)\]", text, re.M):
        arrays[name] = [float(v) for v in body.split(",") if v.strip()]
    return values, items, arrays


def load_order():
    text = read("Core/Autoplay.swift")
    body = text.split("static let referenceOrder", 1)[1].split("]\n", 1)[0]
    order = []
    for line in body.splitlines():
        line = line.strip()
        build = re.match(r'\.build\("([\w.]+)", \.(\w+)\)', line)
        if build:
            order.append(("build", build.group(1), build.group(2)))
        elif line.startswith(".recruitArchers"):
            order.append(("archers",))
        else:
            guards = re.match(r"\.recruitGuards\((\d+)\)", line)
            if guards:
                order.append(("guards", int(guards.group(1))))
    return order


def load_unlocks():
    text = read("Core/Realm.swift")
    lines = [int(v) for v in re.search(r"lineUnlockDays: \[Int\] = \[([^\]]*)\]", text).group(1).split(",")]
    beacon = int(re.search(r"beaconUnlockDay = (\d+)", text).group(1))
    return {"l1": lines[0], "l2": lines[1], "l3": lines[2], "beacon": beacon}


# Upgrade chains and tiers, as in BuildItem.
CHAINS = [["gate", "ironGate", "greatGate"], ["palisade", "stoneWall", "bastion"], ["archerTower", "watchtower"],
          ["brazier", "fireTower"], ["beaconBase", "beaconTower", "greatBeacon"], ["smithy", "masterSmithy"],
          ["lodge", "bigLodge"], ["house", "bigHouse"], ["ballista"], ["catapult"], ["stakePit"], ["field"],
          ["market"], ["tavern"]]
TIER = {item: index + 1 for chain in CHAINS for index, item in enumerate(chain)}
PREVIOUS = {chain[i + 1]: chain[i] for chain in CHAINS for i in range(len(chain) - 1)}
PREBUILT = {"l1.wall": "gate", "town.house.1": "house", "town.house.3": "house", "town.house.4": "house",
            "town.house.5": "house"}


class Realm:
    def __init__(self, v, items, arrays, unlocks, tax):
        self.v, self.items, self.arrays, self.unlocks, self.tax = v, items, arrays, unlocks, tax
        self.gold = int(v["startGold"])
        self.happiness = int(v["startHappiness"])
        self.citizens = int(v["startCitizens"])
        self.archers = int(v["startArchers"])
        self.guards = int(v["startGuards"])
        self.built = dict(PREBUILT)          # plot -> finished item
        self.jobs = []                        # [plot, item, builder-seconds left]
        self.dawns = 0
        self.day = 1
        self.cursor = 0
        self.beacon_day = None
        self.first_taxes = None
        self.buildings_day10 = None
        self.log = []

    # --- helpers mirroring GameState / Build ---
    def taxpayers(self):
        return max(0, self.citizens - self.archers - self.guards)

    def room(self):
        room = 0
        for item in self.built.values():
            if item == "house":
                room += int(self.v["houseRoom"])
            elif item == "bigHouse":
                room += int(self.v["bigHouseRoom"])
        return room

    def builders(self):
        lodge = self.built.get("castle.lodge")
        if lodge == "lodge":
            return int(self.v["buildersLodge"])
        if lodge == "bigLodge":
            return int(self.v["buildersBigLodge"])
        return int(self.v["buildersBase"])

    def posts(self):
        wall_posts = self.arrays["wallPosts"]
        gate_posts = self.arrays["gatePosts"]
        tower_posts = self.arrays["towerPosts"]
        total = 0
        for plot, item in self.built.items():
            if plot.endswith(".wall"):
                tier = TIER[item]
                total += int((gate_posts if item in ("gate", "ironGate", "greatGate") else wall_posts)[tier - 1])
            elif plot.endswith(".tower"):
                total += int(tower_posts[TIER[item] - 1])
        return total

    def buildings(self):
        count = 0
        for plot, item in self.built.items():
            if plot in PREBUILT:
                continue
            count += 1
        return count

    def has_or_building(self, plot, item):
        for job in self.jobs:
            if job[0] == plot and job[1] == item:
                return True
        current = self.built.get(plot)
        if current is None:
            return False
        if plot.endswith(".engine"):
            return True
        return TIER[current] >= TIER[item]

    def unlocked(self, plot):
        return self.day >= self.unlocks.get(plot.split(".")[0], 1)

    # --- the bot's day (Autoplay.planDay without rubble) ---
    def buy(self, order, builds_beacon=True, share=0.5):
        while self.cursor < len(order):
            step = order[self.cursor]
            if step[0] == "build":
                plot, item = step[1], step[2]
                if not builds_beacon and plot == "beacon":
                    self.cursor += 1
                    continue
                if self.has_or_building(plot, item):
                    self.cursor += 1
                    continue
                if not self.unlocked(plot) or any(job[0] == plot for job in self.jobs):
                    return
                previous = PREVIOUS.get(item)
                if previous is not None and self.built.get(plot) != previous:
                    return
                if previous is None and self.built.get(plot) is not None:
                    self.cursor += 1
                    continue
                price, time = self.items[item]
                if self.gold < price:
                    return
                self.gold -= price
                self.jobs.append([plot, item, time * 2])
                self.cursor += 1
            elif step[0] == "archers":
                floor = math.ceil(share * self.citizens)
                if self.posts() - self.archers <= 0 or self.taxpayers() - 1 < floor:
                    self.cursor += 1
                    continue
                if self.gold < self.v["archerPrice"]:
                    return
                self.gold -= int(self.v["archerPrice"])
                self.archers += 1
            else:
                floor = math.ceil(share * self.citizens)
                if self.guards >= step[1] or self.taxpayers() - 1 < floor:
                    self.cursor += 1
                    continue
                if self.gold < self.v["guardPrice"]:
                    return
                self.gold -= int(self.v["guardPrice"])
                self.guards += 1

    def work(self, seconds):
        """Builders work `seconds` of the day on the jobs, oldest first; returns True if a job finished."""
        factor = self.v["happyBuildFactor"] if self.happiness >= self.v["fastGrowthFrom"] else 1.0
        capacity = self.builders() * seconds * (1 - WALKING_SHARE) * factor
        finished = False
        while self.jobs and capacity > 0:
            job = self.jobs[0]
            spend = min(capacity, job[2])
            job[2] -= spend
            capacity -= spend
            if job[2] <= 1e-9:
                self.built[job[0]] = job[1]
                self.jobs.pop(0)
                finished = True
                if job[1] == "greatBeacon" and self.beacon_day is None:
                    self.beacon_day = self.day
        return finished

    def run_day(self, order, builds_beacon):
        # The bot buys whenever it can; finished jobs open upgrades the same day. Four slices per day.
        for _ in range(4):
            self.buy(order, builds_beacon)
            self.work(DAY_SECONDS / 4)
        self.buy(order, builds_beacon)
        if self.day == 10:
            self.buildings_day10 = self.buildings()

    def dawn(self):
        v = self.v
        before = self.happiness
        rate = {"low": v["rateLow"], "normal": v["rateNormal"], "high": v["rateHigh"], "war": v["rateWar"]}[self.tax]
        mood = v["moodBase"] + v["moodSpan"] * min(100, max(0, before)) / 100
        tax_part = round_half_away(self.taxpayers() * v["taxPerPayer"] * rate * mood)
        fields = sum(1 for item in self.built.values() if item == "field") * int(v["fieldGold"])
        market = round_half_away(tax_part * v["marketShare"]) if "market" in self.built.values() else 0
        total = 0 if before < v["unrestBelow"] else tax_part + fields + market
        self.gold += total
        if self.first_taxes is None:
            self.first_taxes = total
        delta = {"low": v["happinessLowTax"], "normal": v["happinessNormalTax"], "high": v["happinessHighTax"],
                 "war": v["happinessWarTax"]}[self.tax]
        if "tavern" in self.built.values():
            delta += v["happinessTavern"]
        delta += v["happinessNoLosses"]
        after = int(min(100, max(0, before + delta)))
        self.happiness = after
        if after < v["unrestBelow"]:
            if self.citizens > 0:
                if self.taxpayers() == 0 and self.archers + self.guards > 0:
                    if self.guards > 0:
                        self.guards -= 1
                    else:
                        self.archers -= 1
                self.citizens -= 1
        else:
            free = max(0, self.room() - self.citizens)
            if after >= v["fastGrowthFrom"]:
                self.citizens += min(2, free)
            elif after >= v["growthFrom"]:
                self.citizens += min(1, free)
        self.dawns += 1
        if self.dawns % int(v["volunteerEvery"]) == 0 and after >= v["volunteerFrom"] and self.citizens < self.room():
            self.citizens += 1
            self.archers += 1
        self.day += 1
        self.log.append((self.day, total, self.gold, self.happiness, self.citizens, self.archers, self.guards,
                         self.buildings(), self.cursor))


def round_half_away(x):
    """Swift's Double.rounded(): halves away from zero."""
    return int(math.floor(x + 0.5)) if x >= 0 else -int(math.floor(-x + 0.5))


def simulate(v, items, arrays, unlocks, order, tax="normal", days=20, builds_beacon=True):
    realm = Realm(v, items, arrays, unlocks, tax)
    for _ in range(days):
        realm.run_day(order, builds_beacon)
        realm.dawn()
    return realm


def builds_bought(gold, items):
    """TuningRun.buildsBought: the cheapest first build of every plot open on day 2, cheapest first."""
    plots = ["brazier", "brazier", "stakePit", "archerTower", "ballista", "smithy", "lodge", "field", "field",
             "market", "tavern"]
    prices = sorted(items[item][0] for item in plots)
    count = 0
    for price in prices:
        if price > gold:
            break
        gold -= price
        count += 1
    return count


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--days", type=int, default=20)
    parser.add_argument("--set", action="append", default=[], help="override a Balance value, e.g. taxPerPayer=5.5")
    parser.add_argument("--quiet", action="store_true", help="targets only, no day table")
    args = parser.parse_args()
    v, items, arrays = load_balance()
    for change in args.set:
        name, value = change.split("=", 1)
        v[name] = float(value)
    order = load_order()
    unlocks = load_unlocks()

    normal = simulate(v, items, arrays, unlocks, order, "normal", args.days)
    low = simulate(v, items, arrays, unlocks, order, "low", args.days)
    high = simulate(v, items, arrays, unlocks, order, "high", args.days)

    if not args.quiet:
        print("normal tax, reference order (dawn of day: taxes, gold after, happiness, citizens, archers, guards, "
              "buildings, order step)")
        for row in normal.log:
            print("  day %2d: taxes %4d  gold %4d  happiness %3d  citizens %2d  archers %2d  guards %d  "
                  "buildings %2d  step %d" % row)
    first_builds = builds_bought(normal.first_taxes, items)
    happiness_high_day8 = next((row[3] for row in high.log if row[0] == 8), None)
    low_min = min((row[3] for row in low.log if 8 <= row[0] <= 20), default=0)
    checks = [
        ("T3 beacon by day 18 (normal tax)", normal.beacon_day is not None and normal.beacon_day <= 18,
         "day %s" % normal.beacon_day),
        ("T3 low tax cannot", low.beacon_day is None or low.beacon_day > 18, "day %s" % low.beacon_day),
        ("T4 high tax below 30 by day 8", happiness_high_day8 is not None and happiness_high_day8 < 30,
         "happiness %s" % happiness_high_day8),
        ("T4 low tax above 70 (dawns 8-20)", low_min > 70, "lowest %s" % low_min),
        ("T5 first taxes buy 2-3 builds", 2 <= first_builds <= 3, "%d gold, %d builds" % (normal.first_taxes,
                                                                                         first_builds)),
        ("T5 8-12 buildings by day 10", normal.buildings_day10 is not None and 8 <= normal.buildings_day10 <= 12,
         "%s" % normal.buildings_day10),
    ]
    failed = 0
    for name, ok, value in checks:
        print("%s %-36s %s" % ("PASS" if ok else "FAIL", name, value))
        failed += 0 if ok else 1
    print("economy mirror: %d of %d checks pass (battle effects left out)" % (len(checks) - failed, len(checks)))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
