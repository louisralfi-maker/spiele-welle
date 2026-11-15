#!/usr/bin/env python3
"""Lanternhold economy mirror (DESIGN.md "Economy", "Tuning targets"; docs/TOWN.md section 1): taxes on foot,
happiness, growth and the affordability of the reference build order over 20 days, in pure python, in well under a
second. For quick checks on the old Mac, which never builds Swift (CLAUDE.md "This Mac").

Since town-1 the dawn works out the day's taxes at the one rate and splits them over the paying places (each house by
its taxpayers, largest remainder; each field; the market); the bots collect at dawn by habit: normal collects
everything, low leaves the two houses that owe least alone (+1 happiness each at the next dawn, at most +3), high
knocks once at every house (40 % more, -2 happiness at once each; the war levy's second knock once the realm opens it
on story day 8). On the first morning the town's first house owes the 16 that make the purse's 44 the 60 of before,
and every habit takes them at once (fix round 1). The bots never hire the collector, so he is left out.
Core/Town/Town.swift is the source.

Town-3 (docs/TOWN.md section 3, Core/Town/TownGrowth.swift): the townhouse (room 12), the market hall (25 % of the
tax part), the inn (+2 happiness a dawn), the farmstead (8 gold a day) and the two far fields (from day 5); the town's
standing (a point for every townhouse, the market hall, the inn and every farmstead, at most 10) adds 1.5 % a point to
the tax part. The grower bot (Core/Town/TownGrowthTuning.swift, `growerOrder`) grows the town before the beacon;
target T12 compares its taxes at the dawn after night 14 with the old town's (the same game without the growth: 25 to
35 % more on the runner; reported here, not checked: this mirror reads about 8 points low). The reference bots never
build the new tiers, so their numbers stay what they were.

It reads its numbers from the Swift sources, so it cannot drift from them:
  Core/Balance.swift          the `var name = value` lines and the ItemStats rows (prices, build times)
  Core/Town/TownRules.swift   the `var name = value` lines (the knock, the houses left alone)
  Core/Autoplay.swift         the reference build order (.build("plot", .item), .recruitArchers, .recruitGuards(n))
  Core/Realm.swift            the unlock days (the lines, the beacon, the war levy)
  Core/Town/TownGrowth.swift  the far fields' and the treasury's unlock days
  Core/Town/TownGrowthTuning.swift  the grower's build order (`growerOrder`)

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
    for source in (text, read("Core/Town/TownRules.swift")):
        for name, value in re.findall(r"^\s*var (\w+) = (-?[0-9][0-9_]*(?:\.[0-9]+)?)\s*$", source, re.M):
            values[name] = float(value.replace("_", ""))
    items = {}
    for item, price, time in re.findall(r"ItemStats\(\.(\w+), price: (\d+), time: ([0-9.]+)\)", text):
        items[item] = (int(price), float(time))
    arrays = {}
    for name, body in re.findall(r"^\s*var (\w+): \[(?:Int|Double)\] = \[([^\]]*)\]", text, re.M):
        arrays[name] = [float(v) for v in body.split(",") if v.strip()]
    return values, items, arrays


def load_order(name="Core/Autoplay.swift", order="referenceOrder"):
    text = read(name)
    body = text.split("static let " + order, 1)[1].split("]\n", 1)[0]
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


def town_orders(order):
    """Core/Town/TownGrowthTuning.swift: the grower's and the old town's orders, the reference order with the growth
    (or the town of before) inserted before its first big house 4 and the far fields after its field 8."""
    growth = load_order("Core/Town/TownGrowthTuning.swift", "growthSteps")
    old = load_order("Core/Town/TownGrowthTuning.swift", "oldTownSteps")
    far = load_order("Core/Town/TownGrowthTuning.swift", "farFieldSteps")

    def inserting(steps, with_far):
        result, inserted = [], False
        for step in order:
            if not inserted and step == ("build", "town.house.4", "bigHouse"):
                result += steps
                inserted = True
            result.append(step)
            if with_far and step == ("build", "town.field.8", "field"):
                result += far
        return result
    return inserting(growth, True), inserting(old, False)


def load_unlocks():
    text = read("Core/Realm.swift")
    lines = [int(v) for v in re.search(r"lineUnlockDays: \[Int\] = \[([^\]]*)\]", text).group(1).split(",")]
    beacon = int(re.search(r"beaconUnlockDay = (\d+)", text).group(1))
    war = int(re.search(r"warTaxDay = (\d+)", text).group(1))
    growth = read("Core/Town/TownGrowth.swift")
    far = int(re.search(r"farFieldsDay = (\d+)", growth).group(1))
    treasury = int(re.search(r"treasuryDay = (\d+)", growth).group(1))
    return {"l1": lines[0], "l2": lines[1], "l3": lines[2], "beacon": beacon, "war": war,
            "town.field.9": far, "town.field.10": far, "castle.treasury": treasury}


# Upgrade chains and tiers, as in BuildItem.
CHAINS = [["gate", "ironGate", "greatGate"], ["palisade", "stoneWall", "bastion"], ["archerTower", "watchtower"],
          ["brazier", "fireTower"], ["beaconBase", "beaconTower", "greatBeacon"], ["smithy", "masterSmithy"],
          ["lodge", "bigLodge"], ["house", "bigHouse", "townhouse"], ["ballista"], ["catapult"], ["stakePit"],
          ["field", "farmstead"], ["market", "marketHall"], ["tavern", "inn"], ["treasury"]]
# The tiers that count for the town's standing (TownGrowth.points).
STANDING = ("townhouse", "marketHall", "inn", "farmstead")
TIER = {item: index + 1 for chain in CHAINS for index, item in enumerate(chain)}
PREVIOUS = {chain[i + 1]: chain[i] for chain in CHAINS for i in range(len(chain) - 1)}
PREBUILT = {"l1.wall": "gate", "town.house.1": "house", "town.house.3": "house", "town.house.4": "house",
            "town.house.5": "house"}
# The town plots left to right (Realm.townPlots) and what pays there.
TOWN = ["town.house.1", "town.field.2", "town.house.3", "town.house.4", "town.house.5", "town.market.6",
        "town.tavern.7", "town.field.8", "town.field.9", "town.field.10"]
HABIT = {"low": "spare", "normal": "collect", "high": "knock", "war": "levy"}


def split(total, weights):
    """Town.split: largest remainder, ties to the earlier place; the shares add up to `total`."""
    whole = sum(max(0, w) for w in weights)
    if total <= 0 or whole <= 0:
        return [0] * len(weights)
    shares = [total * max(0, w) // whole for w in weights]
    rests = sorted(range(len(weights)), key=lambda i: (-(total * max(0, weights[i]) % whole), i))
    left = total - sum(shares)
    for i in rests[:left]:
        shares[i] += 1
    return shares


class Realm:
    def __init__(self, v, items, arrays, unlocks, tax):
        self.v, self.items, self.arrays, self.unlocks, self.tax = v, items, arrays, unlocks, tax
        self.habit = HABIT[tax]
        # Town.firstMorning: the first house owes the rest of the 60 of before; [{plot, kind, owed, collected, knocks}]
        self.today = [{"plot": "town.house.1", "kind": "house", "owed": int(v["firstMorningGold"]), "collected": False,
                       "knocks": 0}]
        self.first_morning = True
        self.first_morning_gold = 0           # what the bot took on the first morning (not counted as income)
        self.war_unlocked = False             # GameState.warTaxUnlocked: Sim's dawn opens it on story day 8
        self.spared_yesterday = 0
        self.unrest_today = False
        self.income = 0                       # every coin the town paid over the run's dawns (tosses and knocks)
        self.knocks = 0
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
        self.standings = []                   # the town's standing at each logged dawn

    # --- helpers mirroring GameState / Build ---
    def taxpayers(self):
        return max(0, self.citizens - self.archers - self.guards)

    def room(self):
        room = 0
        for item in self.built.values():
            room += self.house_room(item)
        return room

    def house_room(self, item):
        """TownGrowth.room: a cottage 4, a big house 8, a townhouse 12."""
        return int({"house": self.v["houseRoom"], "bigHouse": self.v["bigHouseRoom"],
                    "townhouse": self.v["townhouseRoom"]}.get(item, 0))

    def field_gold(self, item):
        """TownGrowth.fieldGold: a field 5, a farmstead 8."""
        return int({"field": self.v["fieldGold"], "farmstead": self.v["farmsteadGold"]}.get(item, 0))

    def standing(self):
        """TownGrowth.standing: a point for every townhouse, the market hall, the inn, every farmstead."""
        points = sum(1 for plot, item in self.built.items() if plot in TOWN and item in STANDING)
        return min(int(self.v["standingMost"]), points)

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
        if plot in self.unlocks:
            return self.day >= self.unlocks[plot]
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
        self.horn()

    # --- the taxes on foot (Town) ---
    def doors_open(self):
        return self.today is not None and not self.unrest_today and self.happiness >= self.v["unrestBelow"]

    def ledger(self, tax_part, market, unrest):
        """Town.ledger: taxpayers over the houses by room, the tax part over the houses by taxpayers."""
        places = []
        for plot in TOWN:
            item = self.built.get(plot)
            if item in ("house", "bigHouse", "townhouse"):
                places.append({"plot": plot, "kind": "house", "room": self.house_room(item)})
            elif item in ("field", "farmstead"):
                places.append({"plot": plot, "kind": "field", "gold": self.field_gold(item)})
            elif item in ("market", "marketHall"):
                places.append({"plot": plot, "kind": "market"})
        houses = [p for p in places if p["kind"] == "house"]
        payers = split(self.taxpayers(), [h["room"] for h in houses])
        parts = split(0 if unrest else tax_part, payers)
        for house, part in zip(houses, parts):
            house["owed"] = part
        for place in places:
            if place["kind"] == "field":
                place["owed"] = 0 if unrest else place["gold"]
            elif place["kind"] == "market":
                place["owed"] = 0 if unrest else market
            place["collected"] = False
            place["knocks"] = 0
        return places

    def horn(self):
        """Town.horn: houses that owed, were left alone and whose doors were open count at the next dawn."""
        self.spared_yesterday = 0
        if self.today is None:
            return
        if self.doors_open():
            self.spared_yesterday = sum(1 for p in self.today if p["kind"] == "house" and p["owed"] > 0
                                        and not p["collected"])

    def collect(self, place):
        if self.doors_open() and place["owed"] > 0 and not place["collected"]:
            place["collected"] = True
            self.gold += place["owed"]
            if self.first_morning:
                self.first_morning_gold += place["owed"]
            else:
                self.income += place["owed"]

    def knock(self, place):
        v = self.v
        allowed = 2 if self.war_unlocked else 1
        if not self.doors_open() or place["kind"] != "house" or not place["collected"] or place["knocks"] >= allowed:
            return False
        levy = place["knocks"] >= 1
        share = v["levyShare"] if levy else v["knockShare"]
        gold = max(1, round_half_away(place["owed"] * share))
        place["knocks"] += 1
        self.gold += gold
        self.income += gold
        self.knocks += 1
        self.happiness = int(min(100, max(0, self.happiness + (v["levyHappiness"] if levy else v["knockHappiness"]))))
        return True

    def morning(self):
        """Town.morning: the bot's habit at dawn; on the first morning every habit only collects."""
        if not self.doors_open():
            return
        habit = "collect" if self.first_morning else self.habit
        if habit == "spare":
            houses = sorted((p for p in self.today if p["kind"] == "house" and p["owed"] > 0),
                            key=lambda p: (p["owed"], TOWN.index(p["plot"])))
            spared = {p["plot"] for p in houses[:int(self.v["lowHabitSpares"])]}
        else:
            spared = set()
        for place in self.today:
            if place["plot"] not in spared:
                self.collect(place)
        if habit in ("knock", "levy"):
            times = 1 if habit == "knock" else 2
            for place in self.today:
                while place["knocks"] < times and self.knock(place):
                    pass

    def dawn(self):
        v = self.v
        before = self.happiness
        mood = v["moodBase"] + v["moodSpan"] * min(100, max(0, before)) / 100
        standing = self.standing()
        factor = 1 + standing * v["standingTaxShare"] if standing > 0 else 1
        tax_part = round_half_away(self.taxpayers() * v["taxPerPayer"] * mood * factor)
        fields = sum(self.field_gold(item) for item in self.built.values())
        built = self.built.values()
        share = v["marketHallShare"] if "marketHall" in built else (v["marketShare"] if "market" in built else None)
        market = round_half_away(tax_part * share) if share is not None else 0
        unrest = before < v["unrestBelow"]
        total = 0 if unrest else tax_part + fields + market
        ledger = self.ledger(tax_part, market, unrest)
        assert sum(p["owed"] for p in ledger) == total, "the parts add up to the day's taxes"
        if self.first_taxes is None:
            self.first_taxes = total
        delta = min(v["spareHappinessMost"], self.spared_yesterday * v["spareHappiness"])
        if "inn" in self.built.values():
            delta += v["innHappiness"]
        elif "tavern" in self.built.values():
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
        if self.day >= self.unlocks["war"]:
            self.war_unlocked = True
        self.today = ledger
        self.first_morning = False
        self.unrest_today = unrest
        self.morning()
        self.log.append((self.day, total, self.gold, self.happiness, self.citizens, self.archers, self.guards,
                         self.buildings(), self.cursor))
        self.standings.append(self.standing())


