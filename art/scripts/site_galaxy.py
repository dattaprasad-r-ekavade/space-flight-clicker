"""Launch site: galaxy. A small floating launch deck with a gate ring above it.

Run from the repository root:
    blender --background --python art/scripts/site_galaxy.py

Layout: deck top at z = 0, launch point at the origin, gate ring centred on the Z axis at z = 7.
No normalize() here: the site is not a vehicle.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib_style import *

ASSET_ID = "site_galaxy"

reset_scene()

# Deck: a flat slab. Its top surface is at z = 0. The origin sits on it.
box((0, 0, -0.4), size=(5.0, 4.0, 0.8), material="metal_dark")
# Deck rim: a thin lighter strip along the front edge.
box((0, -1.95, 0.02), size=(5.0, 0.1, 0.04), material="glow_orange")

# Gate ring: flat in XY, centred on the Z axis at z = 7.
# Inner radius = 2.6 - 0.15 = 2.45 m (at least 2 m). Outer radius 2.75 m fits the 6 m deep box.
torus((0, 0, 7.0), major_radius=2.6, minor_radius=0.15, material="metal_light",
      major_segments=48, minor_segments=12)

# Four legs from the deck up to the ring. They stand on the 2.6 m circle, outside the gate opening.
for ang in (45, 135, 225, 315):
    r = 2.6
    x = r * math.cos(math.radians(ang))
    y = r * math.sin(math.radians(ang))
    cylinder((x, y, 0.0), radius=0.12, height=7.0, material="metal", segments=12)

# Prop 1: two stacked crates (heights 0.7 and 1.2 m).
box((-1.9, -1.0, 0.35), size=(0.7, 0.7, 0.7), material="wood")
box((-1.9, -1.0, 0.95), size=(0.5, 0.5, 0.5), material="cardboard")

# Prop 2: a tall antenna mast with a cyan beacon on top (3.1 m).
cylinder((2.2, 0.0, 0.0), radius=0.05, height=3.0, material="white", segments=8)
sphere((2.2, 0.0, 3.1), radius=0.1, material="glow_cyan", segments=12, rings=6)

# Prop 3: a fuel tank with a flat cap (1.1 m).
cylinder((-2.0, 0.9, 0.0), radius=0.35, height=1.1, material="red", segments=12)
cylinder((-2.0, 0.9, 1.1), radius=0.38, height=0.1, material="metal_dark", segments=12)

# Prop 4: a lamp post with a warm light head (2.2 m).
cylinder((0.0, -1.9, 0.0), radius=0.08, height=2.2, material="metal", segments=8)
sphere((0.0, -1.9, 2.25), radius=0.15, material="glow_orange", segments=12, rings=6)

site = join_and_apply(ASSET_ID)

finish(ASSET_ID, max_tris=3000)
