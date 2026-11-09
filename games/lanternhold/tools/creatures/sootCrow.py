"""Soot Crow: a crow made of torn cloak scraps: a dark hooded head with one hollow eye and a grey beak, a rag tail.
Perched it is a small hunched hood. (Fix stage, ART-look2.md 14: no pale skull face.)"""
from rig import grid

SIZE = (12, 10, 4)
FLOATS = True
F = [
    # fly 0-2: wings up, level, down
    ["...h..h.....",
     "...hh.hh....",
     "....hhhh....",
     ".r..hhhhHh..",
     "rrrhhhhhnEdd",
     ".r.rhhhhnw..",
     "..r..hh.....",
     "............",
     "............",
     "............"],
    ["............",
     "............",
     "..hh........",
     ".r.hhhhhHh..",
     "rrrhhhhhnEdd",
     ".r.rhhhhnw..",
     "..r.hhhh....",
     "....hh.h....",
     "............",
     "............"],
    ["............",
     "............",
     "............",
     ".r..hhhhHh..",
     "rrrhhhhhnEdd",
     ".r.rhhhhnw..",
     "..r.hhhh....",
     "...hhhh.....",
     "...hh.hh....",
     "...h...h...."],
    # perch 3: hunched, the wings a hood
    ["............",
     "............",
     "............",
     "....hhhh....",
     "...hhHhHh...",
     "...hhhhnEdd.",
     "..rhhhhnw...",
     "..rrhhhh....",
     ".rr.hhh.....",
     ".r...d.d...."],
]


def frame(k):
    return grid(12, 10, F[k], seed=9)
