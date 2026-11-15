"""Sootling, the crawler (POLISH.md section 7, build 3): a low husk of soot that drags itself on two clawed
forearms. No legs: its rear is a ragged smoke that trails on the ground. The back is its highest point and pumps two
pixels in the scuttle; the hooded head hangs low in front, the hood's torn peak standing at the nape, where its smoke
thread rises (sootThread.py). One socket with a cold point of light. It rears up to claw. 10 px high.
(ART-look2.md 14: no pale face, never two eyes, nothing of a child.)"""
from hordekit import paint

SIZE = (14, 14, 6)
HEIGHT = 10
E = ".............."
HIGH = ["....h.H.H.....",
        "...hHhHhHH....",
        "..rhhhhhhhHP..",
        ".rRkhhhhhhhHH.",
        "w.rkkhhhhhhgnH",
        ".w.kkkkhhkgnEe"]
LOW = ["....h.H.HHP...",
       "..rhHhHhhhhHH.",
       ".rRkhhhhhhhgnH",
       "w.rkkkhhhkgnEe"]
F = [
    # crawl 0-3 at 3 px a frame: a claw plants 12 px ahead, moves back 3 px a frame to 6 and swings; the near arm
    # (light) and the far arm (dark) take turns. The back is high on 0 and 2 and sunk 2 px on 1 and 3 (the pump).
    [E] * 5 + HIGH + ["..w...l...Lnn.",
                      "......l....L..",
                      ".....ll.....LL"],
    [E] * 7 + LOW + [".w.w..l..L.nn.",
                     "..w....l.L....",
                     "........LL...."],
    [E] * 5 + HIGH + ["..w.....L.lnn.",
                      ".......L...l..",
                      "......LL....ll"],
    [E] * 7 + LOW + [".w.w..L..l.nn.",
                     "..w....L.l....",
                     "........ll...."],
    # attack 4-5: the front lifts and the claws rise ahead (never upright: the back stays the highest mass); then
    # it strikes down, the head low again
    [E] * 4 + ["...........hh.",
               "....h.H.H.h..h",
               "...hHhHhHHh...",
               "..rhhhhhhHHP..",
               ".rRkhhhhhhgnH.",
               "w.rkkhhhhgnEe.",
               ".w.kkkkhhhnnh.",
               "..w.l..l......",
               "....l...l.....",
               "...ll...ll...."],
    [E] * 7 + LOW[:3] + ["w.rkkkhhhkgnEe",
                         ".w.wl.....Lnnh",
                         "..w.l.....L.LL",
                         "...ll....L..L."],
]


def frame(k):
    return paint(F[k], seed=3)
