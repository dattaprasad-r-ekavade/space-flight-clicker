"""Vehicle: model rocket. Cardboard body, three fins, nose cone. Height 2 m, nose toward +Z.

Run from the repository root:
    blender --background --python art/scripts/vehicle_model_rockets.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib_style import *

ASSET_ID = "vehicle_model_rockets"

reset_scene()

# Body: a cardboard tube. Cylinders grow upward from the centre of their bottom.
cylinder((0, 0, 0.25), radius=0.2, height=1.3, material="cardboard", segments=12)

# Nose cone: a red cone on top of the body.
cone((0, 0, 1.55), radius=0.2, height=0.45, material="red", segments=12)

# Paper band near the top of the body.
cylinder((0, 0, 1.3), radius=0.205, height=0.06, material="paper", segments=12)

# Engine nozzle: a short tapered tube at the bottom.
cone((0, 0, 0.0), radius=0.13, height=0.25, material="metal_dark", segments=10, radius_top=0.09)

# Three wooden fins around the lower body (tips point outward).
for pos, angle in ring_positions(3, radius=0.19, z=0.25, start_deg=90):
    fin(pos, length=0.35, height=0.5, thickness=0.03, material="wood", rot=(0, 0, angle))

# Join everything, then make the vehicle exactly 2 m tall with its bottom centre at the origin.
rocket = join_and_apply(ASSET_ID)
normalize(rocket, height=2.0)

finish(ASSET_ID, max_tris=400)
