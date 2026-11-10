"""Launch site: solar. An orbital shipyard deck above a red planet disc.

The deck top is at z = 0. The launch point is the origin. No normalize call.
Everything stays inside x -6..6, y -3..3, z -1..9.

Run from the repository root:
    blender --background --python art/scripts/site_solar.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib_style import *

ASSET_ID = "site_solar"

reset_scene()

# Shipyard deck: a slab whose top surface is at z = 0.
box((0, 0, -0.25), size=(10.0, 4.0, 0.5), material="metal_dark")

# Four short struts under the deck corners.
for sx in (-4.5, 4.5):
    for sy in (-1.5, 1.5):
        box((sx, sy, -0.75), size=(0.3, 0.3, 0.5), material="metal")

# Bollards along the deck edges (cylinders, 0.5 m tall). Kept far from the origin.
for bx, by in ((-4.6, -1.8), (-4.6, 0.0), (-4.6, 1.8), (4.6, -1.8), (4.6, 0.0), (4.6, 1.8)):
    cylinder((bx, by, 0.0), radius=0.12, height=0.5, material="orange", segments=16)

# Prop 1: a stack of two crates at the left (heights 0.8 m and 0.6 m).
box((-3.5, -1.0, 0.4), size=(1.0, 1.0, 0.8), material="wood")
box((-2.3, -0.9, 0.3), size=(0.7, 0.7, 0.6), material="cardboard")

# Prop 2: a crate stack at the right (heights 0.5 m and 1.1 m).
box((3.0, -1.6, 0.25), size=(0.8, 0.8, 0.5), material="cardboard")
box((3.0, -1.6, 0.8), size=(0.6, 0.6, 0.6), material="wood")

# Prop 3: a lamp pole with a warm lamp on top (2.6 m tall).
cylinder((-4.2, 1.4, 0.0), radius=0.05, height=2.6, material="metal", segments=16)
box((-4.2, 1.4, 2.7), size=(0.3, 0.3, 0.15), material="glow_orange")

# Prop 4: a fuel tank with a domed top.
cylinder((4.0, 1.3, 0.0), radius=0.6, height=1.6, material="metal_light", segments=16)
cone((4.0, 1.3, 1.6), radius=0.6, height=0.35, material="metal_light", segments=16)

# Prop 5: a tall antenna mast with a light at the tip (6 m tall, the tallest prop).
cylinder((4.2, -0.9, 0.0), radius=0.06, height=6.0, material="metal_light", segments=16)
sphere((4.2, -0.9, 6.15), radius=0.15, material="glow_white", segments=16, rings=8)

# Prop 6: a flag on a pole. The flag is plain red, with no logo.
cylinder((-2.0, -1.8, 0.0), radius=0.03, height=2.2, material="white", segments=12)
box((-2.0, -1.55, 1.95), size=(0.02, 0.5, 0.3), material="red")

# Prop 7: a solar array on two posts, at the back right of the deck.
for px in (2.0, 3.4):
    cylinder((px, 1.9, 0.0), radius=0.04, height=2.6, material="metal", segments=12)
box((2.7, 1.9, 3.2), size=(2.0, 0.1, 1.2), material="solar_panel")

# Red planet disc behind the deck (+Y). A sphere squashed flat in Y.
# Radius 5 m. Front face at y = 2.5, back face at y = 3.0. Bottom at z = -1, top at z = 9.
sphere((0, 2.75, 4.0), radius=5.0, material="red", segments=24, rings=12, scale=(1.0, 0.05, 1.0))

finish(ASSET_ID, max_tris=3000)
