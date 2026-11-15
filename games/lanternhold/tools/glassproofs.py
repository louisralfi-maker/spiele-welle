"""The proofs' layouts for glassproof.py: every rectangle measured on the screenshots (device px of 2622 x 1206)."""
import glassart as ga

WT = "/Users/enaayla/Desktop/Spiele-Welle/.claude/worktrees"
S8 = WT + "/lh-stage/ci-out/lh-s1-8-upright/"
S13 = WT + "/lh-stage/ci-out/lh-s1f1-3-upright/"
HALL_PLATE = WT + "/lh-stage/ci-out/lh-s1f2-2/01-unit/hall-r-audience-framing.png"

BONE, GOLD, MIST, MIST_DIM, NAVY_DEEP = ga.BONE, ga.LANTERN_GOLD, ga.MIST, ga.MIST_DIM, ga.NAVY_DEEP


def inset(r, d):
    return (r[0] + d, r[1] + d, r[2] - d, r[3] - d)


# --- the hall audience (build 86, round lh-s1-8) -----------------------------------------------------------------------
LETTER = (192, 12, 1219, 572)
COUNSEL_BTN = (832, 54, 1190, 192)
PLAQUES = [(192, 1035, 846, 1191), (870, 1035, 1523, 1191), (1548, 1035, 2201, 1191)]
LEAVE = (2226, 1035, 2428, 1191)
HUD = (1917, 18, 2410, 198)
HUD_ICONS = [(1946, 124, 2001, 180), (2096, 124, 2158, 180)]


def hud_card(icons=HUD_ICONS, rect=HUD):
    return {"rect": rect, "skin": "glassPanel", "icons": icons,
            "text": [{"rect": inset(rect, 8)}]}


def letter_card(counsel_button=True):
    card = {"rect": LETTER, "skin": "glassPanel", "portraits": [(228, 39, 396, 207)],
            "erase": [COUNSEL_BTN] if counsel_button else [],
            "text": [{"rect": inset(LETTER, 22), "roles": {"rubric": MIST},
                      "over": [(400, 34, 830, 108, {"ink": GOLD})]}]}
    return card


def counsel_button_card():
    return {"rect": COUNSEL_BTN, "skin": "glassInset", "portraits": [(841, 63, 961, 183)],
            "text": [{"rect": (965, 62, 1182, 184), "roles": {"teal": GOLD}, "rules": False}]}


def plaque_card(rect, skin_name="glassPlaque", pressed=False, fill=None):
    roles = {"teal": MIST}
    if pressed:
        roles = {"ink": NAVY_DEEP, "teal": NAVY_DEEP, "soft": NAVY_DEEP, "rubric": NAVY_DEEP}
    card = {"rect": rect, "skin": skin_name, "text": [{"rect": inset(rect, 14), "roles": roles, "rules": False}]}
    if fill is not None:
        card["skin"] = "glassPlaquePressed"
        card["fill"] = fill
        card["fill_rest"] = "glassPlaque"
        card["fill_roles"] = {"ink": NAVY_DEEP, "teal": NAVY_DEEP, "soft": NAVY_DEEP, "rubric": NAVY_DEEP}
    return card


def audience(pressed_index=None, fill=None):
    cards = [letter_card(), counsel_button_card()]
    for i, r in enumerate(PLAQUES):
        if i == pressed_index:
            if fill is None:
                cards.append(plaque_card(r, "glassPlaquePressed", pressed=True))
            else:
                cards.append(plaque_card(r, fill=fill))
        else:
            cards.append(plaque_card(r))
    cards.append(plaque_card(LEAVE))
    cards.append(hud_card())
    return {"src": S8 + "133-hall-audience-en.jpg", "plate": HALL_PLATE,
            "shadows": [(LETTER, 28, 15, 0.5), (HUD, 9, 6, 0.45)], "cards": cards}


def plaque_fill():
    """The sweep of a pressed plaque, 0, 0.04, 0.08 and 0.12 s (linear): four frames of the plaque row stacked."""
    frames = []
    for f in (0.0, 1 / 3, 2 / 3, 1.0):
        frames.append(audience(pressed_index=1, fill=f))
    return {"frames": frames, "crop": (150, 990, 2472, 1206)}


PROOFS = {
    "audience": lambda: audience(),
    "audience-pressed": lambda: audience(pressed_index=1),
}


# --- Odile's counsel (the same audience, her slip open, her favourite marked) ------------------------------------------
COUNSEL_SLIP = (1250, 17, 1848, 334)
FAVOURED = (192, 994, 846, 1191)


def counsel():
    cards = [letter_card(counsel_button=False),
             {"rect": COUNSEL_SLIP, "skin": "glassPanel",
              "text": [{"rect": inset(COUNSEL_SLIP, 10), "roles": {"teal": BONE},
                        "over": [(1260, 27, 1840, 92, {"teal": GOLD})]}]},
             {"rect": FAVOURED, "skin": "glassPlaqueMarked",
              "text": [{"rect": inset(FAVOURED, 14), "roles": {"teal": MIST}, "rules": False,
                        "over": [(750, 1000, 830, 1070, {"teal": GOLD})]}]}]
    for r in PLAQUES[1:]:
        cards.append(plaque_card(r))
    cards.append(plaque_card(LEAVE))
    cards.append(hud_card())
    return {"src": S8 + "134-hall-counsel-en.jpg", "plate": HALL_PLATE,
            "shadows": [(LETTER, 28, 15, 0.5), (HUD, 9, 6, 0.45), (COUNSEL_SLIP, 9, 6, 0.45)], "cards": cards}


PROOFS["counsel"] = counsel


