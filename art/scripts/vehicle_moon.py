"""Vehicle: moon. A four-leg lunar lander, 2 m tall. Nose (top) points +Z, origin at the bottom centre.

Run from the repository root:
    blender --background --python art/scripts/vehicle_moon.py
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib_style import *

ASSET_ID = "vehicle_moon"

reset_scene()

# Heights before normalize (metres). Feet sit at z = 0.
DESC_Z = 0.7          # underside of the descent stage
DESC_TOP = DESC_Z + 0.5
CABIN_TOP = DESC_TOP + 0.6
FOOT_R = 0.9          # radius of the foot ring
LEG_TILT = 30.0       # degrees from vertical
LEG_LEN = DESC_Z / math.cos(math.radians(LEG_TILT))  # top of each leg reaches the descent stage underside

# (1) Descent stage: wide, low, 8-sided gold foil octagon.
cylinder((0, 0, DESC_Z), radius=0.9, height=0.5, material="sun_yellow", segments=8)

# Engine bell under the descent stage: narrow at the nozzle end, wide at the top.
cone((0, 0, 0.45), radius=0.14, height=0.25, material="metal_dark", segments=8, radius_top=0.25)

# (2) Four splayed legs with round foot pads.
# Each leg starts at its foot on the ring and leans inward as it rises.
# rot Y = -30 makes the leg lean inward; the foot is wider than the top.
for pos, angle in ring_positions(4, radius=FOOT_R, z=0.0, start_deg=45):
    cylinder(pos, radius=0.035, height=LEG_LEN, material="metal", segments=6,
             rot=(0, -LEG_TILT, angle))
    cylinder(pos, radius=0.14, height=0.03, material="metal_light", segments=8)

# (3) Ascent stage: 8-sided cabin with a tapered top.
cylinder((0, 0, DESC_TOP), radius=0.6, height=0.6, material="white", segments=8)
cone((0, 0, CABIN_TOP), radius=0.6, height=0.3, material="white", segments=8, radius_top=0.35)

# Two glow windows on the -Y side of the cabin.
for wx in (-0.18, 0.18):
    sphere((wx, -0.57, 1.5), radius=0.1, material="glow_cyan", segments=8, rings=4, scale=(1, 0.4, 1))

# Thin mast and small dish antenna on the roof.
mast_base = CABIN_TOP + 0.3
cylinder((0, 0, mast_base), radius=0.02, height=0.3, material="metal_light", segments=6)
cone((0, 0, mast_base + 0.3), radius=0.02, height=0.1, material="metal_light", segments=8, radius_top=0.18)

# Two small thruster boxes on the sides of the descent stage (+X and -X).
for tx in (-0.95, 0.95):
    box((tx, 0.0, 0.9), size=(0.2, 0.2, 0.25), material="metal")

# Join everything, then make the vehicle exactly 2 m tall with its bottom centre at the origin.
lander = join_and_apply(ASSET_ID)
normalize(lander, height=2.0)

finish(ASSET_ID, max_tris=1000)
