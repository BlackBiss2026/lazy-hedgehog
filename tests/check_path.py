#!/usr/bin/env python3
"""Validate a hedgehog answer.
usage: check_path.py <world-file> <program-output> <expected-cost>
The output must be: the total weight on the first line, then the path,
one "row col" per line, from 0 0 to rows-1 cols-1, moving one step
up/down/left/right at a time. Any lightest path is accepted.
"""
import sys

def fail(msg):
    print("  " + msg)
    sys.exit(1)

world = open(sys.argv[1]).read().split()
R, C = int(world[0]), int(world[1])
w = [int(x) for x in world[2:2 + R * C]]
expected = int(open(sys.argv[3]).read())
lines = [l for l in open(sys.argv[2], errors="replace").read().split("\n") if l.strip()]
if not lines:
    fail("no output")
try:
    total = int(lines[0])
except ValueError:
    fail(f"first line must be the total weight, got: {lines[0][:60]!r}")
path = []
for i, l in enumerate(lines[1:], 2):
    p = l.split()
    if len(p) != 2 or not all(x.lstrip("-").isdigit() for x in p):
        fail(f"line {i}: expected 'row col', got {l[:60]!r}")
    path.append((int(p[0]), int(p[1])))
if not path:
    fail("the path is missing (only the total was printed)")
if path[0] != (0, 0):
    fail(f"path must start at 0 0, starts at {path[0][0]} {path[0][1]}")
if path[-1] != (R - 1, C - 1):
    fail(f"path must end at {R-1} {C-1}, ends at {path[-1][0]} {path[-1][1]}")
for (r1, c1), (r2, c2) in zip(path, path[1:]):
    if not (0 <= r2 < R and 0 <= c2 < C):
        fail(f"cell {r2} {c2} is outside the world")
    if abs(r1 - r2) + abs(c1 - c2) != 1:
        fail(f"illegal move {r1} {c1} -> {r2} {c2} (one step up/down/left/right only)")
s = sum(w[r * C + c] for r, c in path)
if s != total:
    fail(f"printed total {total}, but the weights on the printed path sum to {s}")
if total != expected:
    fail(f"path is valid but not the lightest: weight {total}, best possible is {expected}")
print(f"  ok: lightest path, weight {total}, {len(path)} cells")
