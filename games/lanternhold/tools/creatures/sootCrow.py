"""Soot Crow: a crow made of torn cloak scraps, one hollow eye. Perched it is a small hunched hood."""
from rig import grid

SIZE = (12, 10, 4)
FLOATS = True
F = [
    # fly 0-2: wings up, level, down
    ["...h..h.....",
     "...hh.hh....",
     "....hhhh....",
     ".r..hhhhSs..",
     "rrrhhhhhsEdd",
     ".r.rhhhhsw..",
     "..r..hh.....",
     "............",
     "............",
     "............"],
    ["............",
     "............",
     "..hh........",
     ".r.hhhhhSs..",
     "rrrhhhhhsEdd",
     ".r.rhhhhsw..",
     "..r.hhhh....",
     "....hh.h....",
     "............",
     "............"],
    ["............",
     "............",
     "............",
     ".r..hhhhSs..",
     "rrrhhhhhsEdd",
     ".r.rhhhhsw..",
     "..r.hhhh....",
     "...hhhh.....",
     "...hh.hh....",
     "...h...h...."],
    # perch 3: hunched, the wings a hood
    ["............",
     "............",
     "............",
     "....hhhh....",
     "...hhHhSs...",
     "...hhhhsEdd.",
     "..rhhhhsw...",
     "..rrhhhh....",
     ".rr.hhh.....",
     ".r...d.d...."],
]


def frame(k):
    return grid(12, 10, F[k], seed=9)