def round_half_away(x):
    """Swift's Double.rounded(): halves away from zero."""
    return int(math.floor(x + 0.5)) if x >= 0 else -int(math.floor(-x + 0.5))


def simulate(v, items, arrays, unlocks, order, tax="normal", days=20, builds_beacon=True):
    realm = Realm(v, items, arrays, unlocks, tax)
    realm.morning()                           # the bot's first step: the first morning's coins
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
    grower_order, old_order = town_orders(order)
    night = 14                                # T12 compares at the dawn after night 14 (TownGrowthMetrics.night)
    grower = simulate(v, items, arrays, unlocks, grower_order, "normal", night)
    old_town = simulate(v, items, arrays, unlocks, old_order, "normal", night)
    reference14 = simulate(v, items, arrays, unlocks, order, "normal", night)
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
    t12 = grower.log[-1][1] / old_town.log[-1][1] - 1
    # Reported, not checked: the mirror leaves out the court and the battle, and its grower's people grow more slowly
    # than on the runner (round lh-t3-1: the mirror +30.4 %, the runner +39.6 % at 3 % a point), so the runner's
    # TownGrowthTuningTests decide T12 (25 to 35 %).
    print("T12 (reported; the runner decides, it reads about 8 points higher): the grower %+.1f %% over the old town "
          "(taxes %d against %d at the dawn after night 14; the reference %d, %+.1f %%; standing %d)" % (
              100 * t12, grower.log[-1][1], old_town.log[-1][1], reference14.log[-1][1],
              100 * (grower.log[-1][1] / reference14.log[-1][1] - 1), grower.standings[-1]))
    print("town over %d days: normal collects %d gold; low (two houses left alone) %d; high (knocks at every house, %d "
          "knocks) %d; every bot took the first morning's %d and started its first build with %d" % (
              args.days, normal.income, low.income, high.knocks, high.income, normal.first_morning_gold,
              int(v["startGold"]) + normal.first_morning_gold))
    failed = 0
    for name, ok, value in checks:
        print("%s %-36s %s" % ("PASS" if ok else "FAIL", name, value))
        failed += 0 if ok else 1
    print("economy mirror: %d of %d checks pass (battle effects left out)" % (len(checks) - failed, len(checks)))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
