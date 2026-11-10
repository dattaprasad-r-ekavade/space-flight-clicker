"""Vehicle: sounding. A thin two-stage rocket, 2 m tall, nose toward +Z.

Run from the repository root:
    blender --background --python art/scripts/vehicle_sounding.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib_style import *

ASSET_ID = "vehicle_sounding"

reset_scene()

# Engine nozzle: a short tapered bell at the base (bottom is wider).
cone((0, 0, 0.0), radius=0.10, height=0.2, material="metal_dark", segments=8, radius_top=0.07)

# Lower stage: a white tube above the nozzle.
cylinder((0, 0, 0.2), radius=0.13, height=0.8, material="white", segments=8)

# Coloured band on the lower stage.
cylinder((0, 0, 0.6), radius=0.135, height=0.06, material="red", segments=8)

# Three thin fins at the base of the lower stage.
for pos, angle in ring_positions(3, radius=0.13, z=0.2, start_deg=90):
    fin(pos, length=0.22, height=0.35, thickness=0.02, material="red", rot=(0, 0, angle))

# Upper stage: a narrower metal tube on top of the lower stage.
cylinder((0, 0, 1.0), radius=0.09, height=0.6, material="metal_light", segments=8)

# Dark band on the upper stage.
cylinder((0, 0, 1.3), radius=0.095, height=0.04, material="black", segments=8)

# Nose cone: a short tapered tip at +Z.
cone((0, 0, 1.6), radius=0.09, height=0.4, material="red", segments=8)

# Join everything, then make the vehicle exactly 2 m tall with its bottom centre at the origin.
rocket = join_and_apply(ASSET_ID)
normalize(rocket, height=2.0)

finish(ASSET_ID, max_tris=600)