# --- the dawn report (round lh-s1f1-3, 45) -----------------------------------------------------------------------------
REPORT = (321, 124, 2301, 1023)
CONTINUE = (1776, 831, 2241, 987)
RIBBON = (380, 579, 1289, 669)


def report():
    left, right = (372, 338, 1300, 800), (1318, 338, 2250, 800)
    card = {"rect": REPORT, "skin": "glassPanel",
            "icons": [(2130, 420, 2182, 474), (2186, 548, 2243, 608), (611, 875, 673, 938)],
            "erase": [CONTINUE, RIBBON],
            "text": [
                {"rect": (345, 146, 2280, 336), "roles": {"ink": MIST},
                 "over": [(345, 146, 500, 290, {"ink": GOLD, "gold": GOLD, "soft": GOLD})]},
                {"rect": left, "roles": {"rubric": MIST}},
                {"rect": right, "roles": {"rubric": MIST}},
                {"rect": (345, 800, 2262, 1002), "roles": {"ink": MIST}},
            ]}
    ribbon = {"rect": RIBBON, "skin": "glassRibbon15",
              "text": [{"rect": (470, 586, 1200, 662), "polarity": "light", "roles": {"seal": GOLD}, "rules": False}]}
    button = {"rect": CONTINUE, "skin": "glassInsetMarked",
              "text": [{"rect": inset(CONTINUE, 14), "polarity": "light", "roles": {"seal": GOLD}, "rules": False}]}
    return {"src": S13 + "45-report-en.jpg", "shadows": [(REPORT, 30, 25, 0.5)], "cards": [card, ribbon, button]}


PROOFS["report"] = report


# --- the pause sheet (round lh-s1f1-3, 49) -----------------------------------------------------------------------------
PAUSE = (681, 79, 1941, 1067)
RESUME = (748, 293, 1291, 447)
HORN = (1326, 293, 1875, 447)
ROWS = [(747, 485, 1875, 635), (747, 671, 1875, 821)]
RESTART = (747, 857, 1875, 1013)
TOGGLES = [(1683, 518, 1833, 602), (1683, 704, 1833, 788)]


# The quiet words of the desk were bone (QuietButtonStyle onDark, SettingRow); JPEG blurs bone toward the gold.
QUIET = {"bone": BONE, "boneDim": BONE, "goldHi": BONE, "seal": BONE}


def pause(variant=None):
    light = "light"
    cards = [{"rect": PAUSE, "skin": "glassPanel", "polarity": light,
              "text": [{"rect": (760, 105, 1860, 228), "roles": {"goldHi": GOLD, "bone": GOLD}, "rules": False}],
              "flourish": [(747, 242, 1875)]},
             {"rect": RESUME, "skin": "glassInsetMarked", "polarity": light,
              "text": [{"rect": inset(RESUME, 12), "roles": {"seal": GOLD, "bone": GOLD}, "rules": False}]},
             {"rect": HORN, "skin": "glassInset", "polarity": light,
              "text": [{"rect": inset(HORN, 12), "roles": QUIET, "rules": False}]}]
    for r, t in zip(ROWS, TOGGLES):
        cards.append({"rect": r, "skin": "glassInset", "polarity": light, "switches": [t + (True,)],
                      "text": [{"rect": inset(r, 10), "roles": QUIET, "rules": False}]})
    cards.append({"rect": RESTART, "skin": "glassInsetDanger" if variant == "danger" else "glassInset",
                  "polarity": light, "text": [{"rect": inset(RESTART, 12), "roles": QUIET, "rules": False}]})
    return {"src": S13 + "49-pause-en.jpg", "shadows": [(PAUSE, 16, 10, 0.6)], "cards": cards}


PROOFS["pause"] = pause


# --- noon in the town: a word from Tamsin, her name over her, the HUD's ledger on the bright sky (lh-s1f1-3, 55) -----
BUBBLE = (718, 556, 1618, 843)
CAPTION = (2164, 678, 2352, 756)


def noon():
    cards = [{"rect": BUBBLE, "skin": "glassPanel", "tail": [(1168, 843, 7)],
              "text": [{"rect": inset(BUBBLE, 8)}]},
             {"rect": CAPTION, "skin": "glassPanel", "text": [{"rect": inset(CAPTION, 6), "rules": False}]},
             hud_card()]
    return {"src": S13 + "55-talk-en.jpg",
            "shadows": [(BUBBLE, 18, 9, 0.35), (HUD, 9, 6, 0.45), (CAPTION, 9, 6, 0.45)],
            "hide": [(1140, 843, 1197, 866)], "cards": cards}


PROOFS["noon"] = noon


# --- the brightest noon: Tamsin's word laid over clouds and snow by the castle (lh-world round lh-w1f2-3, w-2400) ---
HUD_2400 = (1942, 18, 2412, 200)
W2400 = WT + "/lh-world/ci-out/lh-w1f2-3/sweep-upright/w-2400-noon-en.jpg"


def shift(r, dx, dy):
    return (r[0] + dx, r[1] + dy, r[2] + dx, r[3] + dy)


def noon_bright():
    dx, dy = 1700 - BUBBLE[0], 236 - BUBBLE[1]
    b = shift(BUBBLE, dx, dy)
    cards = [{"rect": b, "skin": "glassPanel", "see": True, "text": [{"rect": inset(b, 8)}]},
             hud_card([(1970, 124, 2027, 180), (2096, 124, 2158, 180)], HUD_2400)]
    return {"src": W2400, "paste": [(S13 + "55-talk-en.jpg", BUBBLE, (b[0], b[1]))],
            "shadows": [(HUD_2400, 9, 6, 0.45)], "cards": cards}


PROOFS["plaque-fill"] = plaque_fill
PROOFS["noon-bright"] = noon_bright
