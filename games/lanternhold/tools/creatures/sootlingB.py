"""Sootling B: a small stooped husk upright on stick legs. The bent back is its highest point, the hooded head hangs
forward below the shoulders on a broken neck, the hood's peak torn; one hollow socket with a single point of cold
light and a tear. One arm has grown far too long and is dragged along the ground; it whips that arm over its head to
strike. (Fix stage, ART-look2.md 14: no pale bare head, no smock, never two eyes, nothing of a child.)"""
from rig import grid

SIZE = (14, 14, 6)
TOP = ["..............", ".............."]
HEAD = ["..hhhhhHHHh...",
        "...hhh.hnnh...",
        "...hkh.hnnh...",
        "...hhh.hnE...."]
F = [
    # walk 0-3 at 3 px a frame: thin legs, the long arm dragged; the back sinks 1 px on frames 1 and 3 and the tear
    # under the eye goes out
    TOP + ["...hHH........", "..hHHhh.Hh...."] + HEAD + [
     "...rhh..dw....",
     "...rhh.h......",
     "...hh...h.....",
     "...h.h...h....",
     "..hh.h....h...",
     "..h..hh...hhh."],
    TOP + ["..............", "..hHHHh.Hh...."] + HEAD + [
     "...rhh..dd....",
     "...rhh.h......",
     "...hh...h.....",
     "....hh...h....",
     "....h.....h...",
     "...hhh....hhh."],
    TOP + ["...hHH........", "..hHHhh.Hh...."] + HEAD + [
     "...rhh..dw....",
     "...rhh.h......",
     "...hh...h.....",
     "...h.h...h....",
     "...h..h...h...",
     "..hh..hh..hhh."],
    TOP + ["..............", "..hHHHh.Hh...."] + HEAD + [
     "...rhh..dd....",
     "...rhh.h......",
     "...hh...hh....",
     "....hh....h...",
     "....h.....h...",
     "...hhh....hhh."],
    # attack 4-5: the long arm swung up behind the back; whipped over the head and down in front
    ["h.............",
     "h.............",
     ".h.hHH........",
     ".hhHHhh.Hh...."] + HEAD + [
     "...rhh..dw....",
     "...rhh........",
     "...hh.........",
     "...h.h........",
     "..hh.h........",
     "..h..hh......."],
    ["..............",
     ".....hhhhh....",
     "....hh....hh..",
     "....hHH.....h.",
     "...hHHhh.Hh..h",
     "...hhhhhHHHh.h",
     "....hhh.hnnh.h",
     "....hkh.hnnh..",
     "....hhh.hnE...",
     "....rhh..dw...",
     "...hhh........",
     "...h.h........",
     "..hh..h.......",
     "..h...hh......"],
]


def frame(k):
    return grid(14, 14, F[k], seed=5)
