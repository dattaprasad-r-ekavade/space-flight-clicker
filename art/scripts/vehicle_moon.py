"""Vehicle: moon. A four-leg lunar lander. Nose (top) points +Z, origin at the bottom centre.

Run from the repository root:
    blender --background --python art/scripts/vehicle_moon.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib_style import *

ASSET_ID = "vehicle_moon"

reset_scene()

LEG_X = 0.45  # leg offset from the centre, in metres (before normalize)

# Body: a box cabin above the legs.
box((0, 0, 1.1), size=(0.9, 0.9, 0.6), material="moon_grey")

# Top dome: a squashed sphere on the cabin roof.
sphere((0, 0, 1.4), radius=0.2, material="metal_light", segments=8, rings=4, scale=(1, 1, 0.6))

# Antenna on the roof.
cylinder((0.2, 0.2, 1.4), radius=0.02, height=0.5, material="metal_dark", segments=6)

# Engine bell: a tapered tube under the cabin, wider at the bottom.
cone((0, 0, 0.4), radius=0.2, height=0.3, material="metal_dark", segments=10, radius_top=0.12)

# Window on the front face (-Y faces the camera).
sphere((0, -0.44, 1.1), radius=0.12, material="glow_cyan", segments=8, rings=4, scale=(1, 0.3, 0.8))

# Four legs and their landing pads, one at each corner.
for lx in (-LEG_X, LEG_X):
    for ly in (-LEG_X, LEG_X):
        cylinder((lx, ly, 0.0), radius=0.05, height=0.8, material="metal_light", segments=6)
        box((lx, ly, 0.02), size=(0.26, 0.26, 0.04), material="metal")

# Cross brace between the legs at mid height.
box((0, 0, 0.5), size=(0.9, 0.04, 0.04), material="metal")
box((0, 0, 0.5), size=(0.04, 0.9, 0.04), material="metal")

# Join everything, then make the vehicle exactly 2 m tall with its bottom centre at the origin.
lander = join_and_apply(ASSET_ID)
normalize(lander, height=2.0)

finish(ASSET_ID, max_tris=1000)
